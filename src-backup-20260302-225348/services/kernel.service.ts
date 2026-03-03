// src/services/kernel.service.ts
// PSALM 139:23 "Search me, O God, and know my heart; test me and know my anxious thoughts."

export class KernelService {
  private static instance: KernelService;
  private baseUrl = '/api/kernel';

  public static getInstance(): KernelService {
    if (!KernelService.instance) {
      KernelService.instance = new KernelService();
    }
    return KernelService.instance;
  }

  public async execute(task: string): Promise<any> {
    try {
      const response = await fetch(this.baseUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ task }),
      });
      return await response.json();
    } catch (error: any) {
      console.error("Kernel Service Error:", error);
      return { status: 'error', error: error.message };
    }
  }
}
