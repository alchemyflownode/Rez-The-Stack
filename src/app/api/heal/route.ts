import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';
import { ROOT_SEEKER_PROMPTS } from '@/lib/root-seeker';
import { db } from '@/lib/db';

// Self-Healing Module - Detect surface-level thinking and redirect
export async function POST(request: NextRequest) {
  try {
    const { context, domainId } = await request.json();

    if (!context) {
      return NextResponse.json({ error: 'Context is required' }, { status: 400 });
    }

    const zai = await ZAI.create();

    // Analyze for surface-level thinking
    const prompt = `${ROOT_SEEKER_PROMPTS.heal}

CONTEXT TO ANALYZE:
${context}

Detect if this thinking is stuck at the surface level.
Look for:
- Circular reasoning
- Feature lists without purpose
- Losing sight of root questions
- Solution-first instead of problem-first
- Analysis paralysis
- Accumulation without structure

Output diagnosis JSON:`;

    const completion = await zai.chat.completions.create({
      messages: [
        { role: 'system', content: ROOT_SEEKER_PROMPTS.heal },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3
    });

    const responseText = completion.choices[0]?.message?.content || '';
    
    // Parse diagnosis
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const diagnosis = jsonMatch ? JSON.parse(jsonMatch[0]) : {
      issue: 'Unknown',
      rootCause: 'Unable to diagnose',
      intervention: 'Continue exploration',
      confidence: 0.5
    };

    // Save healing log
    const healing = await db.healingLog.create({
      data: {
        domainId: domainId || null,
        issue: diagnosis.issue,
        diagnosis: diagnosis.rootCause,
        intervention: diagnosis.intervention,
        success: false // Will be updated when intervention applied
      }
    });

    // Determine if healing is needed
    const needsHealing = diagnosis.confidence > 0.6;

    return NextResponse.json({
      success: true,
      diagnosis: {
        ...diagnosis,
        healingId: healing.id
      },
      needsHealing,
      redirect: needsHealing ? {
        type: diagnosis.issue.includes('circular') ? 'new_angle' :
              diagnosis.issue.includes('feature') ? 'return_to_root' :
              diagnosis.issue.includes('paralysis') ? 'action' : 'descend',
        suggestion: diagnosis.intervention
      } : null
    });

  } catch (error) {
    console.error('Healing error:', error);
    return NextResponse.json(
      { error: 'Failed to diagnose', details: String(error) },
      { status: 500 }
    );
  }
}

// Apply healing intervention
export async function PUT(request: NextRequest) {
  try {
    const { healingId, appliedIntervention, success } = await request.json();

    await db.healingLog.update({
      where: { id: healingId },
      data: {
        intervention: appliedIntervention,
        success: success
      }
    });

    return NextResponse.json({
      success: true,
      message: 'Healing intervention recorded'
    });

  } catch (error) {
    console.error('Healing update error:', error);
    return NextResponse.json(
      { error: 'Failed to update healing' },
      { status: 500 }
    );
  }
}

// Get healing history
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const domainId = searchParams.get('domainId');

    const where = domainId ? { domainId } : {};
    
    const healings = await db.healingLog.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 20
    });

    return NextResponse.json({
      success: true,
      healings: healings.map(h => ({
        id: h.id,
        issue: h.issue,
        diagnosis: h.diagnosis,
        intervention: h.intervention,
        success: h.success,
        createdAt: h.createdAt
      }))
    });

  } catch (error) {
    console.error('Get healings error:', error);
    return NextResponse.json(
      { error: 'Failed to get healing history' },
      { status: 500 }
    );
  }
}
