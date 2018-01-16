//
//  ViewController.swift
//  PurchaseKit
//
//  Created by admin on 2018/1/16.
//  Copyright © 2018年 george. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var purchase:PurchaseKit!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        purchase = PurchaseKit.startPurchase("")
        
    }
}

