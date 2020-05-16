
import UIKit

class TextureLoader {

    static let sharedInstance = TextureLoader()
    
    /// Creates a texture from a given image.
    ///
    /// - Parameters:
    ///   - imageName: The name of the image in the main bundle to load
    ///   - mipMapped: Whether this texture should be mipmapped
    ///   - commandQueue: The command queue on which this texture should be loaded
    /// - Returns: The created Metal texture
    func texture2DWithImageNamed(_ imageName: String, mipMapped: Bool, commandQueue: MTLCommandQueue) -> MTLTexture? {
        let image = UIImage(named: imageName)
        
        // escape early if we can't find the image
        guard let i = image else {
            return nil
        }
        
        // convert points to pixels
        let imageSize = CGSize(width: i.size.width * i.scale, height: i.size.height * i.scale)
        
        // create a descriptor with the necessary properties
        let bytesPerPixel = 4
        let bytesPerRow = CGFloat(bytesPerPixel) * imageSize.width
        let imageData = self.dataForImage(image: i)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(imageSize.width), height: Int(imageSize.height), mipmapped: mipMapped)
        textureDescriptor.usage = .shaderRead
        
        // make the texture with our descriptor
        let device = commandQueue.device
        let texture = device.makeTexture(descriptor: textureDescriptor)
        
        // return if it failed
        guard let t = texture else {
            return nil
        }
        
        t.label = imageName
        
        // copy the texture from our image
        let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
        texture?.replace(region: region, mipmapLevel: 0, withBytes: imageData, bytesPerRow: Int(bytesPerRow))
        free(imageData)
        
        // generate our mips if needed
        if(mipMapped) {
            self.generateMipmapsForTexture(t, onQueue: commandQueue)
        }
        
        return t
    }
    
    /// Generates mipmaps of a given texture
    ///
    /// - Parameters:
    ///   - texture: The texture to generate mips of
    ///   - queue: The command queue on which to generate them
    private func generateMipmapsForTexture(_ texture: MTLTexture, onQueue queue:MTLCommandQueue){
        let commandBuffer = queue.makeCommandBuffer()
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.generateMipmaps(for: texture)
        blitEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }
    
    /// Returns the raw data for a given image
    ///
    /// - Parameter image: The image to get the data for
    /// - Returns: The data of the image
    private func dataForImage(image:UIImage)->UnsafeMutableRawPointer {
        
        // create the properties necessary to create the CGContext
        let imageRef = image.cgImage!
        let width = imageRef.width
        let height = imageRef.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData:UnsafeMutableRawPointer = calloc(height * width * 4, MemoryLayout<UInt8>.stride)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue   )

        
        // do the dirty work
        let imageRect = CGRect(x: 0, y: 0, width: width, height: height)
        context?.draw(imageRef, in: imageRect)
        return rawData
    }
}
