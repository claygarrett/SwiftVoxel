//
//  Renderer.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

typealias SVIndex = UInt32;

struct SVVertex {
    let position:vector_float4
    let color:vector_float4
    let normal:vector_float3
    let barycentricCoord:vector_float3
    let highlighted:Bool
    let uv:vector_float2
    
    init(position:vector_float4, normal: vector_float3, barycentricCoord:vector_float3, uv:vector_float2) {
        self.position = position
        self.normal = normal
        self.barycentricCoord = barycentricCoord
        self.uv = uv
        self.color = vector_float4(0, 0, 0, 1);
        self.highlighted = true
    }
}

struct SVUniforms {
    var modelViewProjectionMatrix:matrix_float4x4
}

import UIKit
import simd
class Renderer:MetalViewDelegate {
    
   
    var metalDevice:MTLDevice!
    var renderables:[Renderable] = []
    
    var projectionMatrix:matrix_float4x4!
    
    var commandQueue:MTLCommandQueue!
    var pipeline:MTLRenderPipelineState!
    var depthStencilState:MTLDepthStencilState!
    
    let displaySemaphore:DispatchSemaphore = DispatchSemaphore(value: 3)
    
    var bufferIndex:NSInteger = 0
    let inFlightBufferCount:NSInteger = 3
    
    // Views & State
    let metalView:MetalView!
    var timePassed:TimeInterval = 0
    
    
    /// Initializes a renderer given a MetalView to render to
    ///
    /// - Parameter view: The view the renderer should render to
    init(view: MetalView) {
        self.metalView = view
        self.metalView.delegate = self
        metalDevice = MTLCreateSystemDefaultDevice()!
        
        self.makePipeline()
        
        
        let chunkRenderable = ChunkRenderable(metalDevice: metalDevice, type: .world)
        chunkRenderable.prepare()
        
        chunkRenderable.addTexturesToQueue(commandQueue: commandQueue)
        
        metalDevice = MTLCreateSystemDefaultDevice()!
        
        let chunkRenderable2 = ChunkRenderable(metalDevice: metalDevice, type: .selectedBlock)
        chunkRenderable2.prepare()
        
        chunkRenderable2.addTexturesToQueue(commandQueue: commandQueue)
        
        renderables.append(chunkRenderable)
        renderables.append(chunkRenderable2)
        
        
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
        
        // create our pipmeeline state from our descriptor
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
    
    private func createProjectionMatrix(size:CGSize) {
        // create our projection matrix
        let aspect = Float(size.width / size.height)
        let fov = Float((2 * Double.pi) / 5)
        let near:Float = 0.1
        let far:Float = 1000
        projectionMatrix = MatrixUtilities.matrixFloat4x4Perspective(aspect: aspect, fovy: fov, near: near, far: far)
    }
  
    
    /// Updates the uniform buffer with the latest transformation data
    ///
    /// - Parameters:
    ///   - view: The view we're updating the buffer for. It has the size information we need for our projection matrix
    ///   - duration: The amount of time passed since the last draw
    private func updateUniformsForView(view: MetalView, duration: TimeInterval) {
        
        let _  = displaySemaphore.wait(timeout: .distantFuture)
        
        if(projectionMatrix == nil) {
            createProjectionMatrix(size:  view.metalLayer.drawableSize)
        }
        
        // get our view matrix representing our camera
        let viewMatrix = MatrixUtilities.matrixFloat4x4Translation(t: [0, 80, -120])
        
        
        
        let viewProjectionMatrix = matrix_multiply(projectionMatrix, viewMatrix)
        
        var i = 0
        
        // do the heavy lifting of creating a command buffer and command encoder
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        
        
        for var renderable in renderables {
            renderable.bufferIndex = self.bufferIndex
            
       let passDescriptor = view.currentRenderPassDescriptor(clearDepth: i == 0)
            
            renderable.draw(timePassed: duration, viewProjectionMatrix: viewProjectionMatrix,  renderPassDescriptor: passDescriptor, drawable: view.drawable, commandBuffer: commandBuffer, pipeline: pipeline, depthStencilState: depthStencilState, completion: {
               
            })
            
            i += 1
            
           
        }
        
        commandBuffer.present(view.drawable)
        
        // find out when our work is completed to signal the semaphore is free
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.displaySemaphore.signal()
            self.bufferIndex = (self.bufferIndex + 1) % self.inFlightBufferCount
        }
        
        // finalize
        commandBuffer.commit()
        
    }
      
    /// Delegate method for MetalView, called when the view is ready to be drawn to
    ///
    /// - Parameter view: The metal view that's ready for drawing
    func viewIsReadyToDraw(view: MetalView) {
        // wait until our resources are free
        
        
        self.updateUniformsForView(view: view, duration: view.frameDuration)
        
        
        
    }
}
