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

class CardItemView: UIView,CardEntityHolder {

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var issuerLogoImageView: UIImageView!
    @IBOutlet weak var networkLogoImageView: UIImageView!
    
    @IBOutlet weak var cardNumberLabel: UILabel!
    
    var card : CardEntity? {
        didSet {
            if let card = card {
                cardNumberLabel.text = card.obfuscatedCardNumber ?? "????"

                let bundle = Bundle(for: type(of: self))
                switch(card.networkType) {
                case .Visa:
                    networkLogoImageView.image = UIImage(named: "logo_visa", in: bundle, compatibleWith: nil)
                    issuerLogoImageView.image = UIImage(named: "logo_raybank", in: bundle, compatibleWith: nil)
                    backgroundImageView.image = UIImage(named: "cardback_1", in: bundle, compatibleWith: nil)
                    backgroundImageView.backgroundColor = UIColor(red: 0.82, green: 0.33, blue: 0.10, alpha: 1)
                case .MasterCard:
                    // TODO: use other images for the background and issuer
                    networkLogoImageView.image = UIImage(named: "logo_mastercard", in: bundle, compatibleWith: nil)
                    issuerLogoImageView.image = UIImage(named: "logo_barleys", in: bundle, compatibleWith: nil)
                    backgroundImageView.image = UIImage(named: "cardback_2", in: bundle, compatibleWith: nil)
                    backgroundImageView.backgroundColor = UIColor(red: 0.18, green: 0.51, blue: 0.72, alpha: 1)
                default:
                    backgroundImageView.image = nil
                    networkLogoImageView.image = nil
                    backgroundImageView.image = nil
                    backgroundImageView.backgroundColor = UIColor(red: 0.74, green: 0.76, blue: 0.78, alpha: 1)
                }
            } else {
                backgroundImageView.backgroundColor = UIColor.darkGray
                cardNumberLabel.text = ""
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderColor = UIColor.white.withAlphaComponent(0.4)

        let cornerRadius = CGFloat(10)
        let backgroundLayer = backgroundImageView.layer
        backgroundLayer.cornerRadius = cornerRadius
        backgroundLayer.masksToBounds = true
        backgroundLayer.borderColor = borderColor.cgColor
        backgroundLayer.borderWidth = 1

        let shadowLayer = self.layer
        shadowLayer.shadowColor = UIColor.black.cgColor
        shadowLayer.shadowOffset = CGSize.zero
        shadowLayer.shadowOpacity = 0.3
        shadowLayer.shadowRadius = cornerRadius / 2
    }
}
