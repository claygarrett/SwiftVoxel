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
    
    var modelMatrix:matrix_float4x4! { get set }
    var renderShadows:Bool { get set }
    var vertexBuffer:MTLBuffer! { get }
    var indexBuffer:MTLBuffer! { get }
    var uniformBuffer:MTLBuffer! { get }
    var diffuseTexture:MTLTexture? { get }
    var samplerState:MTLSamplerState? { get }
    
    /// Called once to do initial setup such as buffer creation
    func prepare()
    
    
    /// Called per frame to allow renderables to update their model matrices
    ///
    /// - Parameter timePassed: The amount of time passed ssince the last update
    func update(timePassed: TimeInterval)
}
