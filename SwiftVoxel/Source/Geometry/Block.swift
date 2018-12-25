//
//  Block.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import simd

class Block {
    enum BlockType: Int, CaseIterable {
        case grass
        case dirt
        case trunk
        case leaves
        case cloud
        case air
    }
    
    enum Direction: Int, CaseIterable {
        case north
        case east
        case south
        case west
        case top
        case bottom
    }
    
    // Enums
    enum TextureQuadrant {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    var visible: Bool
    var type: BlockType
    
    init(visible: Bool, type: BlockType) {
        self.visible = visible
        self.type = type
    }
    
    /// Returns the x/y uv positions of the slot this block's texture resides in
    ///
    /// - Returns: The uv position
    func getUVCorners(forDirection direction: Direction) -> (topLeft: simd_float2, topRight: simd_float2, bottomRight: simd_float2, bottomLeft: simd_float2) {
        // our texture is a square
        // so it is a grid of texture slots where m x m = num types
        let index = self.type.rawValue
        let numSlotsInRow = Int(sqrt(Double(Block.BlockType.allCases.count)))
        let slotWidth:Float = 1.0 / Float(numSlotsInRow)
        let quadrantWidth = Float(slotWidth) / 2.0
        let x = slotWidth * Float(index % numSlotsInRow)
        let y = slotWidth * Float(index / numSlotsInRow) + slotWidth
        
        
        let quadrant = getTextureQuadrantForDirection(direction: direction)
        
        var topLeftUV:simd_float2;
        var topRightUV:simd_float2;
        var bottomRightUV:simd_float2;
        var bottomLeftUV:simd_float2;
        
        switch quadrant {
        case .topLeft:
            topLeftUV = [x, y - quadrantWidth * 2];
            topRightUV = [x + quadrantWidth, y - quadrantWidth * 2];
            bottomRightUV = [x + quadrantWidth, y - quadrantWidth];
            bottomLeftUV = [x, y - quadrantWidth];
        case .topRight:
            topLeftUV = [x + quadrantWidth, y - quadrantWidth * 2];
            topRightUV = [x + quadrantWidth * 2, y - quadrantWidth * 2];
            bottomRightUV = [x + quadrantWidth * 2, y - quadrantWidth];
            bottomLeftUV = [x + quadrantWidth, y - quadrantWidth];
        case .bottomLeft, .bottomRight:
            topLeftUV = [x, y - quadrantWidth];
            topRightUV = [x + quadrantWidth, y - quadrantWidth];
            bottomRightUV = [x + quadrantWidth, y];
            bottomLeftUV = [x, y];
        }
        
        
        let returnVal = (topLeft: topLeftUV, topRight: topRightUV, bottomRight: bottomRightUV, bottomLeft: bottomLeftUV)
        print("type: \(self.type) \(returnVal)")
        return returnVal
        
        
    }
    
    /// Returns which texture quadrant to use for a given face direction
    ///
    /// - Parameter direction: The direction of the face
    /// - Returns: The texture quadrant that the face's texture lives in
    private func getTextureQuadrantForDirection(direction:Direction) -> TextureQuadrant {
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
