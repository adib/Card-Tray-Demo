//
//  CardDetailsViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 17/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardDetailsViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var cardholderNameTextField: UITextField!
    
    @IBOutlet weak var cardNumberTextField: UITextField!
    
    var card : CardEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        if let cardEntity = self.card {
            cardholderNameTextField.text = cardEntity.cardholderName
            cardNumberTextField.text = cardEntity.cardNumber
        }
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "cardVerify":
                if let cardCtrl = segue.destinationViewController as? CardVerifyViewController {
                    cardCtrl.card = self.card
                }
            default:
                ()
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(segueIdentifier: String, sender: AnyObject?) -> Bool {
        let showMissingDataAlert = {
            (alertMessage : String,focusTextField:UITextField) in
            let alertCtrl = UIAlertController(title: NSLocalizedString("Missing Data", comment: "Validation alert"), message: alertMessage, preferredStyle: .Alert)
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default confirm"), style: .Default, handler: { (action) in
                focusTextField.becomeFirstResponder()
            }))
            self.presentViewController(alertCtrl, animated: true, completion: nil)
        }
        switch segueIdentifier {
        case "cardVerify":
            guard let cardEntity = self.card else {
                return false
            }
            guard let cardholderName = self.cardholderNameTextField.text where !cardholderName.isEmpty else {
                showMissingDataAlert(NSLocalizedString("Please enter cardholder name", comment: "Validation alert"),cardholderNameTextField)
                return false
            }
            guard let cardNumber = self.cardNumberTextField.text where !cardNumber.isEmpty else {
                showMissingDataAlert(NSLocalizedString("Please enter card number", comment: "Validation alert"),cardNumberTextField)
                return false
            }
            
            cardEntity.cardholderName = cardholderName
            cardEntity.cardNumber = cardNumber
            return true
        default:
            ()
        }

        return super.shouldPerformSegueWithIdentifier(segueIdentifier, sender: sender)
    }
    
    // MARK: - UITextFieldDelegate

}
