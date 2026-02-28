import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    status: 'success',
    health: { cpu: 20, memory: 50 }
  });
}
