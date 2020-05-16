
import UIKit

class BlockUtilities {
    static func get1DIndexFromXYZ(x: Int, y: Int, z: Int, chunkSize: Vector3) -> Int {
        return x * chunkSize.x * chunkSize.x + y * chunkSize.y + z
    }
}
