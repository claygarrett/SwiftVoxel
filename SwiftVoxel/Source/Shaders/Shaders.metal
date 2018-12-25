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
    float2 uv;
};

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
    float4x4 modelViewMatrix;
    float4x4 modelMatrix;
};

struct PerInstanceUniforms {
    float4x4 modelMatrix;
};


vertex Vertex vertex_project(device Vertex *vertices[[buffer(0)]],
                             constant Uniforms *uniforms [[buffer(1)]],
                             constant PerInstanceUniforms *perInstanceUniforms [[buffer(2)]],
                             uint vid [[vertex_id]],
                             uint iid [[instance_id]])
{
    float4 sunDirection = { -1, 0, 0.4, 1} ;
    
    float dotProduct = dot(normalize(vertices[vid].normal), normalize(-sunDirection.xyz));
    
    
    
    Vertex vertexOut;
    vertexOut.position = uniforms->modelViewProjectionMatrix * vertices[vid].position;
    vertexOut.normal =   vertices[vid].normal.xyz;
    
    float2 uv = vertices[vid].uv;
    
    
   
    vertexOut.uv =   uv;
    vertexOut.color = (0.7 + 0.3 * float4(dotProduct, dotProduct, dotProduct, 1));// * vertices[vid].color;
    vertexOut.barycentricCoords = vertices[vid].barycentricCoords;
    
    
    return vertexOut;
}

fragment float4 fragment_flatcolor(Vertex vertexIn [[stage_in]],
                                   texture2d<float> diffuseTexture [[texture(0)]],
                                   sampler samplr [[sampler(0)]])
{
//    return float4(vertexIn.normal.x * 0.5 + 0.5, vertexIn.normal.y * 0.5 + 0.5, vertexIn.normal.z * 0.5 + 0.5 , 1.0);
    float4 diffuse = diffuseTexture.sample(samplr, vertexIn.uv.xy) * vertexIn.color;
    return diffuse;
    
//    if(vertexIn.barycentricCoords.x < 0.1) {
//        float4 multiplier = { 0.8, 0.8, 0.8, 1.0 };
//        return vertexIn.color * multiplier;
//    }
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

