// THE SOVEREIGN COMPONENT EXCHANGE (SCE) STANDARD v1.0
// "The HTML of Synthetic Reality"

export interface SCEManifest {
  id: string;          // Unique concept identifier
  version: string;     // SCE Version
  concept: string;     // Human-readable concept name
  provenance: string[]; // Sources (Wikipedia, GitHub, Synthetic)
}

export interface SCEVisualDNA {
  style: string;       // e.g., "Cyberpunk, Neon, Noir"
  elements: string[];  // Key visual components
  mood: string;        // Emotional tone
}

export interface SCEBlueprint {
  manifest: SCEManifest;
  visual_dna: SCEVisualDNA;
  spatial_logic: string; // How components relate (e.g., "Masonry Grid")
  export_targets: { 
    threejs?: string; 
    midjourney?: string; 
    unreal?: string;
    json?: string; 
  };
}

// VALIDATION FUNCTION
export function validateSCE(blueprint: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  
  if (!blueprint.manifest?.id) errors.push("Missing Manifest ID");
  if (!blueprint.visual_dna?.style) errors.push("Missing Visual DNA style");
  if (!blueprint.spatial_logic) errors.push("Missing Spatial Logic");
  
  return {
    valid: errors.length === 0,
    errors
  };
}
