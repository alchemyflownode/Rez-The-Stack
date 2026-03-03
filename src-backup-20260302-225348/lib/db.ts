// In-memory pattern storage (temporary)
export const db = {
  pattern: {
    patterns: [],
    async create(data: any) {
      const newPattern = {
        id: 'pattern-' + Date.now(),
        ...data.data,
        createdAt: new Date(),
        updatedAt: new Date()
      };
      this.patterns.push(newPattern);
      console.log('✅ Pattern saved:', data.data.name);
      return newPattern;
    },
    async findMany(options: any) {
      return this.patterns;
    }
  }
};
