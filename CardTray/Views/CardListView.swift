//
//  CardListView.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardListView: UIView,UIDynamicAnimatorDelegate {
    
    @IBOutlet weak var delegate : CardListViewDelegate?
    
    var cardList : CardListModel? {
        didSet {
            self.reloadData()
        }
    }
    
    var cardViews = Array<UIView>()
    
    var focusedCardView : UIView?
    
    var isFocusedCard : Bool {
        get {
            return focusedCardView != nil
        }
    }
    
    var focusedCardBottomMargin : CGFloat {
        get {
            if let firstCardView = cardViews.first {
                let bounds = firstCardView.bounds
                let frame = firstCardView.convertRect(bounds, toView: self)
                let bottom = ceil(frame.origin.y + frame.size.height + 8)
                return bottom
            }
            return 0
        }
    }

    let topCardMargin = CGFloat(8)

    var lowestCardPos = CGFloat(0)
    
    var topOffsetConstraints = NSMapTable.weakToWeakObjectsMapTable()
    
    lazy var containerView : UIView = {
        [unowned self] in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        let bindingsDict = ["view": view]
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: bindingsDict))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: bindingsDict))
        return view
    }()
    
    let cardItemOffset = CGFloat(44)
    
    var dynamicAnimator : UIDynamicAnimator? {
        didSet {
            dynamicAnimator?.delegate = self
        }
    }
    
    /**
     Maps cards in `cardViews` to UIAttachmentBehavior
     */
    var cardCenterAttachments = NSMapTable.weakToWeakObjectsMapTable()
    var cardCenterSnaps = NSMapTable.weakToWeakObjectsMapTable()
    
    weak var cardDragAttachment : UIAttachmentBehavior?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        //let animator =
    }
    
    deinit {
        self.cardList = nil
    }
    
    override func layoutSubviews() {
        dynamicAnimator?.removeAllBehaviors()
        super.layoutSubviews()
        let containerBounds = containerView.bounds
        if !CGRectIsEmpty(containerBounds) {
            let animator = dynamicAnimator ?? UIDynamicAnimator(referenceView: containerView)
            containerView.layoutIfNeeded()
            var maxCardBottom = CGFloat(0)
            for cardItem in cardViews {
                let itemFrame = cardItem.frame
                if !CGRectIsEmpty(itemFrame) {
                    let cardCenter = cardItem.center
                    let snap = UISnapBehavior(item: cardItem, snapToPoint: cardCenter)
                    snap.damping = 0.9
                    animator.addBehavior(snap)
                    cardCenterSnaps.setObject(snap,forKey:cardItem)
                    
                    let attachment = UIAttachmentBehavior.slidingAttachmentWithItem(cardItem, attachmentAnchor: cardCenter, axisOfTranslation: CGVectorMake(0,1))
                    animator.addBehavior(attachment)
                    cardCenterAttachments.setObject(attachment,forKey:cardItem)
                    let cardBottom = itemFrame.origin.y + itemFrame.size.height
                    if cardBottom > maxCardBottom {
                        maxCardBottom = cardBottom
                    }
                }
            }
            if maxCardBottom > 0 {
                lowestCardPos = maxCardBottom
            }
            let noRotate = UIDynamicItemBehavior(items: cardViews)
            noRotate.allowsRotation = false
            animator.addBehavior(noRotate)
            dynamicAnimator = animator
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        if let focusedCardView = self.focusedCardView {
            let containerBounds = containerView.bounds
            let bottomCardConstant = containerBounds.size.height - topCardMargin * 2
            let topCardConstant = topCardMargin
            var foundFocusedCard = false
            for curView in cardViews {
                guard let constraint = topOffsetConstraints.objectForKey(curView) as? NSLayoutConstraint else {
                    continue
                }
                if foundFocusedCard {
                    constraint.constant = bottomCardConstant;
                } else {
                    constraint.constant = topCardConstant
                }
                if curView === focusedCardView {
                    foundFocusedCard = true
                }
            }
        } else {
            var currentOffset = topCardMargin
            for cardView in cardViews {
                if let constraint = topOffsetConstraints.objectForKey(cardView) as? NSLayoutConstraint {
                    constraint.constant = currentOffset
                    currentOffset += cardItemOffset
                }
            }
        }
    }
    
    private func newCardItemViewAtIndex(cardIndex:Int) -> UIView {
        let itemView = delegate!.cardListView(self, itemAtIndex: cardIndex)
        itemView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(itemView)

        let leftMargin = 8
        let rightMargin = 8
        let topOffset = topCardMargin + cardItemOffset * CGFloat(cardIndex)

        itemView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(itemView)
        
        //  the size of credit cards is 85.60 × 53.98 mm ratio is 1.5858
        let ratioConstraint = NSLayoutConstraint(item: itemView, attribute: .Width, relatedBy: .Equal, toItem: itemView, attribute: .Height, multiplier: CGFloat(1.5858), constant: 0)
        let topConstraint = NSLayoutConstraint(item: itemView, attribute: .Top, relatedBy: .Equal, toItem: containerView, attribute: .Top, multiplier: 1, constant: topOffset)
        
        containerView.addConstraint(NSLayoutConstraint(item: itemView, attribute: .Leading, relatedBy: .Equal, toItem: containerView, attribute: .Leading, multiplier: 1, constant: CGFloat(leftMargin)))
        containerView.addConstraint(NSLayoutConstraint(item: itemView, attribute: .Trailing, relatedBy: .Equal, toItem: containerView, attribute: .Trailing, multiplier: 1, constant: -CGFloat(rightMargin)))
        containerView.addConstraint(ratioConstraint)
        containerView.addConstraint(topConstraint)
        
        cardViews.insert(itemView, atIndex: cardIndex)
        topOffsetConstraints.setObject(topConstraint, forKey: itemView)
        
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCardDragGesture))
        dragGesture.maximumNumberOfTouches = 1
        itemView.addGestureRecognizer(dragGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCardTapGesture))
        tapGesture.numberOfTapsRequired = 1
        itemView.addGestureRecognizer(tapGesture)

        // Apparently UIInterpolatingMotionEffect is not compatible with UIDynamicAnimator so we can't use it here

        return itemView
    }
    
    
    func reloadData() {
        guard let delegate = self.delegate else {
            return
        }
        for view in cardViews {
            view.removeFromSuperview()
        }
        cardViews.removeAll()

        let numberOfCards = delegate.numberOfItemsInCardListView(self)
        cardViews.reserveCapacity(numberOfCards)
        
        for currentRow in 0..<numberOfCards {
            newCardItemViewAtIndex(currentRow)
        }
    }
    
    func appendItem() {
        guard let delegate = self.delegate else {
            return
        }
        let numberOfCards = delegate.numberOfItemsInCardListView(self)
        cardViews.reserveCapacity(numberOfCards)
        let newCardView = newCardItemViewAtIndex(numberOfCards-1)
        
        // animate drop down from top
        if let topConstraint = topOffsetConstraints.objectForKey(newCardView) as? NSLayoutConstraint {
            let originalTopOffset = topConstraint.constant
            topConstraint.constant = -self.focusedCardBottomMargin
            layoutSubviews()
            // TODO: reduce animation duration
            UIView.animateWithDuration(1, animations: {
                topConstraint.constant = originalTopOffset
                self.layoutSubviews()
                }, completion: { (completion) in
                    //<#code#>
            })
        }
    }
    
    func removeItemAtIndex(index:Int) {
        // TODO: card removal
    }
    
    // MARK: UIDynamicAnimatorDelegate
    
    func  dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        if self.cardDragAttachment == nil {
            setNeedsUpdateConstraints()
        }
    }
    
    
    // MARK: - handlers
    
    func handleCardDragGesture(gesture : UIPanGestureRecognizer) {
        guard let cardView = gesture.view else {
            return
        }
        let touchPoint = gesture.locationInView(containerView)
        let cleanupDrag = {
            if let attachment = self.cardDragAttachment {
                self.dynamicAnimator?.removeBehavior(attachment)
                self.cardDragAttachment = nil
            }
        }
        
        switch gesture.state {
        case .Possible:
            if self.focusedCardView != nil {
                // cancel the gesture if display mode is focus
                gesture.enabled = false
                gesture.enabled = true
            }
        case .Began:
            cleanupDrag()
            let attachment = UIAttachmentBehavior(item: cardView, attachedToAnchor: touchPoint)
            dynamicAnimator?.addBehavior(attachment)
            cardDragAttachment = attachment
        case .Changed:
            if let attachment = cardDragAttachment {
                attachment.anchorPoint = touchPoint
            }
        case .Ended:
            if let  cardViewIndex = cardViews.indexOf(cardView) {
                let lastCardIndex = cardViews.count - 1
                if cardViewIndex != lastCardIndex {
                    // if not end of card and top has gone below the bottom end
                    let cardFrame = cardView.frame
                    let cardBottom = cardFrame.origin.y + cardFrame.size.height
                    if cardBottom >= lowestCardPos + cardItemOffset {
                        
                        var cardSnapPoints = Array<CGPoint>()
                        cardSnapPoints.reserveCapacity(cardViews.count)
                        for cv in cardViews {
                            if let snap = cardCenterSnaps.objectForKey(cv) as? UISnapBehavior {
                                let pt = snap.snapPoint
                                cardSnapPoints.append(pt)
                            }
                        }

                        self.cardViews.removeAtIndex(cardViewIndex)
                        self.cardViews.append(cardView)
                        self.containerView.bringSubviewToFront(cardView)
                        self.dynamicAnimator?.updateItemUsingCurrentState(self.containerView)

                        for i in 0..<cardSnapPoints.count {
                            let cv = self.cardViews[i]
                            let pt = cardSnapPoints[i]
                            if let attachment = self.cardCenterAttachments.objectForKey(cv) as? UIAttachmentBehavior {
                                attachment.anchorPoint = pt
                            }
                            if let snap = self.cardCenterSnaps.objectForKey(cv) as? UISnapBehavior {
                                snap.snapPoint = pt
                            }
                            self.dynamicAnimator?.updateItemUsingCurrentState(cv)
                        }
                        
                        self.delegate?.cardListView(self, didMoveItemAtIndexToFront: cardViewIndex)
                    }
                }
            }
            fallthrough
        case .Cancelled:
            cleanupDrag()
        default:
            ()
        }
    }

    func handleCardTapGesture(gesture:UITapGestureRecognizer) {
        guard let tappedCardView = gesture.view else {
            return
        }
        
        let cardAnimationDuration = 0.5
        switch gesture.state {
        case .Ended:
            self.delegate?.cardListViewWillChangeDisplayMode?(self)
            if self.focusedCardView != nil {
                // has card view in focus. unfocus it.
                self.focusedCardView = nil
            } else {
                // focus the card view
                self.focusedCardView = tappedCardView
            }
            UIView.animateWithDuration(cardAnimationDuration, delay: 0, options: [.BeginFromCurrentState], animations: {
                self.updateConstraints()
                self.layoutSubviews()
                }, completion: { (completed) in
                    self.delegate?.cardListViewDidChangeDisplayMode?(self)
            })

        default: ()
        }
    }
}


@objc protocol CardListViewDelegate  {
    
    func numberOfItemsInCardListView(view: CardListView) -> Int

    func cardListView(view: CardListView, itemAtIndex row: Int) -> UIView
    
    func cardListView(view: CardListView, didMoveItemAtIndexToFront row: Int) -> Void
    
    optional func cardListViewWillChangeDisplayMode(view: CardListView) -> Void
    optional func cardListViewDidChangeDisplayMode(view: CardListView) -> Void
    
}