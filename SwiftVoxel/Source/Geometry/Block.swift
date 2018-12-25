//
//  Block.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit

class Block {
    enum BlockType: Int, CaseIterable {
        case air
        case grass
        case dirt
        case trunk
        case leaves
        case cloud
    }
    
    enum Direction: Int, CaseIterable {
        case north
        case east
        case south
        case west
        case top
        case bottom
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
    func getTextureSlotIndex() -> (Float, Float) {
        // our texture is a square
        // so it is a grid of texture slots where m x m = num types
        let index = self.type.rawValue
        let width = Int(sqrt(Double(Block.BlockType.allCases.count)))
        let x = Float((1/width) * (index % width))
        let y = Float((1/width) * (index / width)) + 1.0/Float(width)
        return (x, y)
    }
    
}
