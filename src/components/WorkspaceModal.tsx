'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Folder, FolderOpen, HardDrive, Star } from 'lucide-react';

interface WorkspaceModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (path: string) => void;
  currentPath?: string;
}

export const WorkspaceModal: React.FC<WorkspaceModalProps> = ({
  isOpen,
  onClose,
  onSelect,
  currentPath = ''
}) => {
  const [inputPath, setInputPath] = useState(currentPath);
  const [recentWorkspaces, setRecentWorkspaces] = useState<string[]>([]);

  // Load recent workspaces from localStorage
  useEffect(() => {
    const saved = localStorage.getItem('rezcode-workspaces');
    if (saved) {
      setRecentWorkspaces(JSON.parse(saved));
    }
  }, []);

  // Save workspace to history
  const saveWorkspace = (path: string) => {
    const updated = [path, ...recentWorkspaces.filter(w => w !== path)].slice(0, 5);
    setRecentWorkspaces(updated);
    localStorage.setItem('rezcode-workspaces', JSON.stringify(updated));
  };

  const handleSelect = (path: string) => {
    saveWorkspace(path);
    onSelect(path);
    onClose();
  };

  // Preset workspaces like your sample
  const presetWorkspaces = [
    { 
      name: 'RezStack-IDE', 
      path: 'G:\\okiru\\app builder\\RezStackFinal2\\RezStack-IDE',
      icon: '⚡',
      desc: 'Current IDE'
    },
    { 
      name: 'RezStackFinal', 
      path: 'G:\\okiru\\app builder\\RezStackFinal2\\RezStackFinal',
      icon: '🏛️',
      desc: 'Backend Services'
    },
    { 
      name: 'Desktop', 
      path: 'C:\\Users\\' + (typeof window !== 'undefined' ? window.location.pathname.split('\\')[2] || 'User' : 'User') + '\\Desktop',
      icon: '🖥️',
      desc: 'Quick Access'
    }
  ];

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/80 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        className="relative w-full max-w-2xl bg-gradient-to-b from-gray-900 to-gray-950 
                   border border-purple-500/30 rounded-2xl shadow-2xl overflow-hidden"
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-purple-500/30 
                      bg-gradient-to-r from-purple-900/20 to-gray-900">
          <div className="flex items-center gap-3">
            <FolderOpen className="w-5 h-5 text-purple-400" />
            <h2 className="text-lg font-semibold text-purple-300">Select Workspace</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-purple-500/20 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-400" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-6">
          {/* Path Input */}
          <div className="space-y-2">
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wider">
              Enter Path
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                value={inputPath}
                onChange={(e) => setInputPath(e.target.value)}
                placeholder="G:\okiru\app builder\RezStackFinal2\RezStack-IDE"
                className="flex-1 px-4 py-3 bg-gray-800/50 border border-purple-500/30 
                         rounded-lg text-sm font-mono text-gray-300 placeholder-gray-600
                         focus:outline-none focus:border-purple-500 focus:ring-1 focus:ring-purple-500"
              />
              <button
                onClick={() => handleSelect(inputPath)}
                className="px-6 py-3 bg-gradient-to-r from-purple-600 to-cyan-600 
                         hover:from-purple-700 hover:to-cyan-700 rounded-lg
                         text-sm font-medium text-white transition-all duration-200
                         shadow-lg shadow-purple-500/20"
              >
                Open
              </button>
            </div>
          </div>

          {/* Preset Workspaces - Exactly like your sample */}
          <div className="space-y-3">
            <label className="text-xs font-medium text-gray-500 uppercase tracking-wider">
              Quick Access
            </label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {presetWorkspaces.map((ws) => (
                <button
                  key={ws.path}
                  onClick={() => handleSelect(ws.path)}
                  className="flex flex-col items-center p-4 bg-gray-800/30 hover:bg-purple-500/10 
                           border border-purple-500/20 hover:border-purple-500/50 
                           rounded-xl transition-all duration-200 group"
                >
                  <span className="text-3xl mb-2">{ws.icon}</span>
                  <span className="text-sm font-medium text-gray-300 group-hover:text-purple-300">
                    {ws.name}
                  </span>
                  <span className="text-xs text-gray-600 group-hover:text-purple-400/70">
                    {ws.desc}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Recent Workspaces */}
          {recentWorkspaces.length > 0 && (
            <div className="space-y-3">
              <label className="text-xs font-medium text-gray-500 uppercase tracking-wider">
                Recent Workspaces
              </label>
              <div className="space-y-2">
                {recentWorkspaces.map((path) => (
                  <button
                    key={path}
                    onClick={() => handleSelect(path)}
                    className="w-full flex items-center gap-3 px-4 py-3 bg-gray-800/30 
                             hover:bg-purple-500/10 rounded-lg border border-purple-500/20
                             hover:border-purple-500/50 transition-all duration-200 group"
                  >
                    <HardDrive className="w-4 h-4 text-gray-500 group-hover:text-purple-400" />
                    <span className="flex-1 text-left text-sm font-mono text-gray-400 
                                   group-hover:text-purple-300 truncate">
                      {path}
                    </span>
                    <Star className="w-4 h-4 text-gray-600 group-hover:text-yellow-400" />
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
};
