//
//  MetalView.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class MetalView: UIView {
    
    var depthTexture:MTLTexture!
    var metalLayer:CAMetalLayer {
        get {
            return (self.layer as! CAMetalLayer)
        }
    }
    
    let passDescriptor = MTLRenderPassDescriptor()
    
    var drawable:CAMetalDrawable!
    
    private var displayLink:CADisplayLink?
    var frameDuration:TimeInterval = 0
    
    var delegate: MetalViewDelegate?
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        metalLayer.device = MTLCreateSystemDefaultDevice()
        
        displayLink?.invalidate()
        
        guard let _ = self.window else {
            displayLink = nil
            return
        }
        
        displayLink = CADisplayLink(target: self, selector: #selector(MetalView.displayLinkDidFire))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .current, forMode: .common)
        
    }
    
    override var frame: CGRect {
        set {
            super.frame = newValue
            var scale = UIScreen.main.scale
            if let window = self.window {
                scale = window.screen.scale
            }
            var drawableSize = self.bounds.size;
            drawableSize.width *= scale;
            drawableSize.height *= scale;
            
            self.metalLayer.drawableSize = drawableSize
            self.initDepthTexture()
        }
        get {
            return super.frame
        }
    }
    
    /// create the depth texture to back this view
    private func initDepthTexture() {
        // we don't need to recreate the texture if it's already there and matches our drawable size
        let drawableSize = self.metalLayer.drawableSize
        
        let drawableWidth = Int(drawableSize.width)
        let drawableHeight = Int(drawableSize.height)
        
        if(depthTexture == nil || depthTexture.width != drawableWidth || depthTexture.height != drawableHeight) {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: drawableWidth, height: drawableHeight, mipmapped: false)
            descriptor.usage = .renderTarget
            descriptor.storageMode = .private
            
            depthTexture = self.metalLayer.device?.makeTexture(descriptor: descriptor)
        }
    }
    
    @objc private func displayLinkDidFire(displayLink: CADisplayLink) {
        frameDuration = displayLink.duration
        drawable = metalLayer.nextDrawable()
        delegate?.viewIsReadyToDraw(view: self)
    }
    
    func currentRenderPassDescriptor(clearDepth: Bool)->MTLRenderPassDescriptor {
        
        let colorAttachement = passDescriptor.colorAttachments[0]
        colorAttachement?.texture = self.drawable.texture
        colorAttachement?.clearColor = MTLClearColor(red: 0, green: 0.8, blue: 1, alpha: 1)
        colorAttachement?.storeAction = .store
        colorAttachement?.loadAction = clearDepth ? .clear : .load
        
        let depthAttachment = passDescriptor.depthAttachment
        depthAttachment?.texture = depthTexture
        depthAttachment?.clearDepth = 1.0
        depthAttachment?.loadAction = clearDepth ? .clear : .load
        depthAttachment?.storeAction = .store
        
        return passDescriptor
    }
    
    
}
