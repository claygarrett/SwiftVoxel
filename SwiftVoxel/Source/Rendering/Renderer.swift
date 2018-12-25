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
        let chunkRenderable = ChunkRenderable()
        chunkRenderable.prepare()
        renderables.append(chunkRenderable)
    }
    
    private func createProjectionMatrix(size:CGSize) {
        // create our projection matrix
        let aspect = Float(size.width / size.height)
        let fov = Float((2 * Double.pi) / 5)
        let near:Float = 0.1
        let far:Float = 200
        projectionMatrix = MatrixUtilities.matrixFloat4x4Perspective(aspect: aspect, fovy: fov, near: near, far: far)
    }
  
    
    /// Updates the uniform buffer with the latest transformation data
    ///
    /// - Parameters:
    ///   - view: The view we're updating the buffer for. It has the size information we need for our projection matrix
    ///   - duration: The amount of time passed since the last draw
    private func updateUniformsForView(view: MetalView, duration: TimeInterval) {
        
        if(projectionMatrix == nil) {
            createProjectionMatrix(size:  view.metalLayer.drawableSize)
        }
        
        // get our view matrix representing our camera
        let viewMatrix = MatrixUtilities.matrixFloat4x4Translation(t: [0, 10, -80])
        
        
        
        let viewProjectionMatrix = matrix_multiply(projectionMatrix, viewMatrix)
        
        for renderable in renderables {
            renderable.draw(timePassed: duration, viewProjectionMatrix: viewProjectionMatrix,  renderPassDescriptor: view.currentRenderPassDescriptor(), drawable: view.drawable)
        }
    }
      
    /// Delegate method for MetalView, called when the view is ready to be drawn to
    ///
    /// - Parameter view: The metal view that's ready for drawing
    func viewIsReadyToDraw(view: MetalView) {
        // wait until our resources are free
        
        
        self.updateUniformsForView(view: view, duration: view.frameDuration)
        
        
        
    }
}
