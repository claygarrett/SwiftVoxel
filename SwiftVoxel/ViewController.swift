//
//  ViewController.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var renderer:Renderer!

    @IBOutlet weak var metalView: MetalView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        renderer = Renderer(view: self.metalView)
        
        
    }


}

