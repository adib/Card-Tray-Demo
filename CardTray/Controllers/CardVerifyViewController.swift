//
//  CardVerifyViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 16/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardVerifyViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var expirationDatePicker: CardExpirationPickerController!
    
    @IBOutlet weak var securityCodeTextField: UITextField!
    
    var cardEntity : CardEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        expirationDatePicker.viewDidLoad()
        // TODO: populate UI
    }
    
    @IBAction func performVerify(sender: AnyObject) {
        // TODO: verify the card number
        guard let card = self.cardEntity else {
            return
        }
        
        card.validate({
            (errorOrNil) in
            if let error = errorOrNil {
                let alertCtrl = UIAlertController(title: NSLocalizedString("Error validating card",comment:"Card Error"), message: error.localizedDescription, preferredStyle: .Alert)
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Re-Enter Details", comment: "default retry"), style: .Default, handler: { (action) in
                    self.performSegueWithIdentifier("retryAddCard", sender: sender)
                }))
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "default cancel"), style: .Cancel, handler: { (action) in
                    self.performSegueWithIdentifier("addCardCancel", sender: sender)
                }))
                self.presentViewController(alertCtrl, animated: true, completion: nil)
            } else {
                self.performSegueWithIdentifier("verifyCompleted", sender: sender)
            }
        })
    }
    

}
