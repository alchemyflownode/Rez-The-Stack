'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ChevronRight, 
  ChevronDown, 
  Folder, 
  File, 
  FileText, 
  Image, 
  Code,
  Terminal,
  Package,
  Settings,
  RefreshCw,
  Home,
  ArrowUp
} from 'lucide-react';

interface FileNode {
  name: string;
  path: string;
  type: 'file' | 'directory';
  children?: FileNode[];
  extension?: string;
}

interface FileTreeProps {
  rootPath?: string;
  currentPath?: string;
  workspace?: string;
  onFileSelect: (path: string) => void;
  onPathChange?: (path: string) => void;
  className?: string;
}

export const FileTree: React.FC<FileTreeProps> = ({ 
  rootPath = 'src', 
  currentPath = '',
  workspace,
  onFileSelect,
  onPathChange,
  className = '' 
}) => {
  const [currentRoot, setCurrentRoot] = useState(() => {
    // Use workspace if provided, otherwise fall back to rootPath
    if (workspace && workspace !== '.') {
      return workspace;
    }
    return rootPath === 'src' ? '.' : rootPath;
  });
  
  const [tree, setTree] = useState<FileNode[]>([]);
  const [expanded, setExpanded] = useState<Set<string>>(new Set([]));
  const [loading, setLoading] = useState(true);

    useEffect(() => {
    // // // console.log('?? FileTree mounted', { workspace, currentPath, rootPath });
  }, [workspace, currentPath, rootPath]);

  // Load file tree when root changes
  useEffect(() => {
    loadFileTree(currentRoot);
  }, [currentRoot]);

  // Listen for workspace changes
  useEffect(() => {
    const handleWorkspaceChange = (e: CustomEvent) => {
      const newPath = e.detail?.path;
      if (newPath) {
        setCurrentRoot(newPath);
        loadFileTree(newPath);
        setExpanded(prev => {
          const next = new Set(prev);
          next.add(newPath);
          return next;
        });
      }
    };

    window.addEventListener('workspace:changed', handleWorkspaceChange as EventListener);
    return () => window.removeEventListener('workspace:changed', handleWorkspaceChange as EventListener);
  }, []);

  // Auto-expand to current path
  useEffect(() => {
    if (currentPath && currentPath !== '.') {
      const parts = currentPath.split('/');
      let path = '';
      const toExpand = new Set(expanded);
      
      parts.forEach(part => {
        path = path ? `${path}/${part}` : part;
        toExpand.add(path);
      });
      
      setExpanded(toExpand);
    }
  }, [currentPath]);

  const loadFileTree = async (path: string) => {
    setLoading(true);
    try {
      const response = await fetch('/api/files/tree', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path })
      });
      const data = await response.json();
      setTree(data.tree || []);
      
      // Auto-expand root
      setExpanded(prev => {
        const next = new Set(prev);
        next.add(path);
        return next;
      });
    } catch (error) {
      console.error('Failed to load file tree:', error);
      setTree(getMockTree(path));
    } finally {
      setLoading(false);
    }
  };

  const toggleExpand = (path: string) => {
    setExpanded(prev => {
      const next = new Set(prev);
      if (next.has(path)) {
        next.delete(path);
      } else {
        next.add(path);
      }
      return next;
    });
  };

  const navigateUp = () => {
    if (currentRoot === '.') return;
    
    const parent = currentRoot.split('/').slice(0, -1).join('/') || '.';
    setCurrentRoot(parent);
    onPathChange?.(parent);
  };

  const navigateHome = () => {
    setCurrentRoot(workspace || '.');
    onPathChange?.(workspace || '.');
  };

  const getFileIcon = (fileName: string) => {
    const ext = fileName.split('.').pop()?.toLowerCase();
    if (fileName === 'package.json') return <Package className="w-4 h-4 text-amber-400" />;
    if (fileName === 'tsconfig.json') return <Settings className="w-4 h-4 text-blue-400" />;
    if (ext === 'tsx' || ext === 'ts') return <Code className="w-4 h-4 text-blue-400" />;
    if (ext === 'js' || ext === 'jsx') return <Code className="w-4 h-4 text-yellow-400" />;
    if (ext === 'css' || ext === 'scss') return <FileText className="w-4 h-4 text-pink-400" />;
    if (ext === 'json') return <FileText className="w-4 h-4 text-green-400" />;
    if (ext === 'md') return <FileText className="w-4 h-4 text-gray-400" />;
    if (ext === 'png' || ext === 'jpg' || ext === 'svg') return <Image className="w-4 h-4 text-purple-400" />;
    return <File className="w-4 h-4 text-gray-400" />;
  };

  const renderNode = (node: FileNode, depth: number = 0) => {
    const isExpanded = expanded.has(node.path);
    const paddingLeft = depth * 12;

    if (node.type === 'directory') {
      return (
        <div key={node.path}>
          <div
            className="flex items-center gap-1 px-2 py-1.5 hover:bg-purple-500/10 rounded-lg cursor-pointer transition-all group"
            style={{ paddingLeft: `${paddingLeft}px` }}
            onClick={() => toggleExpand(node.path)}
            onDoubleClick={() => {
              setCurrentRoot(node.path);
              onPathChange?.(node.path);
            }}
          >
            {isExpanded ? (
              <ChevronDown className="w-4 h-4 text-purple-400/70" />
            ) : (
              <ChevronRight className="w-4 h-4 text-purple-400/70" />
            )}
            <Folder className="w-4 h-4 text-purple-400" />
            <span className="text-sm text-gray-300 group-hover:text-purple-300">
              {node.name}
            </span>
          </div>
          <AnimatePresence>
            {isExpanded && node.children && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.15 }}
              >
                {node.children.map(child => renderNode(child, depth + 1))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      );
    } else {
      return (
        <div
          key={node.path}
          className="flex items-center gap-2 px-2 py-1.5 ml-4 hover:bg-purple-500/10 rounded-lg cursor-pointer transition-all group"
          style={{ paddingLeft: `${paddingLeft + 16}px` }}
          onClick={() => onFileSelect(node.path)}
        >
          {getFileIcon(node.name)}
          <span className="text-sm text-gray-400 group-hover:text-purple-300">
            {node.name}
          </span>
        </div>
      );
    }
  };

  return (
    <div className={`h-full flex flex-col ${className}`}>
      {/* Explorer Header with Navigation */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-purple-500/20">
        <div className="flex items-center gap-2">
          <Terminal className="w-4 h-4 text-purple-400" />
          <span className="text-xs font-medium text-purple-300 uppercase tracking-wider">
            EXPLORER
          </span>
        </div>
        <div className="flex items-center gap-1">
          <button 
            onClick={navigateUp}
            className="p-1 hover:bg-purple-500/20 rounded-md transition-colors group"
            title="Go up"
            disabled={currentRoot === '.'}
          >
            <ArrowUp className="w-3.5 h-3.5 text-gray-500 group-hover:text-purple-400" />
          </button>
          <button 
            onClick={navigateHome}
            className="p-1 hover:bg-purple-500/20 rounded-md transition-colors group"
            title="Go to workspace root"
          >
            <Home className="w-3.5 h-3.5 text-gray-500 group-hover:text-purple-400" />
          </button>
          <button 
            onClick={() => loadFileTree(currentRoot)}
            className="p-1 hover:bg-purple-500/20 rounded-md transition-colors group"
            title="Refresh"
          >
            <RefreshCw className="w-3.5 h-3.5 text-gray-500 group-hover:text-purple-400" />
          </button>
        </div>
      </div>

      {/* Current Path - Shows where you are */}
      <div className="px-3 py-1.5 border-b border-purple-500/10 bg-purple-500/5">
        <span className="text-[10px] font-mono text-purple-400/70 truncate block">
          ?? {currentRoot || '~'}
        </span>
      </div>

      {/* File Tree */}
      <div className="flex-1 overflow-y-auto p-2">
        {loading ? (
          <div className="space-y-2 p-2">
            {[1, 2, 3, 4].map(i => (
              <div key={i} className="animate-pulse flex items-center gap-2">
                <div className="w-4 h-4 bg-purple-500/20 rounded" />
                <div className="h-4 w-32 bg-purple-500/20 rounded" />
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-0.5">
            {tree.map(node => renderNode(node))}
          </div>
        )}
      </div>
    </div>
  );
};

// Mock tree with dynamic root
function getMockTree(root: string): FileNode[] {
  if (root === '.' || root === 'src') {
    return [
      {
        name: 'src',
        path: 'src',
        type: 'directory',
        children: [
          {
            name: 'app',
            path: 'src/app',
            type: 'directory',
            children: [
              { name: 'page.tsx', path: 'src/app/page.tsx', type: 'file', extension: 'tsx' },
              { name: 'layout.tsx', path: 'src/app/layout.tsx', type: 'file', extension: 'tsx' },
              { name: 'globals.css', path: 'src/app/globals.css', type: 'file', extension: 'css' }
            ]
          },
          {
            name: 'components',
            path: 'src/components',
            type: 'directory',
            children: [
              { name: 'FileTree.tsx', path: 'src/components/FileTree.tsx', type: 'file', extension: 'tsx' },
              { name: 'JARVISTerminal.tsx', path: 'src/components/JARVISTerminal.tsx', type: 'file', extension: 'tsx' }
            ]
          }
        ]
      }
    ];
  }
  return [];
}





