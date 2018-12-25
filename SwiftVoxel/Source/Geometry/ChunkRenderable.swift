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
    let displaySemaphore:DispatchSemaphore = DispatchSemaphore(value: 3)
    
    // Core Metal components
    var metalDevice:MTLDevice!
    var vertexBuffer:MTLBuffer!
    var indexBuffer:MTLBuffer!
    var uniformBuffer:MTLBuffer!
    var commandQueue:MTLCommandQueue!
    var pipeline:MTLRenderPipelineState!
    var depthStencilState:MTLDepthStencilState!
    var commandEncoder:MTLRenderCommandEncoder!
    var diffuseTexture:MTLTexture!
    var samplerState:MTLSamplerState!
    
    var rotationY:Float = 0
    let rotationDampening:Float = 10.0
    var bufferIndex:NSInteger = 0
    let inFlightBufferCount:NSInteger = 3
    
    // Geometry
    var world:World!
    var chunk:Chunk!
    
    /// Initializes a renderer given a MetalView to render to
    ///
    /// - Parameter view: The view the renderer should render to
    init() {
        
        // create our world
        // this gives us helper methods to create geometry
        world = World.getLandscape()
        
        // chunk the blocks created by our world
        chunk = Chunk(blocks: world.blocks)
        
        
        metalDevice = MTLCreateSystemDefaultDevice()!
        
    }
    
    func prepare() {
        self.makeBuffers()
        self.makePipeline()
        self.makeTextureResources()
    }
    
    
    /// Create the pipeline state to be used in rendering
    private func makePipeline() {
        // get a new command queue from the device.
        // a command queue keeps a list of command buffers to be executed
        commandQueue = metalDevice.makeCommandQueue()
        
        // create our frag and vert functions from the files in our library
        let library:MTLLibrary = metalDevice.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "vertex_project")
        let fragmentFunc = library.makeFunction(name: "fragment_flatcolor")
        
        // tie it all together with our pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // create our pipeline state from our descriptor
        do {
            try pipeline = metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch  {
            print("Error: \(error)")
        }
        
        // set up our depth stencil
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = metalDevice.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    
    /// Create our initial vertex, index, and uniform buffers
    private func makeBuffers() {
        vertexBuffer = metalDevice.makeBuffer(bytes: chunk.vertices, length: chunk.vertices.count * MemoryLayout<SVVertex>.stride, options: .cpuCacheModeWriteCombined)
        vertexBuffer.label = "Vertices"
        
        indexBuffer = metalDevice.makeBuffer(bytes: chunk.triangles, length: MemoryLayout<SVIndex>.stride * chunk.triangles.count, options: .cpuCacheModeWriteCombined)
        indexBuffer.label = "Indices"
        
        uniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<SVUniforms>.stride * inFlightBufferCount, options: .cpuCacheModeWriteCombined)
        uniformBuffer.label = "Uniforms"
    }
    
    /// Create the resources we need to upload and sample textures
    private func makeTextureResources() {
        
        diffuseTexture = TextureLoader.sharedInstance.texture2DWithImageNamed("grass", mipMapped: false, commandQueue: commandQueue)
        
        let samplerDesc = MTLSamplerDescriptor()
        samplerDesc.sAddressMode = .clampToEdge
        samplerDesc.tAddressMode = .clampToEdge
        samplerDesc.minFilter = .nearest
        samplerDesc.magFilter = .nearest
        samplerDesc.mipFilter = .linear
        samplerState = metalDevice.makeSamplerState(descriptor: samplerDesc)
    }

    func draw(timePassed: TimeInterval, viewProjectionMatrix: matrix_float4x4, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
        let _  = displaySemaphore.wait(timeout: .distantFuture)

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
        
        // do the heavy lifting of creating a command buffer and command encoder
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderPass = renderPassDescriptor
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        commandEncoder.setRenderPipelineState(pipeline)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: uniformBufferOffset, index: 1)
        commandEncoder.setFragmentTexture(diffuseTexture, index: 0)
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        // draw our geometry
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<SVIndex>.size, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        
        // do the encoding and present it
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        
        // find out when our work is completed to signal the semaphore is free
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.displaySemaphore.signal()
            self.bufferIndex = (self.bufferIndex + 1) % self.inFlightBufferCount
        }
        
        // finalize
        commandBuffer.commit()
        
        
    }
    
    
}
