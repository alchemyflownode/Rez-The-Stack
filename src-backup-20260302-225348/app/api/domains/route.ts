import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';

// Get all domains
export async function GET(request: NextRequest) {
  try {
    const domains = await db.domain.findMany({
      include: {
        _count: {
          select: { frameworks: true, questions: true, patterns: true }
        }
      },
      orderBy: { updatedAt: 'desc' }
    });

    return NextResponse.json({
      success: true,
      domains: domains.map(d => ({
        id: d.id,
        name: d.name,
        description: d.description,
        rootAnswer: d.rootAnswer,
        status: d.status,
        frameworksCount: d._count.frameworks,
        questionsCount: d._count.questions,
        patternsCount: d._count.patterns,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt
      }))
    });

  } catch (error) {
    console.error('Get domains error:', error);
    return NextResponse.json(
      { error: 'Failed to get domains' },
      { status: 500 }
    );
  }
}

// Create new domain
export async function POST(request: NextRequest) {
  try {
    const { name, description } = await request.json();

    if (!name) {
      return NextResponse.json({ error: 'Name is required' }, { status: 400 });
    }

    const domain = await db.domain.create({
      data: {
        name,
        description,
        status: 'exploring'
      }
    });

    return NextResponse.json({
      success: true,
      domain
    });

  } catch (error) {
    console.error('Create domain error:', error);
    return NextResponse.json(
      { error: 'Failed to create domain' },
      { status: 500 }
    );
  }
}

// Update domain
export async function PUT(request: NextRequest) {
  try {
    const { id, rootAnswer, status } = await request.json();

    if (!id) {
      return NextResponse.json({ error: 'ID is required' }, { status: 400 });
    }

    const domain = await db.domain.update({
      where: { id },
      data: {
        ...(rootAnswer && { rootAnswer }),
        ...(status && { status })
      }
    });

    return NextResponse.json({
      success: true,
      domain
    });

  } catch (error) {
    console.error('Update domain error:', error);
    return NextResponse.json(
      { error: 'Failed to update domain' },
      { status: 500 }
    );
  }
}

// Delete domain
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {
      return NextResponse.json({ error: 'ID is required' }, { status: 400 });
    }

    await db.domain.delete({
      where: { id }
    });

    return NextResponse.json({
      success: true,
      message: 'Domain deleted'
    });

  } catch (error) {
    console.error('Delete domain error:', error);
    return NextResponse.json(
      { error: 'Failed to delete domain' },
      { status: 500 }
    );
  }
}
