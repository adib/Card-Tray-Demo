//
//  CardVerifyViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 16/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

// TODO: force-validate expiry date after leaving focus (clear it if syntax error or the like)

class CardVerifyViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var expirationDatePicker: CardExpirationPickerController!
    
    @IBOutlet weak var securityCodeTextField: UITextField!
    
    @IBOutlet weak var expirationDateTextField: UITextField!
    
    
    var cardEntity : CardEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        expirationDatePicker.viewDidLoad()
        // TODO: populate UI
    }
    
    override func viewWillAppear(animated: Bool) {
        if let cardEntity = self.cardEntity {
            expirationDatePicker.setSelectedMonth(cardEntity.expiryDayOfMonth, year: cardEntity.expiryYear, animated: animated)
            expirationDatePicker.setNeedsWriteText()
            self.securityCodeTextField.text = cardEntity.securityCode
        }
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func performVerify(sender: AnyObject) {
        guard let card = self.cardEntity else {
            return
        }
        
        let showMissingDataAlert = {
            (alertMessage : String,focusTextField:UITextField) in
            let alertCtrl = UIAlertController(title: NSLocalizedString("Missing Data", comment: "Validation alert"), message: alertMessage, preferredStyle: .Alert)
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default confirm"), style: .Default, handler: { (action) in
                focusTextField.becomeFirstResponder()
            }))
            self.presentViewController(alertCtrl, animated: true, completion: nil)
        }
        
        guard let   selectedMonth = expirationDatePicker.selectedMonth,
                    selectedYear = expirationDatePicker.selectedYear else {
            showMissingDataAlert(NSLocalizedString("Incorrect expiration date", comment: "Validation alert"),self.securityCodeTextField)
            return
        }
        
        card.expiryDayOfMonth = selectedMonth
        card.expiryYear = selectedYear
        
        guard let securityCode = self.securityCodeTextField.text where !securityCode.isEmpty else {
            showMissingDataAlert(NSLocalizedString("Missing security code", comment: "Validation alert"),self.securityCodeTextField)
            return
        }
        
        card.securityCode = securityCode
        
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
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        switch textField {
            case expirationDateTextField:
                if let expirationDateText = expirationDateTextField.text {
                    if expirationDatePicker.setSelectedText(expirationDateText, animated: true) {
                        expirationDateTextField.text = expirationDatePicker.selectedText
                    } else {
                        expirationDateTextField.text = nil
                    }
                }
            default: ()
        }
    }

}
