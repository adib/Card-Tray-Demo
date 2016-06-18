//
//  CardInfoViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 18/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardInfoViewController: UIViewController,CardEntityHolder {

    @IBOutlet weak var cardNumberLabel: UILabel!
    
    @IBOutlet weak var deviceNumberLabel: UILabel!
    
    var card : CardEntity? {
        didSet {
            cardNumberLabel.text = card?.obfuscatedCardNumber ?? ""
            deviceNumberLabel.text = UIDevice.currentDevice().identifierForVendor?.UUIDString
        }
    }
}
