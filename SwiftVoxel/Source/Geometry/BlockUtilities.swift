//
//  BlockUtilities.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/23/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit

class BlockUtilities {
    static func get1DIndexFromXYZ(x: Int, y: Int, z: Int, chunkSize: Int) -> Int {
        return x * chunkSize * chunkSize + y * chunkSize + z
    }
}
