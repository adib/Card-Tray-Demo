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

    override func awakeFromNib() {
        super.awakeFromNib()

        let borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)

        let cornerRadius = CGFloat(10)
        let backgroundLayer = backgroundImageView.layer
        backgroundLayer.cornerRadius = cornerRadius
        backgroundLayer.masksToBounds = true
        backgroundLayer.borderColor = borderColor.CGColor
        backgroundLayer.borderWidth = 1

        let shadowLayer = self.layer
        shadowLayer.shadowColor = UIColor.darkGrayColor().CGColor
        shadowLayer.shadowOffset = CGSizeZero
        shadowLayer.shadowOpacity = 0.4
        shadowLayer.shadowRadius = cornerRadius / 2

    }

}
