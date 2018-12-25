//
//  Renderer.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

typealias SVIndex = UInt16;

struct SVVertex {
    let position:vector_float4
    let color:vector_float4
    let normal:vector_float3
    let barycentricCoord:vector_float3
    let uv:vector_float2
}

struct SVUniforms {
    var modelViewProjectionMatrix:matrix_float4x4
    var modelMatrix:matrix_float4x4
    var modelViewMatrix: matrix_float4x4;
}

import UIKit
import simd
class Renderer:MetalViewDelegate {
    
    struct PerInstanceUniformas {
        let modelMatrix:matrix_float4x4
    }
    
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
    
    // GPU/CPU syncing
    let displaySemaphore:DispatchSemaphore = DispatchSemaphore(value: 3)
    let inFlightBufferCount:NSInteger = 3
    var bufferIndex:NSInteger = 0
    
    // Geometry
    var world:World!
    var chunk:Chunk!
    
    // Views & State
    let metalView:MetalView!
    var timePassed:TimeInterval = 0
    var rotationY:Float = 0
    let rotationDampening:Float = 10.0
    
    /// Initializes a renderer given a MetalView to render to
    ///
    /// - Parameter view: The view the renderer should render to
    init(view: MetalView) {
        self.metalView = view
        self.metalView.delegate = self
       
        // create our world
        // this gives us helper methods to create geometry
        world = World.getLandscape()
        
        // chunk the blocks created by our world
        chunk = Chunk(blocks: world.blocks)

        
        metalDevice = MTLCreateSystemDefaultDevice()!
        self.makeBuffers()
        self.makePipeline()
        self.makeTextureResources()
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
    
    /// Updates the uniform buffer with the latest transformation data
    ///
    /// - Parameters:
    ///   - view: The view we're updating the buffer for. It has the size information we need for our projection matrix
    ///   - duration: The amount of time passed since the last draw
    private func updateUniformsForView(view: MetalView, duration: TimeInterval) {
        timePassed += duration
        
        
        
        rotationY += Float(duration) * (Float.pi / rotationDampening);
        
        let quat = MatrixUtilities.getQuaternionFromAngles(xx: 0, yy: 1, zz: 0, a: rotationY)
        let rotation = MatrixUtilities.getMatrixFromQuat(q: quat)
        
        // get our view matrix representing our camera
        let viewMatrix = MatrixUtilities.matrixFloat4x4Translation(t: [0, 10, -30])
        
        // get our model matrix representing our model
        let scale = MatrixUtilities.matrixFloat4x4UniformScale(1)
        var modelMatrix = matrix_multiply(scale, rotation)
        modelMatrix = matrix_multiply(modelMatrix, rotation);
        
        // calculate our model view matrix by multiplying the 2 together
        let modelViewMatrix:matrix_float4x4 = matrix_multiply(viewMatrix, modelMatrix)
        
        // create our projection matrix
        let drawableSize = view.metalLayer.drawableSize
        let aspect = Float(drawableSize.width / drawableSize.height)
        let fov = Float((2 * Double.pi) / 5)
        let near:Float = 0.1
        let far:Float = 200
        let projectionMatrix:matrix_float4x4 = MatrixUtilities.matrixFloat4x4Perspective(aspect: aspect, fovy: fov, near: near, far: far)
        
        // crearte our uniform buffer
        var uniforms:SVUniforms = SVUniforms(modelViewProjectionMatrix: matrix_multiply(projectionMatrix, modelViewMatrix), modelMatrix: modelMatrix, modelViewMatrix: modelViewMatrix);
        
        let uniformBufferOffset:Int = MemoryLayout<SVUniforms>.stride * bufferIndex
        let contents = uniformBuffer.contents()
        memcpy(contents + uniformBufferOffset, &uniforms, MemoryLayout.size(ofValue: uniforms))
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
    
    /// Delegate method for MetalView, called when the view is ready to be drawn to
    ///
    /// - Parameter view: The metal view that's ready for drawing
    func viewIsReadyToDraw(view: MetalView) {
        // wait until our resources are free
        let _  = displaySemaphore.wait(timeout: .distantFuture)
        
        self.updateUniformsForView(view: view, duration: view.frameDuration)
        
        // do the heavy lifting of creating a command buffer and command encoder
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderPass = view.currentRenderPassDescriptor()
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        commandEncoder.setRenderPipelineState(pipeline)
        let uniformBufferOffset = MemoryLayout<SVUniforms>.stride * bufferIndex
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
        commandBuffer.present(view.drawable)
        
        // find out when our work is completed to signal the semaphore is free
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.displaySemaphore.signal()
            self.bufferIndex = (self.bufferIndex + 1) % self.inFlightBufferCount
        }
        
        // finalize
        commandBuffer.commit()
    }
}
