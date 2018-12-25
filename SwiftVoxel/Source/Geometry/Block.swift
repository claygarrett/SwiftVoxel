//
//  Block.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit

class Block {
    enum BlockType: Int {
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
}
