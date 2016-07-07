//
//  CardListViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

class CardListViewController: UIViewController, CardListViewDelegate {

    weak var cardBackTabController : UITabBarController?
    
    @IBOutlet weak var cardListView: CardListView!
    
    @IBOutlet weak var cardBackContainerView: UIView!
    
    @IBOutlet weak var cardBackContainerViewBottomConstraint: NSLayoutConstraint!
 
    @IBOutlet weak var cardBackContainerViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var addCardBarItem: UIBarButtonItem!
    
    @IBOutlet weak var addCardInstructionLabel: UILabel!
    
    lazy var removeCardBarItem: UIBarButtonItem = {
        let barItem = UIBarButtonItem(title: NSLocalizedString("Remove", comment: "Bar Item"), style: .Plain, target: self, action: #selector(removeSelectedCard))
        return barItem
    }()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    var cardList = CardListModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cardListView.reloadData()
        cardBackContainerView.alpha = 0
        cardBackContainerView.hidden = true
        
        showBlankStateInfo(false, animated: false)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(protectedDataBecameAvailable), name: UIApplicationProtectedDataDidBecomeAvailable, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        loadCardList()
    }
    
    override func viewWillDisappear(animated: Bool) {
        setNeedsSaveCardList()
        super.viewWillDisappear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        updateCardBackConstraints()
        super.viewWillLayoutSubviews()
    }
    
    func updateCardBackConstraints() {
        var rect = cardListView.bounds
        rect.size.height = cardListView.focusedCardBottomMargin
        rect = cardListView.convertRect(rect, toView: self.view)
        self.cardBackContainerViewTopConstraint.constant = rect.origin.x + rect.size.height
        
        if let  cards = cardList.cards,
                focusedCardHolder = cardListView.focusedCardView as? CardEntityHolder,
                focusedCard = focusedCardHolder.card {
            if cards.indexOf(focusedCard) == cards.count - 1 {
                cardBackContainerViewBottomConstraint.constant = 0
            } else {
                cardBackContainerViewBottomConstraint.constant = 20
            }
        }
    }
    
    func loadCardList() {
        let processInfo = NSProcessInfo.processInfo()
        let token = processInfo.beginActivityWithOptions([.UserInitiated], reason: "loading card list")
        cardList.load { (error) in
            self.cardListView.alpha = 0
            self.cardListView.reloadData()
            self.cardListView.layoutSubviews()
            UIView.animateWithDuration(0.1, animations: {
                self.cardListView.alpha = 1
                }, completion: { (completed) in
                    processInfo.endActivity(token)
                    self.showBlankStateInfo(self.cardList.cards?.isEmpty ?? true, animated: true)
            })
        }
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
    
    
    func showBlankStateInfo(show:Bool, animated: Bool) {
        let animationBlock = {
            if show {
                self.addCardInstructionLabel.alpha = 1
            } else {
                self.addCardInstructionLabel.alpha = 0
            }
        }
        
        let cleanupBlock = {
            (completed : Bool) in
            if show {
                self.addCardInstructionLabel.hidden = false
            } else {
                self.addCardInstructionLabel.hidden = true
            }
        }
        
        if animated {
            if show {
                self.addCardInstructionLabel.alpha = 0
                self.addCardInstructionLabel.hidden = false
            }
            UIView.animateWithDuration(0.2, delay: 0, options: [.BeginFromCurrentState], animations: animationBlock, completion: cleanupBlock)
        } else {
            animationBlock()
            cleanupBlock(true)
        }
    }
    

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "embedCardBackTabs":
                if let tabCtrl = segue.destinationViewController as? UITabBarController {
                    cardBackTabController = tabCtrl
                }
            default: ()
            }
        }
    }
    
    func updateCardBackDisplay(selectedCard : CardEntity) {
        guard let tabCtrl = self.cardBackTabController else {
            return
        }
        if let viewControllers = tabCtrl.viewControllers {
            tabCtrl.selectedIndex = 0
            for viewCtrl in viewControllers {
                if let cardCtrl = viewCtrl as? CardEntityHolder {
                    cardCtrl.card = selectedCard
                }
            }
        }
    }
    
    // MARK: - Event Handlers
    
    func protectedDataBecameAvailable(notification:NSNotification) {
        if !cardList.loaded {
            loadCardList()
        }
    }
    
    func applicationDidEnterBackground(notification:NSNotification) {
        setNeedsSaveCardList()
    }

    // MARK: - Action Handlers
    
    @IBAction func addCardDone(unwindSegue:UIStoryboardSegue) {
        guard let   verifyCtrl = unwindSegue.sourceViewController as? CardVerifyViewController,
                    addedCard = verifyCtrl.card else {
            return
        }
        cardList.add(addedCard)
        cardListView.appendItem(completion: {
            (Bool) in
            self.showBlankStateInfo(self.cardList.cards?.isEmpty ?? true, animated: true)
        })
        setNeedsSaveCardList()
    }

    @IBAction func addCardCancel(unwindSegue:UIStoryboardSegue) {
        // no implementation yet, just placholder for unwind segue.
    }
    
    @IBAction func removeSelectedCard(sender:AnyObject) {
        guard let   focusedView = cardListView.focusedCardView,
                    focusedCardHolder = focusedView as? CardEntityHolder else {
            return
        }
        
        let alertCtrl = UIAlertController(title: NSLocalizedString("Remove Card",comment:"Card Removal"), message:NSLocalizedString("Remove selected card?\nYou cannot undo this.", comment: "confirm remove card") , preferredStyle: .Alert)
        alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Remove", comment: "default remove") , style: .Destructive, handler: { (action) in
            if let removedIndex = self.cardList.remove(focusedCardHolder.card) {
                self.cardListView.removeItemAtIndex(removedIndex,completion: {
                    (Bool) in
                    self.showBlankStateInfo(self.cardList.cards?.isEmpty ?? true, animated: true)
                })
                self.setNeedsSaveCardList()
                
            }
        }))
        alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "default cancel"), style: .Cancel, handler: { (action) in
            // nothing yet
        }))
        self.presentViewController(alertCtrl, animated: true, completion: nil)
    }

    // MARK: - CardListViewDelegate
    func numberOfItemsInCardListView(view: CardListView) -> Int {
        return cardList.cards?.count ?? 0
    }
    
    func cardListView(view: CardListView, itemAtIndex row: Int) -> UIView {
        guard let cards = cardList.cards else {
            // shouldn't happen. in case it does, return a blank UIView
            return UIView(frame: CGRectZero)
        }
        let bundle = NSBundle(forClass: self.dynamicType)
        let itemView = bundle.loadNibNamed("CardItemView", owner: self, options: [:]).first as! CardItemView
        itemView.card = cards[row]
        
        return itemView
    }
    
    func cardListView(view: CardListView, didMoveItemAtIndexToFront row: Int) -> Void {
        cardList.moveToFront(row)
        setNeedsSaveCardList()
    }

    
    func cardListView(view: CardListView,willFocusItem itemView:UIView) -> Void {
        if let  cardView = itemView as? CardEntityHolder,
                selectedCard = cardView.card {
            updateCardBackDisplay(selectedCard)
        }
    }

    let cardFocusAnimationDuration = NSTimeInterval(0.2)

    func cardListView(view: CardListView,didFocusItem cardView:UIView) -> Void {
        // have completed focus, set alpha
        updateCardBackConstraints()
        self.view.layoutIfNeeded()
        self.cardBackContainerView.hidden = false
        UIView.animateWithDuration(cardFocusAnimationDuration, delay: 0, options: [.BeginFromCurrentState], animations: {
            self.cardBackContainerView.alpha = 1
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.navigationItem.rightBarButtonItem = self.removeCardBarItem
        })
    }
    
    func cardListView(view: CardListView,willUnfocusItem cardView:UIView) -> Void {
        UIView.animateWithDuration(cardFocusAnimationDuration, delay: 0, options: [.BeginFromCurrentState], animations: {
            self.cardBackContainerView.alpha = 0
            }, completion: { (completed) in
                self.cardBackContainerView.hidden = true
        })
    }
    
    func cardListView(view: CardListView, didUnfocusItem cardView: UIView) {
        self.navigationItem.rightBarButtonItem = self.addCardBarItem
    }
}
