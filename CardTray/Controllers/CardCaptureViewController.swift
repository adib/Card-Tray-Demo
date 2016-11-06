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

class CardCaptureViewController: UIViewController,CardIOViewDelegate {

    @IBOutlet weak var cardView: CardIOView!
    
    var cardEntity = CardEntity()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cardView.useCardIOLogo = false
        cardView.hideCardIOLogo = true
        cardView.delegate = self
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "enterCardDetails":
                if let cardCtrl = segue.destination as? CardEntityHolder {
                    cardCtrl.card = self.cardEntity
                }
            default:
                ()
            }
        }
    }
        
    // MARK: CardIOViewDelegate
    
    func cardIOView(_ view: CardIOView,didScanCard cardInfo: CardIOCreditCardInfo?) {
        guard let cardNumber = cardInfo?.cardNumber else {
            return
        }
        
        // Card.IO doesn't scan the cardholder name: http://stackoverflow.com/a/16844513/199360
        cardEntity.cardNumber = cardNumber
        self.performSegue(withIdentifier: "enterCardDetails", sender: view)
    }
}
