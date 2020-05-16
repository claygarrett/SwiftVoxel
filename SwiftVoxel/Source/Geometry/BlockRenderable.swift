
import UIKit
import simd

class BlockRenderable: Renderable, ControllerHandler {
    
    // Renderable properties
    var modelMatrix: matrix_float4x4!
    var renderShadows: Bool = true
    var diffuseTexture: MTLTexture?
    var samplerState: MTLSamplerState?
    var vertexBuffer:MTLBuffer!
    var indexBuffer:MTLBuffer!
    var uniformBuffer:MTLBuffer!
    var metalDevice:MTLDevice!
    
    // materials
    private var material:Material
    
    // view variables
    var rotationY:Float = 0
    var currentPosition: simd_float3
    let rotationDampening:Float = 10.0
    
    var block:Block
    
    /// Initializes a renderer given a MetalView to render to
    ///
    /// - Parameter view: The view the renderer should render to
    init(metalDevice:MTLDevice) {
        self.metalDevice = metalDevice
        self.material = Material(name: "Block", fragmentFunctionName: "fragment_selected", vertexFunctionName: "vertex_project", device: metalDevice)
        // create our world
        
        block = Block(visible: true, type: .dirt, color: nil)
        currentPosition = [0, 4, 0]
    }
    
    func prepare() {
        self.makeBuffers()
        
    }

    /// Create our initial vertex, index, and uniform buffers
    private func makeBuffers() {
        vertexBuffer = metalDevice.makeBuffer(bytes: block.vertices, length: block.vertices.count * MemoryLayout<SVVertex>.stride, options: .cpuCacheModeWriteCombined)
        vertexBuffer.label = "Vertices"
        
        indexBuffer = metalDevice.makeBuffer(bytes: block.triangles, length: MemoryLayout<SVIndex>.stride * block.triangles.count, options: .cpuCacheModeWriteCombined)
        indexBuffer.label = "Indices"
        
        uniformBuffer = metalDevice.makeBuffer(length: MemoryLayout<SVUniforms>.stride * 3, options: .cpuCacheModeWriteCombined)
        uniformBuffer.label = "Uniforms"
    }
    
    /// Create the resources we need to upload and sample textures
    func addTexturesToQueue(commandQueue:MTLCommandQueue) {
        
        diffuseTexture = TextureLoader.sharedInstance.texture2DWithImageNamed("grass", mipMapped: false, commandQueue: commandQueue)
        
        let samplerDesc = MTLSamplerDescriptor()
        samplerDesc.sAddressMode = .clampToEdge
        samplerDesc.tAddressMode = .clampToEdge
        samplerDesc.minFilter = .nearest
        samplerDesc.magFilter = .nearest
        samplerDesc.mipFilter = .linear
        samplerState = metalDevice.makeSamplerState(descriptor: samplerDesc)
    }
    
    func update(timePassed: TimeInterval) {
        let translation = MatrixUtilities.matrixFloat4x4Translation(t: currentPosition)
//        rotationY += Float(timePassed) * (Float.pi / rotationDampening);
        
        let quat = MatrixUtilities.getQuaternionFromAngles(xx: 0, yy: 1, zz: 0, a: rotationY)
        let rotation = MatrixUtilities.getMatrixFromQuat(q: quat)

        // get our model matrix representing our model
        modelMatrix = matrix_multiply(rotation, translation)
    }
    
    func moveTapped() {
        currentPosition.x = currentPosition.x + 2
        currentPosition.z = currentPosition.z + 2
    }
    
    func getMaterial() -> Material {
        return material
    }
    
}
