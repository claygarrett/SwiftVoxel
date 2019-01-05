//
//  ViewModl.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/25/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//


import RxSwift
import RxCocoa
import simd



class ViewModel:NSObject {

    var position:Variable<String?>
    var renderer:Renderer
    
    init(metalView: MetalView) {
        
        position = Variable("[0, 0, 0]")
        renderer = Renderer(view: metalView)
        
        super.init()
    }
    
    func moveLeft() {
        
    }
    
    func moveRight() {
        renderer.moveBox()
        position.value = "Tapped"
    }
    

    
    func endedPan() {
        renderer.endPan()
    }
    
    func panned(x: CGFloat, y: CGFloat) {
        renderer.pan(x: Float(x), y: Float(y))
    }
    
    func endZoom() {
        renderer.endZoom()
    }
    
    func zoomed(amount: CGFloat) {
        renderer.zoom(amount: Float(1.0 - amount))
    }
   
}
