//
//  BlockUtilities.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/23/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit

class BlockUtilities {
    static func get1DIndexFromXYZ(x: Int, y: Int, z: Int, chunkSize: Vector3) -> Int {
        return x * chunkSize.x * chunkSize.x + y * chunkSize.y + z
    }
}
