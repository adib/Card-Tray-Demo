//
//  CardListViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardListViewController: UIViewController, CardListViewDelegate {

    
    @IBOutlet weak var cardListView: CardListView!
    
    @IBOutlet weak var cardBackContainerView: UIView!
    
    @IBOutlet weak var cardBackContainerViewBottomConstraint: NSLayoutConstraint!
 
    @IBOutlet weak var cardBackContainerViewTopConstraint: NSLayoutConstraint!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    var cardList = CardListModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
//        let hideCardBackConstraint = NSLayoutConstraint(item: cardBackFrameView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
//        hideCardBackConstraint.active = false
//        view.addConstraint(hideCardBackConstraint)
//        self.cardBackHiddenConstraint = hideCardBackConstraint
        
        // Do any additional setup after loading the view.
        cardListView.reloadData()
        cardBackContainerView.alpha = 0
        cardBackContainerView.hidden = true
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(protectedDataBecameAvailable), name: UIApplicationProtectedDataDidBecomeAvailable, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        setNeedsSaveCardList()
        super.viewWillDisappear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        updateCardBackConstraints()
        super.viewWillLayoutSubviews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateCardBackConstraints() {
        var rect = cardListView.bounds
        rect.size.height = cardListView.focusedCardBottomMargin
        rect = cardListView.convertRect(rect, toView: self.view)
        self.cardBackContainerViewTopConstraint.constant = rect.origin.x + rect.size.height
    }
    
    func loadCardList() {
        
    }
    
    func saveCardList() {
        let processInfo = NSProcessInfo.processInfo()
        let token = processInfo.beginActivityWithOptions([.Background], reason: "saving card list")
        cardList.save { (error) in
            processInfo.endActivity(token)
        }
    }
    
    func setNeedsSaveCardList() {
        let sel = #selector(saveCardList)
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: sel, object: nil)
        self.performSelector(sel, withObject: nil, afterDelay: 0)
    }
    
    func protectedDataBecameAvailable(notification:NSNotification) {
        if !cardList.loaded {
            loadCardList()
        }
    }
    
    func applicationDidEnterBackground(notification:NSNotification) {
        setNeedsSaveCardList()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func addCardDone(unwindSegue:UIStoryboardSegue) {
        
    }

    @IBAction func addCardCancel(unwindSegue:UIStoryboardSegue) {
        
    }

    // MARK: - CardListViewDelegate
    func numberOfItemsInCardListView(view: CardListView) -> Int {
        return 3
    }
    
    func cardListViewWillChangeDisplayMode(view: CardListView) -> Void {
        if view.isFocusedCard {
            // will remove remove focus, hide alpha
            UIView.animateWithDuration(0.2, delay: 0, options: [.BeginFromCurrentState], animations: {
                self.cardBackContainerView.alpha = 0
                }, completion: { (completed) in
                    self.cardBackContainerView.hidden = true
            })
        }
    }
    
    func cardListViewDidChangeDisplayMode(cardView: CardListView) -> Void {
        if cardView.isFocusedCard {
            // have completed focus, set alpha
            
            self.view.layoutIfNeeded()
            updateCardBackConstraints()
            self.cardBackContainerView.hidden = false
            UIView.animateWithDuration(0.2, delay: 0, options: [.BeginFromCurrentState], animations: {
                self.cardBackContainerView.alpha = 1
                self.view.layoutIfNeeded()
                }, completion: { (completed) in
            })
        }
    }

}
