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
   
}
