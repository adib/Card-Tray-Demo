//
//  CardDetailsViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 17/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

class CardDetailsViewController: UIViewController,UITextFieldDelegate, CardEntityHolder {

    @IBOutlet weak var cardholderNameTextField: UITextField!
    
    @IBOutlet weak var cardNumberTextField: UITextField!
    
    var card : CardEntity?
    
    override func viewWillAppear(_ animated: Bool) {
        if let cardEntity = self.card {
            cardholderNameTextField.text = cardEntity.cardholderName
            cardNumberTextField.text = cardEntity.cardNumber
        }
        super.viewWillAppear(animated)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "cardVerify":
                if let cardCtrl = segue.destination as? CardEntityHolder {
                    cardCtrl.card = self.card
                }
            default:
                ()
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier segueIdentifier: String, sender: Any?) -> Bool {
        let showMissingDataAlert = {
            (alertMessage : String,focusTextField:UITextField) in
            let alertCtrl = UIAlertController(title: NSLocalizedString("Missing Data", comment: "Validation alert"), message: alertMessage, preferredStyle: .alert)
            alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default confirm"), style: .default, handler: { (action) in
                focusTextField.becomeFirstResponder()
            }))
            self.present(alertCtrl, animated: true, completion: nil)
        }
        switch segueIdentifier {
        case "cardVerify":
            guard let cardEntity = self.card else {
                return false
            }
            guard let cardholderName = self.cardholderNameTextField.text, !cardholderName.isEmpty else {
                showMissingDataAlert(NSLocalizedString("Please enter cardholder name", comment: "Validation alert"),cardholderNameTextField)
                return false
            }
            guard let cardNumber = self.cardNumberTextField.text, !cardNumber.isEmpty else {
                showMissingDataAlert(NSLocalizedString("Please enter card number", comment: "Validation alert"),cardNumberTextField)
                return false
            }
            
            cardEntity.cardholderName = cardholderName
            cardEntity.cardNumber = cardNumber
            return true
        default:
            ()
        }

        return super.shouldPerformSegue(withIdentifier: segueIdentifier, sender: sender)
    }
    
    @IBAction func retryAddCard(_ unwindSegue:UIStoryboardSegue) {
        // nothing yet. Just placeholder for unwind segue.
    }

    // MARK: - UITextFieldDelegate

}
