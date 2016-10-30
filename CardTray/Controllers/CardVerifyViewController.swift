//
//  CardVerifyViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 16/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

class CardVerifyViewController: UIViewController,UITextFieldDelegate,CardEntityHolder {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var expirationDatePicker: CardExpirationPickerController!
    
    @IBOutlet weak var securityCodeTextField: UITextField!
    
    @IBOutlet weak var expirationDateTextField: UITextField!
    
    
    var card : CardEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        expirationDatePicker.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let cardEntity = self.card {
            expirationDatePicker.setSelectedMonth(cardEntity.expiryDayOfMonth, year: cardEntity.expiryYear, animated: animated)
            expirationDatePicker.setNeedsWriteText()
            self.securityCodeTextField.text = cardEntity.securityCode
        }
        super.viewWillAppear(animated)
    }
    
    
    @IBAction func performVerify(_ sender: AnyObject) {
        guard let card = self.card else {
            return
        }
        
        let showMissingDataAlert = {
            (alertMessage : String,focusTextField:UITextField) in
            let alertCtrl = UIAlertController(title: NSLocalizedString("Missing Data", comment: "Validation alert"), message: alertMessage, preferredStyle: .alert)
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default confirm"), style: .default, handler: { (action) in
                focusTextField.becomeFirstResponder()
            }))
            self.present(alertCtrl, animated: true, completion: nil)
        }
        
        guard let   selectedMonth = expirationDatePicker.selectedMonth,
                    let selectedYear = expirationDatePicker.selectedYear else {
            showMissingDataAlert(NSLocalizedString("Incorrect expiration date", comment: "Validation alert"),self.securityCodeTextField)
            return
        }
        
        card.expiryDayOfMonth = selectedMonth
        card.expiryYear = selectedYear
        
        guard let securityCode = self.securityCodeTextField.text, !securityCode.isEmpty else {
            showMissingDataAlert(NSLocalizedString("Missing security code", comment: "Validation alert"),self.securityCodeTextField)
            return
        }
        
        card.securityCode = securityCode
        
        card.validate({
            (errorOrNil) in
            if let error = errorOrNil {
                let alertCtrl = UIAlertController(title: NSLocalizedString("Error validating card",comment:"Card Error"), message: error.localizedDescription, preferredStyle: .alert)
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Re-Enter Details", comment: "default retry"), style: .default, handler: { (action) in
                    self.performSegue(withIdentifier: "retryAddCard", sender: sender)
                }))
                alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "default cancel"), style: .cancel, handler: { (action) in
                    self.performSegue(withIdentifier: "addCardCancel", sender: sender)
                }))
                self.present(alertCtrl, animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "verifyCompleted", sender: sender)
            }
        })
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
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
