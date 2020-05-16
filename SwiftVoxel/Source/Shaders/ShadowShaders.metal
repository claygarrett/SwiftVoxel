//
//  ShadowShaders.metal
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/29/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


#import "AAPLShaderTypes.h"

struct Vertex
{
    float4 position [[position]];
    float4 color;
    float3 normal;
    bool highlighted;
    float2 uv;
    float3 shadow_coord;
};


struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
    float4x4 shadow_mvp_matrix;
    float4x4 shadow_mvp_xform_matrix;
    
};

typedef struct ShadowOutput
{
    float4 position [[position]];
} ShadowOutput;

vertex ShadowOutput shadow_vertex(const device Vertex * positions [[ buffer(0) ]],
                                  constant Uniforms   & uniforms  [[ buffer(1) ]],
                                  uint                      vid       [[ vertex_id ]])
{
    ShadowOutput out;
    
    // Add vertex pos to fairy position and project to clip-space
    out.position = uniforms.shadow_mvp_matrix * float4(positions[vid].position);
    
    return out;
}
