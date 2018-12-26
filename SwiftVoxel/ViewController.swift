//
//  ViewController.swift
//  SwiftVoxel
//
//  Created by Clay Garrett on 12/22/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {

    var renderer:Renderer!

    @IBOutlet weak var metalView: MetalView!
    @IBOutlet weak var moveButton: UIButton!
    @IBOutlet weak var positionLabel: UILabel!
    
    var viewModel:ViewModel!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ViewModel(metalView: metalView)
        bindViewModel()
    }
    
    func bindViewModel() {
        // tie our label to the position variable
        viewModel.position.asObservable().subscribe(onNext: { (value) in
            self.positionLabel.text = value
        }).disposed(by: disposeBag)
        
        // hook up to move button tap events
        moveButton.rx.tap.bind {
            self.viewModel.moveRight()
        }.disposed(by: disposeBag)
    }
}

