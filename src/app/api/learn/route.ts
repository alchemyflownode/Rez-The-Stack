import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';
import { ROOT_SEEKER_PROMPTS } from '@/lib/root-seeker';
import { db } from '@/lib/db';

// Deductive Learning System - Pattern memory and cross-domain application
export async function POST(request: NextRequest) {
  try {
    const { sourceDomain, targetDomain, context } = await request.json();

    if (!targetDomain) {
      return NextResponse.json({ error: 'Target domain is required' }, { status: 400 });
    }

    const zai = await ZAI.create();

    // Get relevant patterns from memory
    const patterns = await db.pattern.findMany({
      where: { confidence: { gte: 0.5 } },
      orderBy: { applications: 'desc' },
      take: 10
    });

    // Get source domain insights if specified
    let sourceInsights = '';
    if (sourceDomain) {
      const source = await db.domain.findFirst({
        where: { name: sourceDomain },
        include: { frameworks: true, questions: true }
      });
      if (source) {
        sourceInsights = `
SOURCE DOMAIN: ${source.name}
ROOT: ${source.rootAnswer || 'Not yet discovered'}
FRAMEWORKS: ${source.frameworks.map(f => f.name).join(', ')}
KEY QUESTIONS: ${source.questions.filter(q => q.answer).map(q => q.question).slice(0, 5).join('\n')}
`;
      }
    }

    // Apply deductive learning
    const prompt = `${ROOT_SEEKER_PROMPTS.learn}

TARGET DOMAIN: ${targetDomain}
${sourceInsights ? sourceInsights : ''}
EXISTING PATTERNS IN MEMORY:
${patterns.map(p => `- ${p.name}: ${p.description}`).join('\n')}

${context ? `ADDITIONAL CONTEXT:\n${context}` : ''}

Apply deductive learning:
1. Which existing patterns could transfer to this domain?
2. What new patterns might emerge here?
3. What root questions should be asked?

Output JSON:
{
  "applicablePatterns": [
    {
      "name": "Pattern Name",
      "adaptation": "How to apply in ${targetDomain}",
      "confidence": 0.0-1.0
    }
  ],
  "suggestedQuestions": [
    {
      "question": "Root-seeking question",
      "depth": 1-5,
      "reasoning": "Why this matters"
    }
  ],
  "newPatterns": [
    {
      "name": "New Pattern",
      "description": "What it captures",
      "structure": {}
    }
  ]
}`;

    const completion = await zai.chat.completions.create({
      messages: [
        { role: 'system', content: ROOT_SEEKER_PROMPTS.learn },
        { role: 'user', content: prompt }
      ],
      temperature: 0.6
    });

    const responseText = completion.choices[0]?.message?.content || '';
    
    // Parse learning output
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const learning = jsonMatch ? JSON.parse(jsonMatch[0]) : {
      applicablePatterns: [],
      suggestedQuestions: [],
      newPatterns: []
    };

    // Store new patterns
    if (learning.newPatterns) {
      for (const p of learning.newPatterns) {
        await db.pattern.create({
          data: {
            name: p.name,
            description: p.description,
            structure: JSON.stringify(p.structure || {}),
            confidence: 0.5
          }
        });
      }
    }

    // Update pattern applications
    if (learning.applicablePatterns) {
      for (const ap of learning.applicablePatterns) {
        const pattern = patterns.find(p => p.name === ap.name);
        if (pattern) {
          await db.pattern.update({
            where: { id: pattern.id },
            data: {
              applications: { increment: 1 },
              confidence: Math.min(1, pattern.confidence + 0.05)
            }
          });
        }
      }
    }

    return NextResponse.json({
      success: true,
      learning: {
        ...learning,
        patternsUsed: patterns.length
      },
      memory: {
        totalPatterns: await db.pattern.count(),
        totalApplications: patterns.reduce((sum, p) => sum + p.applications, 0)
      }
    });

  } catch (error) {
    console.error('Learning error:', error);
    return NextResponse.json(
      { error: 'Failed to apply deductive learning', details: String(error) },
      { status: 500 }
    );
  }
}

// Get pattern memory
export async function GET(request: NextRequest) {
  try {
    const patterns = await db.pattern.findMany({
      orderBy: [
        { applications: 'desc' },
        { confidence: 'desc' }
      ]
    });

    const memories = await db.systemMemory.findMany({
      orderBy: { updatedAt: 'desc' }
    });

    return NextResponse.json({
      success: true,
      patterns: patterns.map(p => ({
        id: p.id,
        name: p.name,
        description: p.description,
        structure: JSON.parse(p.structure),
        applications: p.applications,
        confidence: p.confidence
      })),
      memories: memories.map(m => ({
        id: m.id,
        key: m.key,
        value: JSON.parse(m.value),
        category: m.category,
        confidence: m.confidence
      }))
    });

  } catch (error) {
    console.error('Get memory error:', error);
    return NextResponse.json(
      { error: 'Failed to get pattern memory' },
      { status: 500 }
    );
  }
}
