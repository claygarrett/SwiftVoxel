//
//  Shaders.metal
//  GrokVox
//
//  Created by Clay Garrett on 11/8/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIn
{
    float4 position [[position]];
    float4 color;
    float3 normal;
    bool highlighted;
    float2 uv;
    float3 shadow_coord;
};

struct VertexOut
{
    float4 position [[position]];
    float4 color;
    float3 normal;
    float directional_light_level;
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

vertex VertexOut vertex_project(const device VertexIn *vertices[[buffer(0)]],
                             constant Uniforms *uniforms [[buffer(1)]],
                             uint vid [[vertex_id]],
                             uint iid [[instance_id]])
{
    float4 sunDirection = { -1, -2, -1, 1} ;
    
    float dotProduct = dot(normalize(vertices[vid].normal), normalize(-sunDirection.xyz));
    
    
    
    VertexOut vertexOut;
    vertexOut.shadow_coord = (uniforms->shadow_mvp_xform_matrix * vertices[vid].position ).xyz;
    vertexOut.position = uniforms->modelViewProjectionMatrix * vertices[vid].position;
    vertexOut.normal =   vertices[vid].normal.xyz;
    vertexOut.highlighted = vertices[vid].highlighted;
    vertexOut.color = vertices[vid].color;
    vertexOut.directional_light_level = 0.7 + 0.3 * dotProduct;

    float2 uv = vertices[vid].uv;
    
    
   
    vertexOut.uv =   uv;
    
    //vertexOut.color = vertices[vid].color;

    
    return vertexOut;
}

fragment float4 fragment_flatcolor(VertexOut vertexIn [[stage_in]],
                                   texture2d<float> diffuseTexture [[texture(0)]],
                                   depth2d<float> shadowTexture [[texture(1)]],
                                   sampler albedoSampler [[sampler(0)]],
                                   sampler depthSampler [[sampler(1)]])
{
//    return float4(vertexIn.normal.x * 0.5 + 0.5, vertexIn.normal.y * 0.5 + 0.5, vertexIn.normal.z * 0.5 + 0.5 , 1.0);
    
    float4 diffuse;
    
    if(vertexIn.color.a == 0) {
        diffuse = diffuseTexture.sample(albedoSampler, vertexIn.uv.xy); // * vertexIn.color;
    } else {
        diffuse = vertexIn.color;
    }
    
    diffuse *= vertexIn.directional_light_level;
    
    constexpr sampler shadowSampler(coord::normalized,
                                    filter::linear,
                                    mip_filter::none,
                                    address::clamp_to_edge,
                                    compare_func::less);
    
    // Compare the depth value in the shadow map to the depth value of the fragment in the sun's.
    // frame of reference.  If the sample is occluded, it will be zero.
    
    
    float shadow_sample = shadowTexture.sample_compare(shadowSampler, vertexIn.shadow_coord.xy, vertexIn.shadow_coord.z);
    
    
    
    if (diffuse.a < 0.5) {
//       discard_fragment();
    }
 
    return float4(diffuse.xyz * (0.7 + shadow_sample * 0.3) , 1); //
}


//fragment float4 fragment_main(Vertex inVertex [[stage_in]])
//{
////    return float4(inVertex.normal.x, inVertex.normal.y, inVertex.normal.z, 1.0);
//}

