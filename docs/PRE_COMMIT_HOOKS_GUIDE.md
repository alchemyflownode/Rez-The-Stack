# Pre-commit Hooks Setup - Phase 3 Complete

## Overview
Automated code quality gates using husky, lint-staged, and commitlint to enforce standards before code reaches the repository.

## Framework Configuration

### ✅ Husky (Git Hooks Manager)
- **Package:** `husky@9.1.7`
- **Directory:** `.husky/`
- **Purpose:** Manage git hook scripts
- **Status:** Initialized and configured

### ✅ Lint-staged (File-based Linting)
- **Package:** `lint-staged@16.3.2`
- **Purpose:** Run linters/formatters only on staged files
- **Status:** Configured in package.json

### ✅ Commitlint (Commit Message Linting)
- **Package:** `@commitlint/cli@20.4.3`
- **Config:** `commitlint.config.js`
- **Purpose:** Enforce conventional commit format
- **Status:** Configured with extended ruleset

## Hook Configuration

### 1. Pre-commit Hook (`.husky/pre-commit`)
**Triggers:** Before commit is created
**Actions:**
```bash
npx lint-staged
```

**What it does:**
- Runs on all staged files matching patterns
- Formats TypeScript/JavaScript with prettier
- Runs ESLint with auto-fix
- Prevents commit if checks fail

**File patterns:**
- `*.{ts,tsx,js,jsx}` → prettier + eslint --fix
- `*.{json,css,md}` → prettier --write

### 2. Commit-msg Hook (`.husky/commit-msg`)
**Triggers:** Before commit message is finalized
**Actions:**
```bash
npx --no -- commitlint --edit ${1}
```

**What it does:**
- Validates commit message against conventional commit rules
- Checks type, scope, subject length, punctuation
- Rejects non-conforming commits with helpful error message

## Conventional Commit Format

### Accepted Commit Types
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Formatting, semicolons (no code logic change)
- `refactor:` - Code restructuring without feature/bug changes
- `perf:` - Performance improvements
- `test:` - Test additions/modifications
- `ci:` - CI/CD configuration changes
- `chore:` - Build, dependencies, tooling
- `revert:` - Revert a previous commit
- `security:` - Security improvements
- `a11y:` - Accessibility improvements

### Commit Message Rules
1. **Type:** Must be lowercase from allowed list
2. **Scope:** Optional, must be lowercase if provided
3. **Subject:** Max 100 characters, use sentence case, must end with period
4. **Header:** Max 100 characters

### Valid Examples
```
feat(auth): Add JWT token refresh endpoint.
fix(api): Resolve timeout errors on kernel requests.
docs(readme): Update installation instructions.
a11y(components): Improve ErrorBoundary keyboard navigation.
perf(bundle): Optimize web-vitals lazyload strategy.
```

### Invalid Examples
```
WIP: Update stuff       ❌ (not allowed type)
feat: new feature       ❌ (missing period, lowercase 'f')
Add new auth feature    ❌ (missing type prefix)
feat(Auth): New auth.   ❌ (scope not lowercase, no period)
```

## Workflow Usage

### Normal Git Commit
```bash
git add .
git commit -m "feat(vitals): Add Core Web Vitals monitoring."
```

**What happens:**
1. ✅ Pre-commit hook runs lint-staged
   - Prettier formats changed files
   - ESLint auto-fixes issues
2. ✅ Commit-msg hook validates message format
3. ✅ If all pass, commit is created
4. ❌ If any fail, commit is blocked with error details

### Fix Hook Failures

**Linting failure:**
```bash
# ESLint found fixable issues - they're auto-fixed
git add .
git commit -m "feat: description."  # Try again
```

**Unfixable linting:**
```bash
# ESLint found non-auto-fixable issues
# Fix manually in editor
git add .
git commit -m "feat: description."
```

**Commit message failure:**
```bash
# Commitlint rejected format
# Rewrite with correct format
git commit --amend -m "feat(scope): Correct format."
```

### Bypass Hooks (Emergency Only)
```bash
# Skip all hooks (use sparingly!)
git commit --no-verify -m "hotfix: Emergency fix."
```

## Integration with CI/CD

Pre-commit hooks are **local-only**. For server-side enforcement:

1. **GitHub Actions:** Already configured in `.github/workflows/ci-pipeline.yml`
   - Runs linting and type checks on PR
   - Blocks merge if checks fail
   
2. **Alternative:** Could add branch protection rules to require:
   - PR review before merge
   - All checks passing
   - Conventional commits in PR titles

## Troubleshooting

### Hook Not Running
```bash
# Verify husky is installed and git hooks are linked
ls -la .husky/

# Re-initialize if needed
npx husky install
```

### Commitlint Errors
```bash
# Test a message before committing
echo "feat: Test message." | npx commitlint
```

### Prettier vs ESLint Conflicts
Both configurations exist to prevent conflicts:
- ESLint: Logic and style rules
- Prettier: Code formatting only
- They're configured to work together without conflicts

### Bypass Temporarily
For debugging or emergency hotfixes:
```bash
git commit -m "message" --no-verify
```

## Next Steps

1. **Test the hooks:**
   ```bash
   # Make a change
   echo "test" > test.txt
   git add test.txt
   git commit -m "invalid message"  # Should fail
   ```

2. **Educate team:**
   - Share conventional commit format with team
   - Add pre-commit setup to onboarding docs
   - Reference COMMIT_GUIDE.md in PRs

3. **Expand enforcement:**
   - Add branch protection rules on GitHub
   - Add PR title validation to require conventional format
   - Consider adding auto-labeling based on commit type

4. **Monitor compliance:**
   - Track commit message distribution
   - Adjust types if needed based on team patterns
   - Document team-specific scope conventions

## Files Modified

- `.husky/pre-commit` - Configured to run lint-staged
- `.husky/commit-msg` - Configured to run commitlint
- `commitlint.config.js` - Conventional commit rules
- `package.json` - Added lint-staged config, added husky prepare script

## Summary

✅ **Goals Achieved:**
- Automated code quality enforcement on commit
- Conventional commit format enforced
- Zero-effort formatting via prettier
- ESLint compliance on staged files only
- Clear error messages for developers
