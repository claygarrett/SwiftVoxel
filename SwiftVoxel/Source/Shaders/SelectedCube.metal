//
//  Shaders.metal
//  GrokVox
//
//  Created by Clay Garrett on 11/8/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;




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

fragment float4 fragment_selected(Vertex vertexIn [[stage_in]],
                                   texture2d<float> diffuseTexture [[texture(0)]],
                                   depth2d<float> shadowTexture [[texture(1)]],
                                   sampler albedoSampler [[sampler(0)]],
                                   sampler depthSampler [[sampler(1)]])
{
    
    constexpr sampler shadowSampler(coord::normalized,
                                    filter::linear,
                                    mip_filter::none,
                                    address::clamp_to_edge,
                                    compare_func::less);
    

    float shadow_sample = shadowTexture.sample_compare(shadowSampler, vertexIn.shadow_coord.xy, vertexIn.shadow_coord.z);
    
    return float4(1.0 * (0.2 + shadow_sample * 0.8), 0, 0, 1.0);

}


