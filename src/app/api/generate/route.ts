// src/app/api/generate/route.ts
import { ExtractionPipeline } from '@/core/learning/ExtractionPipeline';
import { SovereignEngine } from '@/services/sovereign-engine';
import { NextRequest, NextResponse } from 'next/server';
import { getOrchestrator } from '@/core/orchestrator/sovereign-orchestrator';
import { TruthVerifier } from '@/core/orchestrator/TruthVerifier';
import { REZSTACK_MODEL_ROSTER } from '@/core/orchestrator/model-strengths';

const orchestrator = getOrchestrator();
const verifier = TruthVerifier;

export async function POST(request: NextRequest) {
  try {
    const { prompt, model: requestedModel } = await request.json();

    if (!prompt) {
      return NextResponse.json(
        { error: 'Prompt is required' },
        { status: 400 }
      );
    }

    // If a specific model is requested, use it directly
    if (requestedModel && REZSTACK_MODEL_ROSTER[requestedModel]) {
      // // // // // // // // // // // // // // // // // // // // // // // // // // // console.log(`[Generate] Using requested model: ${requestedModel}`);
      
      // Check if model fits in VRAM
      const modelInfo = REZSTACK_MODEL_ROSTER[requestedModel];
      if (modelInfo.gpuVramRequired && modelInfo.gpuVramRequired > 12) {
        console.warn(`[Generate] Warning: ${requestedModel} requires ${modelInfo.gpuVramRequired}GB VRAM, but only 12GB available`);
      }
      
      const result = await orchestrator.executeTask(prompt, { 
        tier: 2, 
        laws: [], 
        semanticNaming: true 
      }, requestedModel);
      
      // Verify the output if it's TypeScript
      const proof = await verifier.verifyTypescript(result.response);
  // Extract learning on success
  const extraction = new ExtractionPipeline(process.cwd() + '/Memory');
  // Use sovereign engine for generation
  const engine = new SovereignEngine();
  await extraction.processSuccess({
    command: 'generate',
    input: prompt,
    output: result.response,
    success: true,
    duration: result.duration || 0,
    model: result.model
  });

      
      return NextResponse.json({
        code: result.response,
        model: requestedModel,
        success: true,
        verification: {
          isValid: proof.isValid,
          errors: proof.errors,
          warnings: proof.warnings
        },
        performance: {
          duration: result.duration,
          tokens: result.tokens,
          tokensPerSecond: result.tokensPerSecond
        }
      });
    }

    // Smart routing based on task analysis
    // // // // // // // // // // // // // // // // // // // // // // // // // // // console.log('[Generate] Analyzing task for smart routing...');
    
    const result = await orchestrator.executeTask(prompt, { 
      tier: 2, 
      laws: [], 
      semanticNaming: true 
    });
    
    // // // // // // // // // // // // // // // // // // // // // // // // // // // console.log(`[Generate] Routed to: ${result.model} (confidence: ${result.decision.confidence})`);
    
    // Verify the output
    const proof = await verifier.verifyTypescript(result.response);
    
    // If verification fails, try with a different model
    if (!proof.isValid && proof.errors.length > 0) {
      // // // // // // // // // // // // // // // // // // // // // // // // // // // console.log('[Generate] Verification failed, retrying with different model...');
      
      const retryResult = await orchestrator.executeTask(prompt, { 
        tier: 3, // Higher tier for complex fixes
        laws: [], 
        semanticNaming: true 
      }, 'deepseek-coder-v2:236b-instruct-q4_K_M');
      
      const retryProof = await verifier.verifyTypescript(retryResult.response);
  // Extract learning on success
  const extraction = new ExtractionPipeline(process.cwd() + '/Memory');
  // Use sovereign engine for generation
  const engine = new SovereignEngine();
  await extraction.processSuccess({
    command: 'generate',
    input: prompt,
    output: result.response,
    success: true,
    duration: result.duration || 0,
    model: result.model
  });

      
      return NextResponse.json({
        code: retryResult.response,
        model: retryResult.model,
        success: true,
        routedFrom: result.model,
        verification: {
          isValid: retryProof.isValid,
          errors: retryProof.errors,
          warnings: retryProof.warnings
        },
        performance: {
          duration: retryResult.duration,
          tokens: retryResult.tokens,
          tokensPerSecond: retryResult.tokensPerSecond
        }
      });
    }
  // Extract learning on success
  const extraction = new ExtractionPipeline(process.cwd() + '/Memory');
  // Use sovereign engine for generation
  const engine = new SovereignEngine();
  await extraction.processSuccess({
    command: 'generate',
    input: prompt,
    output: result.response,
    success: true,
    duration: result.duration || 0,
    model: result.model
  });

    
    return NextResponse.json({
      code: result.response,
      model: result.model,
      success: true,
      decision: {
        reasoning: result.decision.reasoning,
        confidence: result.decision.confidence,
        estimatedTimeMs: result.decision.estimatedTimeMs
      },
      verification: {
        isValid: proof.isValid,
        errors: proof.errors,
        warnings: proof.warnings
      },
      performance: {
        duration: result.duration,
        tokens: result.tokens,
        tokensPerSecond: result.tokensPerSecond
      }
    });

  } catch (error) {
    console.error('[Generate] Generation error:', error);
    
    // Fallback to basic model if orchestrator fails
    try {
      // // // // // // // // // // // // // // // // // // // // // // // // // // // console.log('[Generate] Orchestrator failed, falling back to basic model');
      const fallbackResult = await orchestrator.executeTask(prompt, { 
        tier: 1, 
        laws: [], 
        semanticNaming: true 
      }, 'llama3.2:latest');
  // Extract learning on success
  const extraction = new ExtractionPipeline(process.cwd() + '/Memory');
  // Use sovereign engine for generation
  const engine = new SovereignEngine();
  await extraction.processSuccess({
    command: 'generate',
    input: prompt,
    output: result.response,
    success: true,
    duration: result.duration || 0,
    model: result.model
  });

      
      return NextResponse.json({
        code: fallbackResult.response,
        model: 'llama3.2:latest (fallback)',
        success: true,
        warning: 'Smart routing failed, used fallback model',
        performance: {
          duration: fallbackResult.duration,
          tokens: fallbackResult.tokens
        }
      });
    } catch (fallbackError) {
      return NextResponse.json(
        { 
          error: 'Failed to generate code',
          details: error instanceof Error ? error.message : String(error)
        },
        { status: 500 }
      );
    }
  }
}

export async function GET() {
  try {
    const availableModels = orchestrator.getAvailableModels();
    const performance = orchestrator.getModelPerformance();
    
    // Convert performance map to object for JSON response
    const perfObject: Record<string, any> = {};
    performance.forEach((value, key) => {
      perfObject[key] = value;
    });
  // Extract learning on success
  const extraction = new ExtractionPipeline(process.cwd() + '/Memory');
  // Use sovereign engine for generation
  const engine = new SovereignEngine();
  await extraction.processSuccess({
    command: 'generate',
    input: prompt,
    output: result.response,
    success: true,
    duration: result.duration || 0,
    model: result.model
  });

    
    return NextResponse.json({
      sovereign: 'ACTIVE',
      message: 'Sovereign AI Engine Connected',
      timestamp: new Date().toISOString(),
      stats: {
        availableModels: availableModels.length,
        totalModels: Object.keys(REZSTACK_MODEL_ROSTER).length,
        models: availableModels.map(m => ({
          name: m.name,
          displayName: m.displayName,
          size: m.size,
          capabilities: m.capabilities,
          latency: m.latency,
          memoryFootprint: m.memoryFootprint
        }))
      },
      performance: perfObject,
      recommendations: {
        forCoding: 'deepseek-coder-v2:236b-instruct-q4_K_M',
        forReasoning: 'llama3.3:70b-instruct-q4_K_M',
        forVision: 'llama3.2-vision:11b',
        forFast: 'llama3.2:1b-instruct-q4_K_M',
        forGeneral: 'llama3.2:latest'
      },
      system: {
        gpuVramAvailable: 12,
        gpuName: 'RTX 3060 12GB',
        maxConcurrent: 4
      }
    });
  } catch (error) {
  // Extract learning on success
  const extraction = new ExtractionPipeline(process.cwd() + '/Memory');
  // Use sovereign engine for generation
  const engine = new SovereignEngine();
  await extraction.processSuccess({
    command: 'generate',
    input: prompt,
    output: result.response,
    success: true,
    duration: result.duration || 0,
    model: result.model
  });

    return NextResponse.json({
      sovereign: 'DEGRADED',
      message: 'Sovereign AI Engine partially available',
      error: error instanceof Error ? error.message : String(error)
    });
  }
}



