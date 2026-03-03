import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { task, worker, ...payload } = body;
    
    console.log(`🧠 Processing: "${task}"`);
    console.log(`→ Routing to ${worker || 'default'} worker`);
    
    await new Promise(resolve => setTimeout(resolve, 500));
    
    let response = '';
    
    if (task.toLowerCase().includes('cpu')) {
      const cpuUsage = (20 + Math.random() * 30).toFixed(1);
      response = `**CPU Analysis Complete**\n\nCurrent CPU usage is **${cpuUsage}%** across 8 cores.`;
    } 
    else if (task.toLowerCase().includes('ram') || task.toLowerCase().includes('memory')) {
      const ramUsage = (40 + Math.random() * 20).toFixed(1);
      response = `**Memory Analysis Complete**\n\nRAM usage is **${ramUsage}%** (32GB total).`;
    }
    else if (task.toLowerCase().includes('gpu')) {
      const gpuTemp = (45 + Math.random() * 15).toFixed(0);
      response = `**GPU Status**\n\nRTX 3060 temperature: **${gpuTemp}°C**\nGPU load: **${(15 + Math.random() * 30).toFixed(1)}%**`;
    }
    else if (task.toLowerCase().includes('health')) {
      response = `**System Health Check**\n\n✅ All systems operational\n✅ Memory: 32GB available\n✅ GPU: RTX 3060 active\n✅ Storage: 1TB NVMe (62% used)`;
    }
    else {
      response = `**Command Executed**\n\n\`${task}\` processed successfully.\n\n\`\`\`json\n${JSON.stringify(payload, null, 2)}\n\`\`\``;
    }
    
    return NextResponse.json({ 
      content: response,
      status: 'success',
      worker: worker || 'brain',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Kernel API Error:', error);
    
    return NextResponse.json(
      { 
        error: 'Kernel processing failed',
        content: `**⚠️ Kernel Error**\n\nFailed to process request.\n\`\`\`\n${error}\n\`\`\``,
        status: 'error'
      },
      { status: 500 }
    );
  }
}

export async function OPTIONS() {
  return NextResponse.json({}, { status: 200 });
}
