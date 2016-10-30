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
        let barItem = UIBarButtonItem(title: NSLocalizedString("Remove", comment: "Bar Item"), style: .plain, target: self, action: #selector(removeSelectedCard))
        return barItem
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var cardList = CardListModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        cardListView.reloadData()
        cardBackContainerView.alpha = 0
        cardBackContainerView.isHidden = true
        
        showBlankStateInfo(false, animated: false)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(protectedDataBecameAvailable), name: NSNotification.Name.UIApplicationProtectedDataDidBecomeAvailable, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        loadCardList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
        rect = cardListView.convert(rect, to: self.view)
        self.cardBackContainerViewTopConstraint.constant = rect.origin.x + rect.size.height
        
        if let  cards = cardList.cards,
                let focusedCardHolder = cardListView.focusedCardView as? CardEntityHolder,
                let focusedCard = focusedCardHolder.card {
            if cards.index(of: focusedCard) == cards.count - 1 {
                cardBackContainerViewBottomConstraint.constant = 0
            } else {
                cardBackContainerViewBottomConstraint.constant = 20
            }
        }
    }
    
    func loadCardList() {
        let processInfo = ProcessInfo.processInfo
        let token = processInfo.beginActivity(options: [.userInitiated], reason: "loading card list")
        cardList.load { (error) in
            self.cardListView.alpha = 0
            self.cardListView.reloadData()
            self.cardListView.layoutSubviews()
            UIView.animate(withDuration: 0.1, animations: {
                self.cardListView.alpha = 1
                }, completion: { (completed) in
                    processInfo.endActivity(token)
                    self.showBlankStateInfo(self.cardList.cards?.isEmpty ?? true, animated: true)
            })
        }
    }
    
    func saveCardList() {
        let processInfo = ProcessInfo.processInfo
        let token = processInfo.beginActivity(options: [.background], reason: "saving card list")
        cardList.save { (error) in
            processInfo.endActivity(token)
        }
    }
    
    func setNeedsSaveCardList() {
        let sel = #selector(saveCardList)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: sel, object: nil)
        self.perform(sel, with: nil, afterDelay: 0)
    }
    
    
    func showBlankStateInfo(_ show:Bool, animated: Bool) {
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
                self.addCardInstructionLabel.isHidden = false
            } else {
                self.addCardInstructionLabel.isHidden = true
            }
        }
        
        if animated {
            if show {
                self.addCardInstructionLabel.alpha = 0
                self.addCardInstructionLabel.isHidden = false
            }
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: animationBlock, completion: cleanupBlock)
        } else {
            animationBlock()
            cleanupBlock(true)
        }
    }
    

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueIdentifier = segue.identifier {
            switch segueIdentifier {
            case "embedCardBackTabs":
                if let tabCtrl = segue.destination as? UITabBarController {
                    cardBackTabController = tabCtrl
                }
            default: ()
            }
        }
    }
    
    func updateCardBackDisplay(_ selectedCard : CardEntity) {
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
    
    func protectedDataBecameAvailable(_ notification:Notification) {
        if !cardList.loaded {
            loadCardList()
        }
    }
    
    func applicationDidEnterBackground(_ notification:Notification) {
        setNeedsSaveCardList()
    }

    // MARK: - Action Handlers
    
    @IBAction func addCardDone(_ unwindSegue:UIStoryboardSegue) {
        guard let   verifyCtrl = unwindSegue.source as? CardVerifyViewController,
                    let addedCard = verifyCtrl.card else {
            return
        }
        cardList.add(addedCard)
        cardListView.appendItem(completion: {
            (Bool) in
            self.showBlankStateInfo(self.cardList.cards?.isEmpty ?? true, animated: true)
        })
        setNeedsSaveCardList()
    }

    @IBAction func addCardCancel(_ unwindSegue:UIStoryboardSegue) {
        // no implementation yet, just placholder for unwind segue.
    }
    
    @IBAction func removeSelectedCard(_ sender:AnyObject) {
        guard let   focusedView = cardListView.focusedCardView,
                    let focusedCardHolder = focusedView as? CardEntityHolder else {
            return
        }
        
        let alertCtrl = UIAlertController(title: NSLocalizedString("Remove Card",comment:"Card Removal"), message:NSLocalizedString("Remove selected card?\nYou cannot undo this.", comment: "confirm remove card") , preferredStyle: .alert)
        alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Remove", comment: "default remove") , style: .destructive, handler: { (action) in
            if let removedIndex = self.cardList.remove(focusedCardHolder.card) {
                self.cardListView.removeItemAtIndex(removedIndex,completion: {
                    (Bool) in
                    self.showBlankStateInfo(self.cardList.cards?.isEmpty ?? true, animated: true)
                })
                self.setNeedsSaveCardList()
                
            }
        }))
        alertCtrl.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "default cancel"), style: .cancel, handler: { (action) in
            // nothing yet
        }))
        self.present(alertCtrl, animated: true, completion: nil)
    }

    // MARK: - CardListViewDelegate
    func numberOfItemsInCardListView(_ view: CardListView) -> Int {
        return cardList.cards?.count ?? 0
    }
    
    func cardListView(_ view: CardListView, itemAtIndex row: Int) -> UIView {
        guard let cards = cardList.cards else {
            // shouldn't happen. in case it does, return a blank UIView
            return UIView(frame: CGRect.zero)
        }
        let bundle = Bundle(for: type(of: self))
        let itemView = bundle.loadNibNamed("CardItemView", owner: self, options: [:])?.first as! CardItemView
        itemView.card = cards[row]
        
        return itemView
    }
    
    func cardListView(_ view: CardListView, didMoveItemAtIndexToFront row: Int) -> Void {
        cardList.moveToFront(row)
        setNeedsSaveCardList()
    }

    
    func cardListView(_ view: CardListView,willFocusItem itemView:UIView) -> Void {
        if let  cardView = itemView as? CardEntityHolder,
                let selectedCard = cardView.card {
            updateCardBackDisplay(selectedCard)
        }
    }

    let cardFocusAnimationDuration = TimeInterval(0.2)

    func cardListView(_ view: CardListView,didFocusItem cardView:UIView) -> Void {
        // have completed focus, set alpha
        updateCardBackConstraints()
        self.view.layoutIfNeeded()
        self.cardBackContainerView.isHidden = false
        UIView.animate(withDuration: cardFocusAnimationDuration, delay: 0, options: [.beginFromCurrentState], animations: {
            self.cardBackContainerView.alpha = 1
            self.view.layoutIfNeeded()
            }, completion: { (completed) in
                self.navigationItem.rightBarButtonItem = self.removeCardBarItem
        })
    }
    
    func cardListView(_ view: CardListView,willUnfocusItem cardView:UIView) -> Void {
        UIView.animate(withDuration: cardFocusAnimationDuration, delay: 0, options: [.beginFromCurrentState], animations: {
            self.cardBackContainerView.alpha = 0
            }, completion: { (completed) in
                self.cardBackContainerView.isHidden = true
        })
    }
    
    func cardListView(_ view: CardListView, didUnfocusItem cardView: UIView) {
        self.navigationItem.rightBarButtonItem = self.addCardBarItem
    }
}
