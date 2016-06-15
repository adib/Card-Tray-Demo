//
//  CardCaptureViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardCaptureViewController: UIViewController,CardIOViewDelegate {

//    @IBOutlet weak var cardCaptureView: CardCaptureView!

//    @IBOutlet weak var cardView: CardIOView!

    @IBOutlet weak var cardView: CardIOView!
    
    var cardEntity = CardEntity()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cardView.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        cardCaptureView.performSelector(#selector(cardCaptureView.startSession), withObject: nil, afterDelay: 0)
    }
    
    override func viewWillDisappear(animated: Bool) {
//        cardCaptureView.stopSession()
        super.viewWillDisappear(animated)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: CardIOViewDelegate
    func cardIOView(view: CardIOView,didScanCard cardInfo: CardIOCreditCardInfo?) {
        let cardNumber = cardInfo?.cardNumber
        let cardName = cardInfo?.cardholderName
        // Card.IO doesn't scan the cardholder name: http://stackoverflow.com/a/16844513/199360
        NSLog("Scanned card – number: \(cardNumber) name: \(cardName)")
    }
    

}
