'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { 
  ChevronRight, 
  ChevronDown, 
  Folder, 
  File, 
  Image, 
  Code, 
  FileText,
  Package,
  Settings,
  FileJson,
  Loader,
  Search,
  RefreshCw,
  Home,
  ArrowUp,
  Copy,
  Scissors,
  Trash2,
  FilePlus,
  FolderPlus,
  Download,
  Upload,
  Edit,
  MoreVertical,
  X
} from 'lucide-react';

interface FileNode {
  name: string;
  path: string;
  type: 'file' | 'directory';
  extension?: string;
  children?: FileNode[];
  size?: number;
  modified?: string;
}

interface FileTreeProps {
  workspace?: string;
  className?: string;
  onFileSelect?: (path: string) => void;
}

export const FileTree: React.FC<FileTreeProps> = ({ 
  workspace = '.', 
  className = '',
  onFileSelect 
}) => {
  const [tree, setTree] = useState<FileNode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set(['src']));
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [showHidden, setShowHidden] = useState(false);
  const [currentPath, setCurrentPath] = useState(workspace);
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number; path: string; type: string } | null>(null);
  const [renamingFile, setRenamingFile] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState('');

  // Load file tree
  const loadFileTree = useCallback(async (path: string = currentPath) => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/workspace/files', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ workspace: path, showHidden })
      });
      
      const data = await response.json();
      
      if (data.success) {
        setTree(data.tree || []);
        setCurrentPath(path);
      } else {
        setError(data.error || 'Failed to load workspace');
      }
    } catch (error) {
      setError('Connection error');
    } finally {
      setLoading(false);
    }
  }, [currentPath, showHidden]);

  useEffect(() => {
    loadFileTree();
  }, [workspace, showHidden]);

  // Listen for workspace changes
  useEffect(() => {
    const handleWorkspaceChange = (event: CustomEvent) => {
      loadFileTree(event.detail);
    };
    
    window.addEventListener('workspace-changed', handleWorkspaceChange as EventListener);
    return () => window.removeEventListener('workspace-changed', handleWorkspaceChange as EventListener);
  }, [loadFileTree]);

  // File operations
  const handleFileClick = (path: string, type: string) => {
    if (type === 'directory') {
      toggleFolder(path);
    } else {
      setSelectedFile(path);
      onFileSelect?.(path);
    }
  };

  const handleDoubleClick = (node: FileNode) => {
    if (node.type === 'directory') {
      loadFileTree(node.path);
    }
  };

  const handleContextMenu = (e: React.MouseEvent, path: string, type: string) => {
    e.preventDefault();
    setContextMenu({ x: e.clientX, y: e.clientY, path, type });
  };

  const handleRename = (path: string) => {
    setRenamingFile(path);
    setRenameValue(path.split('/').pop() || '');
    setContextMenu(null);
  };

  const handleRenameSubmit = async (oldPath: string) => {
    // API call to rename file
    console.log('Renaming:', oldPath, 'to', renameValue);
    setRenamingFile(null);
    loadFileTree();
  };

  const handleDelete = async (path: string) => {
    if (confirm(`Are you sure you want to delete ${path}?`)) {
      // API call to delete file
      console.log('Deleting:', path);
      loadFileTree();
    }
    setContextMenu(null);
  };

  const handleNewFile = async () => {
    const name = prompt('Enter file name:');
    if (name) {
      // API call to create file
      console.log('Creating file:', name);
      loadFileTree();
    }
  };

  const handleNewFolder = async () => {
    const name = prompt('Enter folder name:');
    if (name) {
      // API call to create folder
      console.log('Creating folder:', name);
      loadFileTree();
    }
  };

  const handleCopy = (path: string) => {
    navigator.clipboard.writeText(path);
    setContextMenu(null);
  };

  const toggleFolder = (path: string) => {
    const newExpanded = new Set(expandedFolders);
    if (newExpanded.has(path)) {
      newExpanded.delete(path);
    } else {
      newExpanded.add(path);
    }
    setExpandedFolders(newExpanded);
  };

  const navigateUp = () => {
    const parent = currentPath.split('/').slice(0, -1).join('/') || '.';
    loadFileTree(parent);
  };

  const navigateHome = () => {
    loadFileTree('.');
  };

  const getFileIcon = (fileName: string, extension?: string) => {
    if (extension === '.tsx' || extension === '.ts') return <Code className="w-4 h-4 text-blue-400" />;
    if (extension === '.js' || extension === '.jsx') return <Code className="w-4 h-4 text-yellow-400" />;
    if (extension === '.json') return <FileJson className="w-4 h-4 text-green-400" />;
    if (extension === '.md') return <FileText className="w-4 h-4 text-purple-400" />;
    if (extension === '.ps1' || extension === '.bat') return <Settings className="w-4 h-4 text-gray-400" />;
    if (extension === '.py') return <Code className="w-4 h-4 text-blue-300" />;
    if (fileName.match(/\.(png|jpg|jpeg|gif|svg)$/i)) return <Image className="w-4 h-4 text-pink-400" />;
    if (fileName === 'package.json') return <Package className="w-4 h-4 text-red-400" />;
    return <File className="w-4 h-4 text-gray-400" />;
  };

  const formatSize = (bytes?: number) => {
    if (!bytes) return '';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const filterTree = (nodes: FileNode[]): FileNode[] => {
    if (!searchQuery) return nodes;
    
    return nodes.filter(node => {
      if (node.name.toLowerCase().includes(searchQuery.toLowerCase())) return true;
      if (node.children) {
        const filteredChildren = filterTree(node.children);
        if (filteredChildren.length > 0) return true;
      }
      return false;
    }).map(node => ({
      ...node,
      children: node.children ? filterTree(node.children) : undefined
    }));
  };

  const renderNode = (node: FileNode, level: number = 0) => {
    const isExpanded = expandedFolders.has(node.path);
    const isSelected = selectedFile === node.path;
    const isRenaming = renamingFile === node.path;
    const paddingLeft = level * 20;

    if (node.type === 'directory') {
      return (
        <div data-testid="filetree-main"  key={node.path}>
          <div data-testid="filetree-main" 
            className={`flex items-center gap-1 px-2 py-1.5 hover:bg-gray-800/50 rounded cursor-pointer transition-colors group ${isSelected ? 'bg-purple-500/20' : ''}`}
            style={{ paddingLeft: `${paddingLeft}px` }}
            onClick={() => handleFileClick(node.path, 'directory')}
            onDoubleClick={() => handleDoubleClick(node)}
            onContextMenu={(e) => handleContextMenu(e, node.path, 'directory')}
          >
            {isExpanded ? (
              <ChevronDown className="w-4 h-4 text-gray-500" />
            ) : (
              <ChevronRight className="w-4 h-4 text-gray-500" />
            )}
            <Folder className="w-4 h-4 text-yellow-500" />
            <span className="text-sm text-gray-300 truncate flex-1">{node.name}</span>
            
            {/* Quick actions on hover */}
            <div data-testid="filetree-main"  className="hidden group-hover:flex items-center gap-1">
              <button className="p-1 hover:bg-gray-700 rounded" onClick={(e) => { e.stopPropagation(); handleNewFile(); }}>
                <FilePlus className="w-3 h-3" />
              </button>
              <button className="p-1 hover:bg-gray-700 rounded" onClick={(e) => { e.stopPropagation(); handleNewFolder(); }}>
                <FolderPlus className="w-3 h-3" />
              </button>
            </div>
          </div>
          {isExpanded && node.children?.map(child => renderNode(child, level + 1))}
        </div>
      );
    }

    return (
      <div data-testid="filetree-main" 
        key={node.path}
        className={`flex items-center gap-2 px-2 py-1.5 hover:bg-gray-800/50 rounded cursor-pointer transition-colors group ${isSelected ? 'bg-purple-500/20' : ''}`}
        style={{ paddingLeft: `${paddingLeft + 24}px` }}
        onClick={() => handleFileClick(node.path, 'file')}
        onDoubleClick={() => handleDoubleClick(node)}
        onContextMenu={(e) => handleContextMenu(e, node.path, 'file')}
      >
        {getFileIcon(node.name, node.extension)}
        {isRenaming ? (
          <input
            type="text"
            value={renameValue}
            onChange={(e) => setRenameValue(e.target.value)}
            onBlur={() => handleRenameSubmit(node.path)}
            onKeyDown={(e) => e.key === 'Enter' && handleRenameSubmit(node.path)}
            className="flex-1 bg-gray-700 text-sm px-1 rounded outline-none focus:ring-1 focus:ring-purple-500"
            autoFocus
            onClick={(e) => e.stopPropagation()}
          />
        ) : (
          <>
            <span className="text-sm text-gray-400 group-hover:text-gray-300 truncate flex-1">{node.name}</span>
            {node.size && (
              <span className="text-xs text-gray-600 ml-2">{formatSize(node.size)}</span>
            )}
          </>
        )}
      </div>
    );
  };

  const filteredTree = searchQuery ? filterTree(tree) : tree;

  return (
    <div data-testid="filetree-main"  className={`h-full flex flex-col ${className}`}>
      {/* Explorer Toolbar */}
      <div data-testid="filetree-main"  className="p-2 border-b border-gray-800 space-y-2">
        {/* Navigation Bar */}
        <div data-testid="filetree-main"  className="flex items-center gap-1">
          <button
            onClick={navigateHome}
            className="p-1.5 hover:bg-gray-800 rounded transition-colors"
            title="Home"
          >
            <Home className="w-4 h-4 text-gray-400" />
          </button>
          <button
            onClick={navigateUp}
            className="p-1.5 hover:bg-gray-800 rounded transition-colors"
            title="Up"
          >
            <ArrowUp className="w-4 h-4 text-gray-400" />
          </button>
          <button
            onClick={() => loadFileTree()}
            className="p-1.5 hover:bg-gray-800 rounded transition-colors"
            title="Refresh"
          >
            <RefreshCw className="w-4 h-4 text-gray-400" />
          </button>
          
          {/* Path Bar */}
          <div data-testid="filetree-main"  className="flex-1 flex items-center gap-1 px-2 py-1 bg-gray-900 rounded text-xs text-gray-400">
            {currentPath.split('/').map((part, i, arr) => (
              <React.Fragment key={i}>
                {i > 0 && <ChevronRight className="w-3 h-3 text-gray-600" />}
                <button
                  className="hover:text-purple-400 hover:underline"
                  onClick={() => loadFileTree(arr.slice(0, i + 1).join('/'))}
                >
                  {part || '.'}
                </button>
              </React.Fragment>
            ))}
          </div>

          {/* Search */}
          <div data-testid="filetree-main"  className="relative">
            <Search className="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3 text-gray-500" />
            <input
              type="text"
              placeholder="Search"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-32 pl-7 pr-2 py-1 bg-gray-900 border border-gray-800 rounded text-xs focus:outline-none focus:border-purple-500"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-2 top-1/2 -translate-y-1/2"
              >
                <X className="w-3 h-3 text-gray-500" />
              </button>
            )}
          </div>

          {/* New File/Folder Menu */}
          <div data-testid="filetree-main"  className="relative">
            <button
              onClick={() => {}}
              className="p-1.5 hover:bg-gray-800 rounded transition-colors"
              title="New"
            >
              <FilePlus className="w-4 h-4 text-gray-400" />
            </button>
          </div>

          {/* Toggle Hidden Files */}
          <button
            onClick={() => setShowHidden(!showHidden)}
            className={`p-1.5 rounded transition-colors ${showHidden ? 'bg-purple-500/20 text-purple-400' : 'hover:bg-gray-800 text-gray-400'}`}
            title="Show hidden files"
          >
            <Settings className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* File Tree */}
      <div data-testid="filetree-main"  className="flex-1 overflow-auto p-2">
        {loading ? (
          <div data-testid="filetree-main"  className="flex items-center justify-center p-8">
            <Loader className="w-5 h-5 text-purple-500 animate-spin" />
          </div>
        ) : error ? (
          <div data-testid="filetree-main"  className="p-4 text-center">
            <p className="text-sm text-red-400 mb-2">{error}</p>
            <button 
              onClick={() => loadFileTree()}
              className="text-xs text-purple-400 hover:text-purple-300"
            >
              Retry
            </button>
          </div>
        ) : filteredTree.length === 0 ? (
          <div data-testid="filetree-main"  className="p-4 text-center text-sm text-gray-500">
            {searchQuery ? 'No matches found' : 'Folder is empty'}
          </div>
        ) : (
          filteredTree.map(node => renderNode(node))
        )}
      </div>

      {/* Context Menu */}
      {contextMenu && (
        <div data-testid="filetree-main" 
          className="fixed bg-gray-900 border border-gray-800 rounded-lg shadow-xl py-1 z-50 text-sm"
          style={{ top: contextMenu.y, left: contextMenu.x }}
          onMouseLeave={() => setContextMenu(null)}
        >
          {contextMenu.type === 'file' ? (
            <>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <Edit className="w-4 h-4" /> Rename
              </button>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <Copy className="w-4 h-4" /> Copy
              </button>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <Scissors className="w-4 h-4" /> Cut
              </button>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2 text-red-400">
                <Trash2 className="w-4 h-4" /> Delete
              </button>
            </>
          ) : (
            <>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <FolderPlus className="w-4 h-4" /> New Folder
              </button>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <FilePlus className="w-4 h-4" /> New File
              </button>
              <div data-testid="filetree-main"  className="border-t border-gray-800 my-1" />
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <Copy className="w-4 h-4" /> Copy Path
              </button>
              <button className="w-full px-4 py-2 text-left hover:bg-gray-800 flex items-center gap-2">
                <RefreshCw className="w-4 h-4" /> Refresh
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
};

