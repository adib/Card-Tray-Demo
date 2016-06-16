//
//  CardVerifyViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 16/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardVerifyViewController: UIViewController {

    @IBOutlet var expirationDatePicker: CardExpirationPickerController!
    
    @IBOutlet weak var securityCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        securityCodeTextField.inputView = expirationDatePicker.pickerView
        expirationDatePicker.viewDidLoad()
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
