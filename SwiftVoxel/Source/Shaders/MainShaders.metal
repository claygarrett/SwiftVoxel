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

vertex Vertex vertex_project(device Vertex *vertices[[buffer(0)]],
                             constant Uniforms *uniforms [[buffer(1)]],
                             uint vid [[vertex_id]],
                             uint iid [[instance_id]])
{
    float4 sunDirection = { -1, -1, 1, 1} ;
    
    float dotProduct = dot(normalize(vertices[vid].normal), normalize(-sunDirection.xyz));
    
    
    
    Vertex vertexOut;
    vertexOut.shadow_coord = (uniforms->shadow_mvp_xform_matrix * vertices[vid].position ).xyz;
    vertexOut.position = uniforms->modelViewProjectionMatrix * vertices[vid].position;
    vertexOut.normal =   vertices[vid].normal.xyz;
    vertexOut.highlighted = vertices[vid].highlighted;
    float2 uv = vertices[vid].uv;
    
    
   
    vertexOut.uv =   uv;
    vertexOut.color = (0.7 + 0.3 * float4(dotProduct, dotProduct, dotProduct, 1));
    //vertexOut.color = vertices[vid].color;

    
    return vertexOut;
}

fragment float4 fragment_flatcolor(Vertex vertexIn [[stage_in]],
                                   texture2d<float> diffuseTexture [[texture(0)]],
                                   depth2d<float> shadowTexture [[texture(1)]],
                                   sampler albedoSampler [[sampler(0)]],
                                   sampler depthSampler [[sampler(1)]])
{
//    return float4(vertexIn.normal.x * 0.5 + 0.5, vertexIn.normal.y * 0.5 + 0.5, vertexIn.normal.z * 0.5 + 0.5 , 1.0);
    float4 diffuse = diffuseTexture.sample(albedoSampler, vertexIn.uv.xy) * vertexIn.color; // * vertexIn.color;
    
    constexpr sampler shadowSampler(coord::normalized,
                                    filter::linear,
                                    mip_filter::none,
                                    address::clamp_to_edge,
                                    compare_func::less);
    
    // Compare the depth value in the shadow map to the depth value of the fragment in the sun's.
    // frame of reference.  If the sample is occluded, it will be zero.
    
    
    float shadow_sample = shadowTexture.sample_compare(shadowSampler, vertexIn.shadow_coord.xy, vertexIn.shadow_coord.z);
    
    
    
    if (diffuse.a < 0.5) {
       //discard_fragment();
    }
 
    return float4(diffuse.xyz * (0.7 + shadow_sample * 0.3) , 1); //
    return vertexIn.color;
}

vertex Vertex vertex_main(device Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]])
{
    return vertices[vid];
}

//fragment float4 fragment_main(Vertex inVertex [[stage_in]])
//{
////    return float4(inVertex.normal.x, inVertex.normal.y, inVertex.normal.z, 1.0);
//}

