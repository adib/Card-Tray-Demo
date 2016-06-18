//
//  CardItemView.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardItemView: UIView {

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var issuerLogoImageView: UIImageView!
    @IBOutlet weak var networkLogoImageView: UIImageView!
    
    @IBOutlet weak var cardNumberLabel: UILabel!
    
    var card : CardEntity? {
        didSet {
            if let card = card {
                if let cardNumber = card.cardNumber {
                    let displayNumbers = String(cardNumber.characters.suffix(4))
                    cardNumberLabel.text = "••••\u{2007}\(displayNumbers)"
                } else {
                    cardNumberLabel.text = "????"
                }

                let bundle = NSBundle(forClass: self.dynamicType)
                switch(card.networkType) {
                case .Visa:
                    networkLogoImageView.image = UIImage(named: "logo_visa", inBundle: bundle, compatibleWithTraitCollection: nil)
                    issuerLogoImageView.image = UIImage(named: "logo_raybank", inBundle: bundle, compatibleWithTraitCollection: nil)
                    backgroundImageView.image = UIImage(named: "cardback_1", inBundle: bundle, compatibleWithTraitCollection: nil)
                    backgroundImageView.backgroundColor = UIColor(red: 0.82, green: 0.33, blue: 0.10, alpha: 1)
                case .MasterCard:
                    // TODO: use other images for the background and issuer
                    networkLogoImageView.image = UIImage(named: "logo_mastercard", inBundle: bundle, compatibleWithTraitCollection: nil)
                    issuerLogoImageView.image = UIImage(named: "logo_raybank", inBundle: bundle, compatibleWithTraitCollection: nil)
                    backgroundImageView.image = UIImage(named: "cardback_1", inBundle: bundle, compatibleWithTraitCollection: nil)
                    backgroundImageView.backgroundColor = UIColor(red: 0.18, green: 0.51, blue: 0.72, alpha: 1)
                default:
                    backgroundImageView.image = nil
                    networkLogoImageView.image = nil
                    backgroundImageView.image = nil
                    backgroundImageView.backgroundColor = UIColor(red: 0.74, green: 0.76, blue: 0.78, alpha: 1)
                }
            } else {
                backgroundImageView.backgroundColor = UIColor.darkGrayColor()
                cardNumberLabel.text = ""
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)

        let cornerRadius = CGFloat(10)
        let backgroundLayer = backgroundImageView.layer
        backgroundLayer.cornerRadius = cornerRadius
        backgroundLayer.masksToBounds = true
        backgroundLayer.borderColor = borderColor.CGColor
        backgroundLayer.borderWidth = 1

        let shadowLayer = self.layer
        shadowLayer.shadowColor = UIColor.blackColor().CGColor
        shadowLayer.shadowOffset = CGSizeZero
        shadowLayer.shadowOpacity = 0.3
        shadowLayer.shadowRadius = cornerRadius / 2

    }

}
