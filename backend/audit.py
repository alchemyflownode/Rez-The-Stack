# src/api/workers/audit.py
# Sovereign file auditor — deterministic, local-only, zero-trust

import os
import hashlib
import json
import re
from pathlib import Path
from datetime import datetime
import ast
import subprocess

class SovereignAuditor:
    def __init__(self, root_path="src"):
        self.root_path = Path(root_path)
        self.findings = []
        self.file_count = 0
        self.total_size = 0
        
    # ========== SECURITY SCANS ==========
    
    def scan_for_secrets(self):
        """Detect hardcoded secrets, API keys, passwords"""
        secret_patterns = [
            (r'(?i)(api[_-]?key|apikey)\s*=\s*["\']([^"\']+)["\']', 'API Key'),
            (r'(?i)(password|passwd|pwd)\s*=\s*["\']([^"\']+)["\']', 'Password'),
            (r'(?i)(secret[_-]?key|secretkey)\s*=\s*["\']([^"\']+)["\']', 'Secret Key'),
            (r'(?i)(token|auth[_-]?token)\s*=\s*["\']([^"\']+)["\']', 'Auth Token'),
            (r'(?i)aws[_-]?access[_-]?key[_-]?id\s*=\s*["\']([^"\']+)["\']', 'AWS Key'),
            (r'(?i)private[_-]?key\s*=\s*["\']([^"\']+)["\']', 'Private Key'),
        ]
        
        for file_path in self.root_path.rglob("*"):
            if file_path.is_file() and file_path.suffix in ['.py', '.ts', '.tsx', '.js', '.json', '.env']:
                if 'node_modules' in str(file_path) or '.next' in str(file_path):
                    continue
                    
                try:
                    content = file_path.read_text(encoding='utf-8', errors='ignore')
                    for pattern, secret_type in secret_patterns:
                        matches = re.finditer(pattern, content)
                        for match in matches:
                            # Check if it's a placeholder
                            value = match.group(2) if len(match.groups()) > 1 else match.group(1)
                            if not any(placeholder in value.lower() for placeholder in ['your_', 'xxx', 'changeme', 'example', 'placeholder']):
                                self.findings.append({
                                    'severity': 'CRITICAL',
                                    'type': 'Hardcoded Secret',
                                    'file': str(file_path),
                                    'line': content[:match.start()].count('\n') + 1,
                                    'detail': f'{secret_type} detected',
                                    'category': 'security'
                                })
                except Exception as e:
                    pass
                    
    def scan_for_vulnerabilities(self):
        """Detect common security vulnerabilities"""
        vuln_patterns = [
            (r'eval\s*\(', 'Dangerous eval() usage', 'CRITICAL'),
            (r'exec\s*\(', 'Dangerous exec() usage', 'CRITICAL'),
            (r'os\.system\s*\(', 'OS command injection risk', 'HIGH'),
            (r'subprocess\.(call|run|Popen)\s*\([^)]*shell\s*=\s*True', 'Shell injection risk', 'HIGH'),
            (r'pickle\.loads?\s*\(', 'Pickle deserialization risk', 'HIGH'),
            (r'yaml\.load\s*\([^)]*\)', 'YAML load without SafeLoader', 'MEDIUM'),
            (r'input\s*\(\s*\)\s*\.eval', 'User input to eval', 'CRITICAL'),
            (r'SELECT\s+\*\s+FROM', 'SQL injection risk (raw query)', 'HIGH'),
            (r'innerHTML\s*=', 'XSS risk (innerHTML)', 'MEDIUM'),
            (r'dangerouslySetInnerHTML', 'React XSS risk', 'MEDIUM'),
        ]
        
        for file_path in self.root_path.rglob("*.py"):
            if 'node_modules' in str(file_path) or '.next' in str(file_path):
                continue
                
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                for pattern, vuln_type, severity in vuln_patterns:
                    matches = re.finditer(pattern, content, re.IGNORECASE)
                    for match in matches:
                        self.findings.append({
                            'severity': severity,
                            'type': 'Security Vulnerability',
                            'file': str(file_path),
                            'line': content[:match.start()].count('\n') + 1,
                            'detail': vuln_type,
                            'category': 'security'
                        })
            except Exception as e:
                pass
                
    def scan_dependencies(self):
        """Audit dependencies for known vulnerabilities"""
        # Check package.json
        package_json = self.root_path.parent / "package.json"
        if package_json.exists():
            try:
                import subprocess
                result = subprocess.run(
                    ['npm', 'audit', '--json'],
                    capture_output=True,
                    text=True,
                    cwd=str(self.root_path.parent)
                )
                if result.returncode == 0:
                    audit_data = json.loads(result.stdout)
                    vulnerabilities = audit_data.get('vulnerabilities', {})
                    for pkg, vuln_info in vulnerabilities.items():
                        self.findings.append({
                            'severity': vuln_info.get('severity', 'MEDIUM').upper(),
                            'type': 'Dependency Vulnerability',
                            'file': 'package.json',
                            'line': 0,
                            'detail': f"{pkg}: {vuln_info.get('title', 'Vulnerability')}",
                            'category': 'dependencies',
                            'via': vuln_info.get('via', [])
                        })
            except Exception as e:
                self.findings.append({
                    'severity': 'INFO',
                    'type': 'Audit Info',
                    'file': 'package.json',
                    'line': 0,
                    'detail': f'npm audit failed: {str(e)}',
                    'category': 'dependencies'
                })
                
    # ========== CODE QUALITY ==========
    
    def check_code_quality(self):
        """Check for code quality issues"""
        for file_path in self.root_path.rglob("*.py"):
            if 'node_modules' in str(file_path) or '.next' in str(file_path):
                continue
                
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                lines = content.split('\n')
                
                # Check for long functions
                tree = ast.parse(content)
                for node in ast.walk(tree):
                    if isinstance(node, ast.FunctionDef):
                        func_lines = node.end_lineno - node.lineno
                        if func_lines > 50:
                            self.findings.append({
                                'severity': 'LOW',
                                'type': 'Code Quality',
                                'file': str(file_path),
                                'line': node.lineno,
                                'detail': f'Function {node.name} is too long ({func_lines} lines)',
                                'category': 'quality'
                            })
                
                # Check for TODO/FIXME comments
                for i, line in enumerate(lines, 1):
                    if re.search(r'(TODO|FIXME|XXX|HACK)', line, re.IGNORECASE):
                        self.findings.append({
                            'severity': 'INFO',
                            'type': 'Technical Debt',
                            'file': str(file_path),
                            'line': i,
                            'detail': line.strip(),
                            'category': 'quality'
                        })
                        
            except Exception as e:
                pass
                
    # ========== FILE INTEGRITY ==========
    
    def generate_checksums(self):
        """Generate SHA-256 checksums for all source files"""
        checksums = {}
        for file_path in self.root_path.rglob("*"):
            if file_path.is_file() and file_path.suffix in ['.py', '.ts', '.tsx', '.js', '.json']:
                if 'node_modules' in str(file_path) or '.next' in str(file_path):
                    continue
                    
                try:
                    content = file_path.read_bytes()
                    checksum = hashlib.sha256(content).hexdigest()
                    checksums[str(file_path)] = checksum
                    self.file_count += 1
                    self.total_size += len(content)
                except Exception as e:
                    pass
                    
        return checksums
        
    def check_file_permissions(self):
        """Check for insecure file permissions"""
        for file_path in self.root_path.rglob("*"):
            if file_path.is_file():
                try:
                    mode = file_path.stat().st_mode
                    # Check if world-writable
                    if mode & 0o002:
                        self.findings.append({
                            'severity': 'MEDIUM',
                            'type': 'File Permission',
                            'file': str(file_path),
                            'line': 0,
                            'detail': 'File is world-writable',
                            'category': 'security'
                        })
                    # Check if executable scripts are safe
                    if file_path.suffix == '.sh' and mode & 0o755:
                        content = file_path.read_text(encoding='utf-8', errors='ignore')
                        if 'curl' in content and '|' in content and 'bash' in content:
                            self.findings.append({
                                'severity': 'HIGH',
                                'type': 'Unsafe Script',
                                'file': str(file_path),
                                'line': 0,
                                'detail': 'Script pipes curl to bash',
                                'category': 'security'
                            })
                except Exception as e:
                    pass
                    
    # ========== COMPREHENSIVE AUDIT ==========
    
    def run_full_audit(self):
        """Execute all audit checks"""
        print("🔍 Starting Sovereign File Audit...")
        print("=" * 60)
        
        start_time = datetime.now()
        
        print("📦 Scanning for hardcoded secrets...")
        self.scan_for_secrets()
        
        print("🛡️  Scanning for security vulnerabilities...")
        self.scan_for_vulnerabilities()
        
        print("🔐 Checking file permissions...")
        self.check_file_permissions()
        
        print("📚 Auditing dependencies...")
        self.scan_dependencies()
        
        print("✨ Checking code quality...")
        self.check_code_quality()
        
        print("🔏 Generating file checksums...")
        checksums = self.generate_checksums()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        # Generate report
        report = {
            'timestamp': datetime.now().isoformat(),
            'duration_seconds': duration,
            'files_scanned': self.file_count,
            'total_size_bytes': self.total_size,
            'total_findings': len(self.findings),
            'checksums': checksums,
            'findings_by_severity': {
                'CRITICAL': len([f for f in self.findings if f['severity'] == 'CRITICAL']),
                'HIGH': len([f for f in self.findings if f['severity'] == 'HIGH']),
                'MEDIUM': len([f for f in self.findings if f['severity'] == 'MEDIUM']),
                'LOW': len([f for f in self.findings if f['severity'] == 'LOW']),
                'INFO': len([f for f in self.findings if f['severity'] == 'INFO']),
            },
            'findings_by_category': {
                'security': len([f for f in self.findings if f['category'] == 'security']),
                'dependencies': len([f for f in self.findings if f['category'] == 'dependencies']),
                'quality': len([f for f in self.findings if f['category'] == 'quality']),
            },
            'findings': sorted(self.findings, key=lambda x: {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3, 'INFO': 4}[x['severity']])
        }
        
        return report


def main():
    auditor = SovereignAuditor(root_path="src")
    report = auditor.run_full_audit()
    
    # Save report
    report_path = Path("audit_report.json")
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    # Print summary
    print("\n" + "=" * 60)
    print("📊 AUDIT SUMMARY")
    print("=" * 60)
    print(f"⏱️  Duration: {report['duration_seconds']:.2f}s")
    print(f"📁 Files Scanned: {report['files_scanned']}")
    print(f"💾 Total Size: {report['total_size_bytes'] / 1024 / 1024:.2f} MB")
    print(f"🚨 Total Findings: {report['total_findings']}")
    print()
    print("By Severity:")
    for severity, count in report['findings_by_severity'].items():
        if count > 0:
            emoji = {'CRITICAL': '🔴', 'HIGH': '🟠', 'MEDIUM': '🟡', 'LOW': '🔵', 'INFO': '⚪'}[severity]
            print(f"  {emoji} {severity}: {count}")
    print()
    print("By Category:")
    for category, count in report['findings_by_category'].items():
        if count > 0:
            print(f"  • {category}: {count}")
    print()
    print(f"💾 Full report saved to: {report_path.absolute()}")
    print("=" * 60)
    
    # Show critical findings
    critical = [f for f in report['findings'] if f['severity'] in ['CRITICAL', 'HIGH']]
    if critical:
        print("\n🚨 CRITICAL & HIGH SEVERITY FINDINGS:")
        print("-" * 60)
        for finding in critical[:10]:  # Show top 10
            print(f"[{finding['severity']}] {finding['file']}:{finding['line']}")
            print(f"  → {finding['detail']}")
            print()
    
    return report


if __name__ == "__main__":
    main()