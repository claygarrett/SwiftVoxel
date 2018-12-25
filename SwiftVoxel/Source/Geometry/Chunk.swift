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
    enum TextureQuadrant {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    // Configuration
    let gridSpacing:Float = 2.0
    
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
    
    
    
    
    let baryX = simd_float3(x: 1, y: 0, z: 0)
    let baryY = simd_float3(x: 0, y: 1, z: 0)
    let baryZ = simd_float3(x: 0, y: 0, z: 1)
    
    let normals: [simd_float3]
    let faceBarycentridCoords:[Block.Direction: [simd_float3]]
    let triangleVertPositions:[Block.Direction: [simd_float4]]
    

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
        
        normals = [northNormal, eastNormal, southNormal, westNormal, topNormal, bottomNormal]
        faceBarycentridCoords = [
                .north: [baryX, baryY, baryZ, baryZ, baryY, baryX],
                .east: [baryX, baryY, baryZ, baryX, baryY, baryZ],
                .south: [baryZ, baryY, baryX, baryX, baryY, baryZ],
                .west: [baryX, baryY, baryZ, baryX, baryY, baryZ],
                .top: [baryX, baryY, baryZ, baryX, baryY, baryZ],
                .bottom: [baryX, baryY, baryZ, baryX, baryY, baryZ]
        ]
        
        triangleVertPositions = [
            .north: [rightBottomBack, leftTopBack, leftBottomBack, rightTopBack, leftTopBack, rightBottomBack],
            .east: [rightTopFront, rightBottomBack, rightBottomFront, rightTopFront, rightTopBack, rightBottomBack],
            .south: [leftBottomFront, leftTopFront, rightBottomFront, rightBottomFront, leftTopFront, rightTopFront],
            .west: [leftTopFront, leftBottomFront, leftBottomBack, leftTopFront, leftBottomBack, leftTopBack],
            .top: [leftTopBack, rightTopFront, leftTopFront, leftTopBack, rightTopBack, rightTopFront],
            .bottom: [leftBottomFront, rightBottomBack, leftBottomBack, leftBottomFront, rightBottomFront, rightBottomBack]
        ]
        
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
                            addFace(position: [Float(i), Float(j), Float(k), 0], direction: Block.Direction(rawValue: x)!)
                            continue
                        }
                        
                        let neighborBlock = blocks[newIndex]
                        
                        if(neighborBlock.type != .air) {
                            continue;
                        }
                        
                        addFace(position: [Float(i), Float(j), Float(k), 0], direction: Block.Direction(rawValue: x)!)
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
    func addFace(position:simd_float4, direction:Block.Direction) {
        
       let offset = -Float(CHUNK_SIZE) * Float(gridSpacing) / 2.0 + 1
       let offsetArray:simd_float4 = [offset, offset, offset, 0]
        
        for i in 0..<NUM_SIDES_IN_CUBE {
            triangles.append(numVerts + UInt16(i))
        }
        
        numVerts += UInt16(NUM_SIDES_IN_CUBE)
        
        let quadrant:TextureQuadrant = getTextureQuadrantForDirection(direction: direction)
        let minUvs = getUVMinsForQuadrant(quadrant: quadrant)
        
        let topLeftUV:simd_float2 = [minUvs.x, minUvs.y - 0.49];
        let topRightUV:simd_float2 = [minUvs.x + 0.49, minUvs.y - 0.49];
        let bottomRightUV:simd_float2 = [minUvs.x + 0.49, minUvs.y];
        let bottomLeftUV:simd_float2 = [minUvs.x, minUvs.y];
        
        let uvs:[Block.Direction: [simd_float2]] = [
            .north: [bottomLeftUV, topRightUV, bottomRightUV, topLeftUV, topRightUV, bottomLeftUV],
            .east: [topLeftUV, bottomRightUV, bottomLeftUV, topLeftUV, topRightUV, bottomRightUV],
            .south: [bottomLeftUV, topLeftUV, bottomRightUV, bottomRightUV, topLeftUV, topRightUV],
            .west: [topRightUV, bottomRightUV, bottomLeftUV, topRightUV, bottomLeftUV, topLeftUV],
            .top: [topLeftUV, bottomRightUV, bottomLeftUV, topLeftUV, topRightUV, bottomRightUV],
            .bottom: [topLeftUV, bottomRightUV, bottomLeftUV, topLeftUV, topRightUV, bottomLeftUV]
        ]
        
        for i in 0..<NUM_SIDES_IN_CUBE {
            let triangleVertPosition = triangleVertPositions[direction]![i]
            let finalPosition = offsetArray + triangleVertPosition + position * gridSpacing
            let vertex = SVVertex(
                position: finalPosition,
                normal: normals[direction.rawValue],
                barycentricCoord: faceBarycentridCoords[direction]![i],
                uv: uvs[direction]![i])
            
            vertices.append(vertex)
        }
    }
    
    /// Gets the base UVs for a given texture quadrant
    ///
    /// - Parameter quadrant: The quadrant to get the UVs for
    /// - Returns: The UVs of the given quadrant
    private func getUVMinsForQuadrant(quadrant:TextureQuadrant) ->(x:Float, y:Float) {
        switch quadrant {
        case .topLeft:
            return (x: 0.0, y: 0.5)
        case .topRight:
            return (x: 0.505, y: 0.495)
        case .bottomLeft, .bottomRight:
            return (x:0, y: 0)
        }
    }
    
    /// Returns which texture quadrant to use for a given face direction
    ///
    /// - Parameter direction: The direction of the face
    /// - Returns: The texture quadrant that the face's texture lives in
    private func getTextureQuadrantForDirection(direction:Block.Direction) -> TextureQuadrant {
        switch direction {
        case .north, .east, .south, .west:
            return .topLeft
        case .top:
            return .topRight
        case .bottom:
            return .bottomLeft
        }
    }
 
}
