import { create } from 'zustand';

interface CanvasStore {
  results: any[];
  images: any[];
  setResults: (results: any[]) => void;
  setImages: (images: any[]) => void;
}

export const useCanvasStore = create<CanvasStore>((set) => ({
  results: [],
  images: [],
  setResults: (results) => set({ results }),
  setImages: (images) => set({ images })
}));
