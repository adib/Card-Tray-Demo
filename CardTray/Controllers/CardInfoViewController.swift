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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
