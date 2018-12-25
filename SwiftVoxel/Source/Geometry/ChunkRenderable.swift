//
//  ChunkRenderable.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/25/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import simd

class ChunkRenderable: Renderable {
    
    var vertexBuffer:MTLBuffer!
    var indexBuffer:MTLBuffer!
    var uniformBuffer:MTLBuffer!
    
    
    
    var commandEncoder:MTLRenderCommandEncoder!
    var diffuseTexture:MTLTexture!
    var samplerState:MTLSamplerState!
    
    var rotationY:Float = 0
    let rotationDampening:Float = 70.0
    var bufferIndex:NSInteger = 0
    
    
    // Geometry
    var world:World!
    var chunk:Chunk!
    var metalDevice:MTLDevice!
    
    enum WorldType {
        case world
        case selectedBlock
    }
    
    /// Initializes a renderer given a MetalView to render to
    ///
    /// - Parameter view: The view the renderer should render to
    init(metalDevice:MTLDevice, type: WorldType) {
        self.metalDevice = metalDevice
        // create our world
        
        switch type {
        case .selectedBlock:
            world = World.getBlock()
        case .world:
            // this gives us helper methods to create geometry
            world = World.getLandscape()
            // chunk the blocks created by our world
         
        }
        
           chunk = Chunk(blocks: world.blocks, size: world.size)
        
        
        
        
        
        
    }
    
    func prepare() {
        self.makeBuffers()
    }
    
   
    
    
    /// Create our initial vertex, index, and uniform buffers
    private func makeBuffers() {
        vertexBuffer = metalDevice.makeBuffer(bytes: chunk.vertices, length: chunk.vertices.count * MemoryLayout<SVVertex>.stride, options: .cpuCacheModeWriteCombined)
        vertexBuffer.label = "Vertices"
        
        indexBuffer = metalDevice.makeBuffer(bytes: chunk.triangles, length: MemoryLayout<SVIndex>.stride * chunk.triangles.count, options: .cpuCacheModeWriteCombined)
        indexBuffer.label = "Indices"
        
        uniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<SVUniforms>.stride * 3, options: .cpuCacheModeWriteCombined)
        uniformBuffer.label = "Uniforms"
    }
    
    /// Create the resources we need to upload and sample textures
    func addTexturesToQueue(commandQueue:MTLCommandQueue) {
        
        diffuseTexture = TextureLoader.sharedInstance.texture2DWithImageNamed("grass", mipMapped: false, commandQueue: commandQueue)
        
        let samplerDesc = MTLSamplerDescriptor()
        samplerDesc.sAddressMode = .clampToEdge
        samplerDesc.tAddressMode = .clampToEdge
        samplerDesc.minFilter = .nearest
        samplerDesc.magFilter = .nearest
        samplerDesc.mipFilter = .linear
        samplerState = metalDevice.makeSamplerState(descriptor: samplerDesc)
    }

    func draw(timePassed: TimeInterval, viewProjectionMatrix: matrix_float4x4, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, commandBuffer: MTLCommandBuffer, pipeline:MTLRenderPipelineState, depthStencilState: MTLDepthStencilState, completion: @escaping ()->()) {
        

        rotationY += Float(timePassed) * (Float.pi / rotationDampening);
        
        let quat = MatrixUtilities.getQuaternionFromAngles(xx: 0, yy: 1, zz: 0, a: rotationY)
        let rotation = MatrixUtilities.getMatrixFromQuat(q: quat)
        
        
        // get our model matrix representing our model
        let scale = MatrixUtilities.matrixFloat4x4UniformScale(1)
        var modelMatrix = matrix_multiply(scale, rotation)
        modelMatrix = matrix_multiply(modelMatrix, rotation);
        
        // calculate our model view matrix by multiplying the 2 together
        let modelViewProjectionMatrix:matrix_float4x4 = matrix_multiply(viewProjectionMatrix, modelMatrix)
        
        var uniforms:SVUniforms = SVUniforms(modelViewProjectionMatrix: modelViewProjectionMatrix);
        
        let uniformBufferOffset:Int = MemoryLayout<SVUniforms>.stride * bufferIndex
        let contents = uniformBuffer.contents()
        memcpy(contents + uniformBufferOffset, &uniforms, MemoryLayout.size(ofValue: uniforms))
        
        
        let renderPass = renderPassDescriptor
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, index: 1)
        commandEncoder.setFragmentTexture(diffuseTexture, index: 0)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.none)
        
        // draw our geometry
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<SVIndex>.size, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        // do the encoding and present it
        commandEncoder.endEncoding()
        
        
        
    }
    
    
}
