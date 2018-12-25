//
//  Renderable.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/25/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import Foundation
import Metal
import simd

protocol Renderable {
    
    var bufferIndex:NSInteger { get set }
    
    func prepare()
    func draw(timePassed: TimeInterval, viewProjectionMatrix: matrix_float4x4, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable, commandBuffer: MTLCommandBuffer, pipeline:MTLRenderPipelineState, depthStencilState: MTLDepthStencilState, completion: @escaping ()->())
    
}
