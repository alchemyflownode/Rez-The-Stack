import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const REMINDER_FILE = path.join(process.cwd(), 'brain', 'reminders', 'reminders.json');

// Initialize reminders file
if (!fs.existsSync(REMINDER_FILE)) {
  fs.writeFileSync(REMINDER_FILE, JSON.stringify([]));
}

export async function GET() {
  try {
    const reminders = JSON.parse(fs.readFileSync(REMINDER_FILE, 'utf-8'));
    return NextResponse.json({ 
      success: true, 
      reminders,
      count: reminders.length 
    });
  } catch (error) {
    return NextResponse.json({ 
      success: true, 
      reminders: [],
      count: 0 
    });
  }
}

export async function POST(req: NextRequest) {
  try {
    const { text, datetime } = await req.json();
    
    const reminders = JSON.parse(fs.readFileSync(REMINDER_FILE, 'utf-8'));
    
    const newReminder = {
      id: Date.now(),
      text: text || 'Social media post',
      datetime: datetime || new Date().toISOString(),
      created: new Date().toISOString(),
      status: 'pending'
    };
    
    reminders.push(newReminder);
    fs.writeFileSync(REMINDER_FILE, JSON.stringify(reminders, null, 2));
    
    return NextResponse.json({ 
      success: true, 
      reminder: newReminder 
    });
  } catch (error) {
    return NextResponse.json({ 
      success: false, 
      error: String(error) 
    }, { status: 500 });
  }
}

export async function DELETE(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const id = searchParams.get('id');
  
  if (!id) {
    return NextResponse.json({ error: 'No ID provided' }, { status: 400 });
  }
  
  try {
    const reminders = JSON.parse(fs.readFileSync(REMINDER_FILE, 'utf-8'));
    const filtered = reminders.filter((r: any) => r.id.toString() !== id);
    fs.writeFileSync(REMINDER_FILE, JSON.stringify(filtered, null, 2));
    
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ error: String(error) }, { status: 500 });
  }
}
