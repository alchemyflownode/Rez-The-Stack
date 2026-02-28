import { NextResponse } from 'next/server';
import { Governor } from '@/lib/delta-zero-engine';
import '@/lib/rules.setup';

export async function POST() {
  const text = "I don't know";
  const safe = Governor.enforce(text, "text");
  return NextResponse.json({ status: 'success', original: text, corrected: safe });
}
