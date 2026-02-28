import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';
import { ROOT_SEEKER_PROMPTS } from '@/lib/root-seeker';
import { db } from '@/lib/db';

// Framework Architect - Distill roots into buildable structures
export async function POST(request: NextRequest) {
  try {
    const { domainId } = await request.json();

    if (!domainId) {
      return NextResponse.json({ error: 'Domain ID is required' }, { status: 400 });
    }

    const domain = await db.domain.findUnique({
      where: { id: domainId },
      include: {
        questions: {
          orderBy: { depth: 'asc' }
        }
      }
    });

    if (!domain) {
      return NextResponse.json({ error: 'Domain not found' }, { status: 404 });
    }

    const zai = await ZAI.create();

    // Compile insights from questions
    const insights = domain.questions
      .filter(q => q.answer)
      .map(q => `Depth ${q.depth}: ${q.question}\nAnswer: ${q.answer}`)
      .join('\n\n');

    // Generate framework
    const prompt = `${ROOT_SEEKER_PROMPTS.architect}

DOMAIN: ${domain.name}
DISCOVERED ROOT: ${domain.rootAnswer || 'See insights below'}

INSIGHTS FROM DESCENT:
${insights}

Based on the root truth discovered, create a framework that can be built upon.
The framework should:
1. Capture the essential structure of this domain
2. Be buildable (have clear components and flows)
3. Be measurable (have metrics for success)
4. Be transferable (principles can apply elsewhere)

Output complete JSON framework:`;

    const completion = await zai.chat.completions.create({
      messages: [
        { role: 'system', content: ROOT_SEEKER_PROMPTS.architect },
        { role: 'user', content: prompt }
      ],
      temperature: 0.5
    });

    const responseText = completion.choices[0]?.message?.content || '';
    
    // Parse framework from response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const frameworkData = jsonMatch ? JSON.parse(jsonMatch[0]) : {
      name: `${domain.name} Framework`,
      principles: ['Root principle not extracted'],
      components: [],
      flows: [],
      metrics: []
    };

    // Save framework
    const framework = await db.framework.create({
      data: {
        name: frameworkData.name || `${domain.name} Framework`,
        description: `Framework distilled from root-seeking in ${domain.name}`,
        structure: JSON.stringify(frameworkData),
        domainId: domain.id
      }
    });

    // Update domain status
    await db.domain.update({
      where: { id: domainId },
      data: { status: 'building' }
    });

    // Extract transferable patterns
    await extractPatterns(zai, domain.name, frameworkData);

    return NextResponse.json({
      success: true,
      framework: {
        id: framework.id,
        name: framework.name,
        ...frameworkData
      },
      domain: {
        id: domain.id,
        name: domain.name,
        status: 'building'
      }
    });

  } catch (error) {
    console.error('Architecture error:', error);
    return NextResponse.json(
      { error: 'Failed to architect framework', details: String(error) },
      { status: 500 }
    );
  }
}

// Extract patterns for deductive learning
async function extractPatterns(zai: Awaited<ReturnType<typeof ZAI.create>>, domainName: string, framework: any) {
  const prompt = `Given this framework from the "${domainName}" domain, extract transferable patterns:

FRAMEWORK: ${JSON.stringify(framework, null, 2)}

Extract patterns that could apply to OTHER domains.
Output JSON array of patterns:
[
  {
    "name": "Pattern Name",
    "description": "What this pattern does",
    "structure": {...},
    "potentialDomains": ["where else this could apply"]
  }
]`;

  try {
    const completion = await zai.chat.completions.create({
      messages: [
        { role: 'system', content: ROOT_SEEKER_PROMPTS.learn },
        { role: 'user', content: prompt }
      ],
      temperature: 0.6
    });

    const responseText = completion.choices[0]?.message?.content || '';
    const jsonMatch = responseText.match(/\[[\s\S]*\]/);
    
    if (jsonMatch) {
      const patterns = JSON.parse(jsonMatch[0]);
      
      for (const p of patterns) {
        await db.pattern.create({
          data: {
            name: p.name,
            description: p.description,
            structure: JSON.stringify(p.structure || {})
          }
        });
      }
    }
  } catch (error) {
    console.error('Pattern extraction error:', error);
    // Non-fatal, continue
  }
}

// Get existing frameworks
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const domainId = searchParams.get('domainId');

    const where = domainId ? { domainId } : {};
    
    const frameworks = await db.framework.findMany({
      where,
      include: { domain: true },
      orderBy: { createdAt: 'desc' }
    });

    return NextResponse.json({
      success: true,
      frameworks: frameworks.map(f => ({
        id: f.id,
        name: f.name,
        description: f.description,
        structure: JSON.parse(f.structure),
        domain: f.domain.name,
        version: f.version,
        createdAt: f.createdAt
      }))
    });

  } catch (error) {
    console.error('Get frameworks error:', error);
    return NextResponse.json(
      { error: 'Failed to get frameworks' },
      { status: 500 }
    );
  }
}
