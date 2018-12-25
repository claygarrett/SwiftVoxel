//
//  Chunk.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import simd

let CHUNK_SIZE = 32
private let NUM_SIDES_IN_CUBE = 6

class Chunk: NSObject {
    
    // Enums
    enum TextureQuadrants {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    // Configuration
    let gridSpacing:Float = 2.0
    
    private let color1:simd_float4 = [ 0.968, 0.278, 0.231, 1]
    private let color2:simd_float4 = [ 0.231, 0.545, 0.533, 1]
    private let color3:simd_float4 = [ 0.949, 0.756, 0.305, 1]
    private let color4:simd_float4 = [ 0.968, 0.505, 0.329, 1]
    private let color5:simd_float4 = [ 0.129, 0.862, 0.182, 1]
    private let color6:simd_float4 = [ 0.968, 0.278, 0.733, 1]
    let colors:[simd_float4]
    
    let rightTopBack:simd_float4 = [1.0, 1.0, 1.0, 1.0];
    let rightTopFront:simd_float4 = [1.0, 1.0, -1.0, 1.0];
    let rightBottomBack:simd_float4 = [1.0, -1.0, 1.0, 1.0];
    let rightBottomFront:simd_float4 = [1.0, -1.0, -1.0, 1.0];
    let leftTopBack:simd_float4 = [-1.0, 1.0, 1.0, 1.0];
    let leftTopFront:simd_float4 = [-1.0, 1.0, -1.0, 1.0];
    let leftBottomBack:simd_float4 = [-1.0, -1.0, 1.0, 1.0];
    let leftBottomFront:simd_float4 = [-1.0, -1.0, -1.0, 1.0];
    
    let northNormal:simd_float3 = [0, 0, 1]
    let southNormal:simd_float3 = [0, 0, -1]
    let eastNormal:simd_float3 = [1, 0, 0]
    let westNormal:simd_float3 = [-1, 0, 0]
    let topNormal:simd_float3 = [0, 1, 0]
    let bottomNormal:simd_float3 = [0, -1, 0]
    
    let directionOffsets:[Int] = [0, 0, 1, 1, 0, 0, 0, 0, -1, -1, 0, 0, 0, 1, 0, 0, -1, 0 ]

    // Geometry
    var triangles:[SVIndex] = []
    var vertices:[SVVertex] = []
    var blocks: [Block]
    var numVerts:UInt16 = 0
    
    /// Initializes a chunk with a given set of blocks
    ///
    /// - Parameter blocks: The blocks that should be chunked
    init(blocks:[Block]) {
        self.blocks = blocks
        self.colors = [color1, color2, color3, color4, color5, color6];
        super.init()
        self.recalculate()
    }
    
    /// Rebuilds the geometry for the given chunk
    func recalculate() {
        for i in 0..<CHUNK_SIZE {
            for j in 0..<CHUNK_SIZE {
                for k in 0..<CHUNK_SIZE {
                    let index = BlockUtilities.get1DIndexFromXYZ(x: i, y: j, z: k, chunkSize: CHUNK_SIZE)
                    let block = blocks[index]
                    
                    if(block.type == .air) {
                        continue;
                    }
                    
                    for x in 0..<NUM_SIDES_IN_CUBE {
                        let xOffset = directionOffsets[x*3];
                        let yOffset = directionOffsets[x*3 + 1];
                        let zOffset = directionOffsets[x*3 + 2];
                        
                        let newI = i + xOffset;
                        let newJ = j + yOffset;
                        let newK = k + zOffset;
                        
                        let newIndex = BlockUtilities.get1DIndexFromXYZ(x: newI, y: newJ, z: newK, chunkSize: CHUNK_SIZE)
                        
                        if(newI < 0 || newI >= CHUNK_SIZE || newJ < 0 || newJ >= CHUNK_SIZE || newK < 0 || newK >= CHUNK_SIZE) {
                            addFace(position: [Float(i), Float(j), Float(k), 0], direction: Block.Direction(rawValue: x)!, color: colors[block.type.rawValue])
                            continue
                        }
                        
                        let neighborBlock = blocks[newIndex]
                        
                        if(neighborBlock.type != .air) {
                            continue;
                        }
                        
                        addFace(position: [Float(i), Float(j), Float(k), 0], direction: Block.Direction(rawValue: x)!, color: colors[block.type.rawValue])
                    }
                }
            }
        }
    }
    
    /// Adds a face consisting of two triangls for the given position, direction, and color
    ///
    /// - Parameters:
    ///   - position: The center position of the block who's face we're drawing
    ///   - direction: The direciton of the face we're adding
    ///   - color: The color of the face
    func addFace(position:simd_float4, direction:Block.Direction, color:simd_float4) {
        
       let offset = -Float(CHUNK_SIZE) * Float(gridSpacing) / 2.0 + 1
       let offsetArray:simd_float4 = [offset, offset, offset, 0]
        
        for i in 0..<6 {
            triangles.append(numVerts + UInt16(i))
        }
        
        numVerts += 6
        
        var quadrant:TextureQuadrants;
        switch direction {
        case .north, .east, .south, .west:
            quadrant = .topLeft
        case .top:
            quadrant = .topRight
        case .bottom:
            quadrant = .bottomLeft
        }
        
        let minUvs = getUVMinsForQuadrant(quadrant: quadrant)
        
        let topLeftUV:simd_float2 = [minUvs.x, minUvs.y - 0.49];
        let topRightUV:simd_float2 = [minUvs.x + 0.49, minUvs.y - 0.49];
        let bottomRightUV:simd_float2 = [minUvs.x + 0.49, minUvs.y];
        let bottomLeftUV:simd_float2 = [minUvs.x, minUvs.y];
        
        switch direction {
        case .north:
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [1, 0, 0], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [0, 1, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [0, 0, 1], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [0, 0, 1], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [0, 1, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [1, 0, 0], uv: bottomLeftUV)))
    
        case .east:
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopFront + position * gridSpacing, color: color, normal: eastNormal, barycentricCoord: [1, 0, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomBack + position * gridSpacing, color: color, normal: eastNormal, barycentricCoord: [0, 1, 0], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomFront + position * gridSpacing, color: color, normal: eastNormal, barycentricCoord: [0, 0, 1], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopFront + position * gridSpacing, color: color, normal: eastNormal, barycentricCoord: [1, 0, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopBack + position * gridSpacing, color: color, normal: eastNormal, barycentricCoord: [0, 1, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomBack + position * gridSpacing, color: color, normal: eastNormal, barycentricCoord: [0, 0, 1], uv: bottomRightUV)))
            
        case .south:
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomFront + position * gridSpacing, color: color, normal: southNormal, barycentricCoord: [0, 0, 1], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopFront + position * gridSpacing, color: color, normal: southNormal, barycentricCoord: [0, 1, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomFront + position * gridSpacing, color: color, normal: southNormal, barycentricCoord: [1, 0, 0], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomFront + position * gridSpacing, color: color, normal: southNormal, barycentricCoord: [1, 0, 0], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopFront + position * gridSpacing, color: color, normal: southNormal, barycentricCoord: [0, 1, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopFront + position * gridSpacing, color: color, normal: southNormal, barycentricCoord: [0, 0, 1], uv: topRightUV)))
            
        case .west:
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopFront + position * gridSpacing, color: color, normal: westNormal, barycentricCoord: [1, 0, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomFront + position * gridSpacing, color: color, normal: westNormal, barycentricCoord: [0, 1, 0], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomBack + position * gridSpacing, color: color, normal: westNormal, barycentricCoord: [0, 0, 1], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopFront + position * gridSpacing, color: color, normal: westNormal, barycentricCoord: [1, 0, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomBack + position * gridSpacing, color: color, normal: westNormal, barycentricCoord: [0, 1, 0], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopBack + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [0, 0, 1], uv: topLeftUV)))
            
        case .top:
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopBack + position * gridSpacing, color: color, normal: topNormal, barycentricCoord: [1, 0, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopFront + position * gridSpacing, color: color, normal: topNormal, barycentricCoord: [0, 1, 0], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopFront + position * gridSpacing, color: color, normal: topNormal, barycentricCoord: [0, 0, 1], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftTopBack + position * gridSpacing, color: color, normal: topNormal, barycentricCoord: [1, 0, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopBack + position * gridSpacing, color: color, normal: topNormal, barycentricCoord: [0, 1, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightTopFront + position * gridSpacing, color: color, normal: northNormal, barycentricCoord: [0, 0, 1], uv: bottomRightUV)))
            
        case .bottom:
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomFront + position * gridSpacing, color: color, normal: bottomNormal, barycentricCoord: [1, 0, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomBack + position * gridSpacing, color: color, normal: bottomNormal, barycentricCoord: [0, 1, 0], uv: bottomRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomBack + position * gridSpacing, color: color, normal: bottomNormal, barycentricCoord: [0, 0, 1], uv: bottomLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + leftBottomFront + position * gridSpacing, color: color, normal: bottomNormal, barycentricCoord: [1, 0, 0], uv: topLeftUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomFront + position * gridSpacing, color: color, normal: bottomNormal, barycentricCoord: [0, 1, 0], uv: topRightUV)))
            
            vertices.append(printVertex(SVVertex(position: offsetArray + rightBottomBack + position * gridSpacing, color: color, normal: bottomNormal, barycentricCoord: [0, 0, 1], uv: bottomLeftUV)))
        }
    }
    
    func printVertex(_ vertex:SVVertex)->SVVertex {
        print("Vert: \(vertex.position)")
        return vertex
    }
    
    /// Gets the base UVs for a given texture quadrant
    ///
    /// - Parameter quadrant: The quadrant to get the UVs for
    /// - Returns: The UVs of the given quadrant
    private func getUVMinsForQuadrant(quadrant:TextureQuadrants) ->(x:Float, y:Float) {
        switch quadrant {
        case .topLeft:
            return (x: 0.0, y: 0.5)
        case .topRight:
            return (x: 0.505, y: 0.495)
        case .bottomLeft, .bottomRight:
            return (x:0, y: 0)
        }
    }
 
}
