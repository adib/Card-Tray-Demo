//
//  CardCaptureViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "enterCardDetails":
                if let cardCtrl = segue.destinationViewController as? CardEntityHolder {
                    cardCtrl.card = self.cardEntity
                }
            default:
                ()
            }
        }
    }
        
    // MARK: CardIOViewDelegate
    
    func cardIOView(view: CardIOView,didScanCard cardInfo: CardIOCreditCardInfo?) {
        guard let cardNumber = cardInfo?.cardNumber else {
            return
        }
        
        // Card.IO doesn't scan the cardholder name: http://stackoverflow.com/a/16844513/199360
        cardEntity.cardNumber = cardNumber
        self.performSegueWithIdentifier("enterCardDetails", sender: view)
    }
}
