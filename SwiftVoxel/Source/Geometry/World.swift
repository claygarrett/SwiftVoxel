//
//  World.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/23/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import simd

let gridSize:Int = CHUNK_SIZE

class World {

    var blocks:[Block] = []
    var size:(Int, Int, Int)
    
    init(width: Int, height: Int, depth: Int) {
        size = (width, height, depth)
    }
    
    static func getLandscape() -> World {
        let world = World(width: gridSize, height: gridSize, depth: gridSize)
        for _ in 0..<gridSize {
            for _ in 0..<gridSize {
                for _ in 0..<gridSize {
                    let block = Block(visible: true, type: .air)
                    world.blocks.append(block)
                }
            }
        }
        
        for i in 0..<gridSize {
            for k in 0..<gridSize {
                let index = BlockUtilities.get1DIndexFromXYZ(x: i, y: 0, z: k, chunkSize: CHUNK_SIZE)
                let block = world.blocks[index]
                block.type = .grass
            }
        }
        
        let numTrees = 20
        for _ in 0..<numTrees {
            let rangeMin = 5
            let rangeMax = 25
            let randomX = Int.random(in: rangeMin..<rangeMax)
            let randomY = Int.random(in: rangeMin..<rangeMax)
            let randomHeight = Int.random(in: 4..<9)
            
            world.addTreeAtLocation(x: randomX, z: randomY, height: randomHeight)
        }
        
        
        return world
     }
    func addTreeAtLocation(x:Int, z:Int, height:Int) {
        let width = Int(height / 2)
        for j in 0..<height {
            let index = BlockUtilities.get1DIndexFromXYZ(x: x, y: j, z: z, chunkSize: gridSize)
            let block = blocks[index]
            block.type = .trunk
        }
        
        let radius = max(width / 2, 1)
        
        for i in x-radius..<x+radius+1 {
            for j in height..<height+width {
                for k in z-radius..<z+radius+1 {
                    let index = BlockUtilities.get1DIndexFromXYZ(x: i, y: j, z: k, chunkSize: gridSize)
                    let block = blocks[index]
                    block.type = .leaves
                    block.visible = true
                }
            }
        }
        
    }
}
