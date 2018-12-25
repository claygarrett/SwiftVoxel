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
    float3 barycentricCoords;
    bool highlighted;
    float2 uv;
};


struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
};


fragment float4 fragment_selected(Vertex vertexIn [[stage_in]],
                                   texture2d<float> diffuseTexture [[texture(0)]],
                                   sampler samplr [[sampler(0)]])
{
    //    return float4(vertexIn.normal.x * 0.5 + 0.5, vertexIn.normal.y * 0.5 + 0.5, vertexIn.normal.z * 0.5 + 0.5 , 1.0);
    float4 diffuse = diffuseTexture.sample(samplr, vertexIn.uv.xy) * vertexIn.color;
    
    if (diffuse.a < 0.5) {
        discard_fragment();
    }
    
    return float4(1.0, 0, 0, 1.0);
    return vertexIn.color;
}


