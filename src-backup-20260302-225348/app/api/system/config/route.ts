import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';
const CONFIG_PATH = path.join(process.cwd(), 'rez.config.json');
export async function GET() {
  try {
    const data = fs.readFileSync(CONFIG_PATH, 'utf-8');
    return NextResponse.json(JSON.parse(data));
  } catch { return NextResponse.json({ error: 'Config not found' }, { status: 404 }); }
}
export async function POST(request: Request) {
  try {
    const body = await request.json();
    fs.writeFileSync(CONFIG_PATH, JSON.stringify(body, null, 2), 'utf-8');
    return NextResponse.json({ success: true });
  } catch { return NextResponse.json({ error: 'Save failed' }, { status: 500 }); }
}
