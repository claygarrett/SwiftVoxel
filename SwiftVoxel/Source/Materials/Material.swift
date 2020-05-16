
import UIKit

/// Defines all aspects of the visual appearance of a renderable
/// as well as other things that affect rendering (such as a vertex function)
class Material: NSObject {
    private var vertexFunctionName:String
    private var fragmentFunctionName:String
    private let vertexFunction:MTLFunction
    private let fragmentFunction:MTLFunction
    private let library:MTLLibrary
    let name:String
    
    init(name: String, fragmentFunctionName: String, vertexFunctionName: String, device: MTLDevice) {
        self.name = name
        self.vertexFunctionName = vertexFunctionName
        self.fragmentFunctionName = fragmentFunctionName
        library = device.makeDefaultLibrary()!
        vertexFunction = library.makeFunction(name: vertexFunctionName)!
        fragmentFunction = library.makeFunction(name: fragmentFunctionName)!
        super.init()
    }
    
    /// Returns the fragment function associated with this material.
    ///
    /// - Returns: The fragment function
    func getFragmentFunction() -> MTLFunction {
        return fragmentFunction
    }
    
    /// Returns the vertex function associated with this material.
    ///
    /// - Returns: The vertex function
    func getVertexFunction() -> MTLFunction {
        return vertexFunction
    }
}
