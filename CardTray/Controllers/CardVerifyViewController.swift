// Card Tray Demo
// Copyright (C) 2016  Sasmito Adibowo – http://cutecoder.org

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
