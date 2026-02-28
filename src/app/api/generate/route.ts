import { NextRequest, NextResponse } from 'next/server';
import ZAI from 'z-ai-web-dev-sdk';
import { db } from '@/lib/db';

// App Factory - Generate actual code from frameworks
export async function POST(request: NextRequest) {
  try {
    const { frameworkId, type = 'app', name, requirements } = await request.json();

    if (!frameworkId) {
      return NextResponse.json({ error: 'Framework ID is required' }, { status: 400 });
    }

    const framework = await db.framework.findUnique({
      where: { id: frameworkId },
      include: { domain: true }
    });

    if (!framework) {
      return NextResponse.json({ error: 'Framework not found' }, { status: 404 });
    }

    const zai = await ZAI.create();
    const structure = JSON.parse(framework.structure);

    // Generate code based on type
    const typePrompts: Record<string, string> = {
      app: `Generate a complete Next.js application structure based on this framework.
Include:
- Main page component with UI
- Core logic hooks/functions
- Type definitions
- CSS styling (Tailwind)

Output as JSON with keys: files (array of {path, content, language})`,
      
      api: `Generate a REST API structure based on this framework.
Include:
- Route handlers
- Input/output types
- Validation logic
- Error handling

Output as JSON with keys: files (array of {path, content, language})`,
      
      component: `Generate a React component library based on this framework.
Include:
- Core components
- Props interfaces
- Hooks
- Utility functions

Output as JSON with keys: files (array of {path, content, language})`,
      
      system: `Generate a system architecture document based on this framework.
Include:
- Architecture diagram (ASCII)
- Data flow
- Component relationships
- Implementation steps

Output as JSON with keys: files (array of {path, content, language})`
    };

    const prompt = `FRAMEWORK: ${framework.name}
DOMAIN: ${framework.domain.name}
STRUCTURE: ${JSON.stringify(structure, null, 2)}

${typePrompts[type] || typePrompts.app}

${requirements ? `ADDITIONAL REQUIREMENTS:\n${requirements}` : ''}

Generate production-ready code that embodies the principles of this framework.
The code should be clean, well-typed, and follow best practices.`;

    const completion = await zai.chat.completions.create({
      messages: [
        { 
          role: 'system', 
          content: `You are a master software architect. Generate clean, production-ready code.
Always output valid JSON with a "files" array containing {path, content, language} objects.
The code should be immediately usable and well-documented.`
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.4,
      max_tokens: 4000
    });

    const responseText = completion.choices[0]?.message?.content || '';
    
    // Parse generated files
    const jsonMatch = responseText.match(/\{[\s\S]*"files"[\s\S]*\}/);
    const generated = jsonMatch ? JSON.parse(jsonMatch[0]) : {
      files: [{
        path: 'output.ts',
        content: responseText,
        language: 'typescript'
      }]
    };

    // Save generation
    const generation = await db.generation.create({
      data: {
        frameworkId: framework.id,
        type,
        name: name || `${framework.name} ${type}`,
        code: JSON.stringify(generated.files),
        description: `Generated from ${framework.name} framework`
      }
    });

    return NextResponse.json({
      success: true,
      generation: {
        id: generation.id,
        type,
        name: generation.name,
        files: generated.files,
        framework: framework.name,
        domain: framework.domain.name
      }
    });

  } catch (error) {
    console.error('Generation error:', error);
    return NextResponse.json(
      { error: 'Failed to generate', details: String(error) },
      { status: 500 }
    );
  }
}

// Get generations
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const frameworkId = searchParams.get('frameworkId');

    const where = frameworkId ? { frameworkId } : {};
    
    const generations = await db.generation.findMany({
      where,
      include: { framework: { include: { domain: true } } },
      orderBy: { createdAt: 'desc' }
    });

    return NextResponse.json({
      success: true,
      generations: generations.map(g => ({
        id: g.id,
        type: g.type,
        name: g.name,
        files: JSON.parse(g.code),
        status: g.status,
        framework: g.framework.name,
        domain: g.framework.domain.name,
        createdAt: g.createdAt
      }))
    });

  } catch (error) {
    console.error('Get generations error:', error);
    return NextResponse.json(
      { error: 'Failed to get generations' },
      { status: 500 }
    );
  }
}
