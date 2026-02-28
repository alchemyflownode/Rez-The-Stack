import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';
import { ROOT_SEEKER_PROMPTS } from '@/lib/root-seeker';
import { db } from '@/lib/db';

// Root Discovery Engine - Guided descent into any domain
export async function POST(request: NextRequest) {
  try {
    const { domain, currentDepth = 1, previousAnswers = [] } = await request.json();

    if (!domain) {
      return NextResponse.json({ error: 'Domain is required' }, { status: 400 });
    }

    const zai = await ZAI.create();

    // Create or get domain
    let domainRecord = await db.domain.findFirst({
      where: { name: domain }
    });

    if (!domainRecord) {
      domainRecord = await db.domain.create({
        data: { name: domain, status: 'exploring' }
      });
    }

    // Generate next root-seeking question
    const prompt = `${ROOT_SEEKER_PROMPTS.descend}

DOMAIN: ${domain}
CURRENT DEPTH: ${currentDepth}
PREVIOUS INSIGHTS: ${JSON.stringify(previousAnswers)}

Generate the next question that will help descend deeper into the root of this domain.
The question should go deeper than surface-level features and use cases.

Output JSON format:
{
  "question": "The question to ask",
  "depth": ${currentDepth + 1},
  "isRoot": false,
  "reasoning": "Why this question leads to root",
  "expectedInsight": "What we might discover"
}`;

    const completion = await zai.chat.completions.create({
      messages: [
        { role: 'system', content: ROOT_SEEKER_PROMPTS.descend },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7
    });

    const responseText = completion.choices[0]?.message?.content || '';
    
    // Parse JSON from response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const questionData = jsonMatch ? JSON.parse(jsonMatch[0]) : {
      question: `What is the fundamental truth that makes ${domain} work?`,
      depth: currentDepth + 1,
      isRoot: currentDepth >= 4
    };

    // Save question
    await db.question.create({
      data: {
        domainId: domainRecord.id,
        question: questionData.question,
        depth: questionData.depth,
        isRoot: questionData.isRoot || false
      }
    });

    return NextResponse.json({
      success: true,
      domain: domainRecord,
      question: questionData,
      progress: {
        currentDepth: questionData.depth,
        maxDepth: 5,
        status: questionData.isRoot ? 'root_reached' : 'descending'
      }
    });

  } catch (error) {
    console.error('Discovery error:', error);
    return NextResponse.json(
      { error: 'Failed to discover root', details: String(error) },
      { status: 500 }
    );
  }
}

// Process answer and determine next step
export async function PUT(request: NextRequest) {
  try {
    const { domainId, questionId, answer } = await request.json();

    // Save answer
    await db.question.update({
      where: { id: questionId },
      data: { answer }
    });

    const question = await db.question.findUnique({
      where: { id: questionId }
    });

    // Check if we've reached root depth
    if (question?.depth >= 5 || question?.isRoot) {
      await db.domain.update({
        where: { id: domainId },
        data: { status: 'rooted' }
      });

      return NextResponse.json({
        success: true,
        status: 'rooted',
        message: 'Root discovered. Ready to architect framework.',
        nextStep: 'architect'
      });
    }

    return NextResponse.json({
      success: true,
      status: 'descending',
      nextDepth: (question?.depth || 1) + 1
    });

  } catch (error) {
    console.error('Answer processing error:', error);
    return NextResponse.json(
      { error: 'Failed to process answer' },
      { status: 500 }
    );
  }
}
