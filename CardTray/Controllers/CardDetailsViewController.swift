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
