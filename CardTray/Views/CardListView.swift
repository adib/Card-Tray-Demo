//
//  CardListView.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

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
                let frame = firstCardView.convert(bounds, to: self)
                let bottom = ceil(frame.origin.y + frame.size.height + 8)
                return bottom
            }
            return 0
        }
    }

    let topCardMargin = CGFloat(8)

    var lowestCardPos = CGFloat(0)
    
    var topOffsetConstraints = NSMapTable<AnyObject, AnyObject>.weakToWeakObjects()
    
    lazy var containerView : UIView = {
        [unowned self] in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        let bindingsDict = ["view": view]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: bindingsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: bindingsDict))
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
    var cardCenterAttachments = NSMapTable<AnyObject, AnyObject>.weakToWeakObjects()
    var cardCenterSnaps = NSMapTable<AnyObject, AnyObject>.weakToWeakObjects()
    
    weak var cardDragAttachment : UIAttachmentBehavior?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        self.cardList = nil
    }
    
    override func layoutSubviews() {
        dynamicAnimator?.removeAllBehaviors()
        super.layoutSubviews()
        let containerBounds = containerView.bounds
        if !containerBounds.isEmpty {
            let animator = dynamicAnimator ?? UIDynamicAnimator(referenceView: containerView)
            containerView.layoutIfNeeded()
            var maxCardBottom = CGFloat(0)
            for cardItem in cardViews {
                let itemFrame = cardItem.frame
                if !itemFrame.isEmpty {
                    let cardCenter = cardItem.center
                    let snap = UISnapBehavior(item: cardItem, snapTo: cardCenter)
                    snap.damping = 0.9
                    animator.addBehavior(snap)
                    cardCenterSnaps.setObject(snap,forKey:cardItem)
                    
                    let attachment = UIAttachmentBehavior.slidingAttachment(with: cardItem, attachmentAnchor: cardCenter, axisOfTranslation: CGVector(dx: 0,dy: 1))
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
                guard let constraint = topOffsetConstraints.object(forKey: curView) as? NSLayoutConstraint else {
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
                if let constraint = topOffsetConstraints.object(forKey: cardView) as? NSLayoutConstraint {
                    constraint.constant = currentOffset
                    currentOffset += cardItemOffset
                }
            }
        }
    }
    
    fileprivate func newCardItemViewAtIndex(_ cardIndex:Int) -> UIView {
        let itemView = delegate!.cardListView(self, itemAtIndex: cardIndex)
        itemView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(itemView)

        let leftMargin = 8
        let rightMargin = 8
        let topOffset = topCardMargin + cardItemOffset * CGFloat(cardIndex)

        itemView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(itemView)
        
        //  the size of credit cards is 85.60 × 53.98 mm ratio is 1.5858
        let ratioConstraint = NSLayoutConstraint(item: itemView, attribute: .width, relatedBy: .equal, toItem: itemView, attribute: .height, multiplier: CGFloat(1.5858), constant: 0)
        let topConstraint = NSLayoutConstraint(item: itemView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: topOffset)
        
        containerView.addConstraint(NSLayoutConstraint(item: itemView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: CGFloat(leftMargin)))
        containerView.addConstraint(NSLayoutConstraint(item: itemView, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -CGFloat(rightMargin)))
        containerView.addConstraint(ratioConstraint)
        containerView.addConstraint(topConstraint)
        
        cardViews.insert(itemView, at: cardIndex)
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
        
        layoutSubviews()
    }
    
    let cardMovementAnimationDuration = TimeInterval(0.5)
    
    func appendItem(completion completionBlock: ((Bool)->Void)? ) {
        guard let delegate = self.delegate else {
            return
        }
        let numberOfCards = delegate.numberOfItemsInCardListView(self)
        cardViews.reserveCapacity(numberOfCards)
        let newCardView = newCardItemViewAtIndex(numberOfCards-1)
        
        // animate drop down from top
        if let topConstraint = topOffsetConstraints.object(forKey: newCardView) as? NSLayoutConstraint {
            let originalTopOffset = topConstraint.constant
            topConstraint.constant = -self.focusedCardBottomMargin
            layoutSubviews()
            UIView.animate(withDuration: cardMovementAnimationDuration, animations: {
                topConstraint.constant = originalTopOffset
                self.layoutSubviews()
                }, completion: completionBlock)
        }
    }
    
    func removeItemAtIndex(_ index:Int,completion completionBlock: ((Bool)->Void)? ) {
        let cardView = cardViews[index]
        
        let cleanup = {
            self.cardViews.remove(at: index)
            if let oldFocusedCardView = self.focusedCardView, oldFocusedCardView === cardView {
                self.toggleFocus(nil)
            }
            cardView.removeFromSuperview()
        }
        
        if let topConstraint = topOffsetConstraints.object(forKey: cardView) as? NSLayoutConstraint {
            let bounds = containerView.bounds
            let targetOffset = bounds.origin.y + bounds.size.height + cardItemOffset
            layoutSubviews()
            UIView.animate(withDuration: cardMovementAnimationDuration, animations: {
                topConstraint.constant = targetOffset
                self.layoutSubviews()
                }, completion:  {
                    (completed) in
                    cleanup()
                    completionBlock?(completed)
                })
        } else {
            cleanup()
            completionBlock?(true)
        }
    }
    
    fileprivate func toggleFocus(_ newFocusedCardView : UIView? ) {
        // if no focused view, then will transition from unfocused to focused
        let oldFocusedCardView = self.focusedCardView
        if oldFocusedCardView == nil {
            // focus the card view
            self.delegate?.cardListView?(self, willFocusItem: newFocusedCardView!)
            self.focusedCardView = newFocusedCardView!
        } else {
            // remove focus
            self.delegate?.cardListView?(self, willUnfocusItem: oldFocusedCardView!)
            self.focusedCardView = nil
        }
        let cardAnimationDuration = 0.3
        UIView.animate(withDuration: cardAnimationDuration, delay: 0, options: [.beginFromCurrentState], animations: {
            self.updateConstraints()
            self.layoutSubviews()
            }, completion: { (completed) in
                if oldFocusedCardView == nil {
                    self.delegate?.cardListView?(self, didFocusItem: newFocusedCardView!)
                } else {
                    self.delegate?.cardListView?(self, didUnfocusItem: oldFocusedCardView!)
                }
        })
    }
    
    // MARK: UIDynamicAnimatorDelegate
    
    func  dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        if self.cardDragAttachment == nil {
            setNeedsUpdateConstraints()
        }
    }
    
    
    // MARK: - handlers
    
    func handleCardDragGesture(_ gesture : UIPanGestureRecognizer) {
        guard let cardView = gesture.view else {
            return
        }
        let touchPoint = gesture.location(in: containerView)
        let cleanupDrag = {
            if let attachment = self.cardDragAttachment {
                self.dynamicAnimator?.removeBehavior(attachment)
                self.cardDragAttachment = nil
            }
        }
        
        switch gesture.state {
        case .possible:
            if self.focusedCardView != nil {
                // cancel the gesture if display mode is focus
                gesture.isEnabled = false
                gesture.isEnabled = true
            }
        case .began:
            cleanupDrag()
            let attachment = UIAttachmentBehavior(item: cardView, attachedToAnchor: touchPoint)
            dynamicAnimator?.addBehavior(attachment)
            cardDragAttachment = attachment
        case .changed:
            if let attachment = cardDragAttachment {
                attachment.anchorPoint = touchPoint
            }
        case .ended:
            if let  cardViewIndex = cardViews.index(of: cardView) {
                let lastCardIndex = cardViews.count - 1
                if cardViewIndex != lastCardIndex {
                    // if not end of card and top has gone below the bottom end
                    let cardFrame = cardView.frame
                    let cardBottom = cardFrame.origin.y + cardFrame.size.height
                    if cardBottom >= lowestCardPos + cardItemOffset {
                        
                        var cardSnapPoints = Array<CGPoint>()
                        cardSnapPoints.reserveCapacity(cardViews.count)
                        for cv in cardViews {
                            if let snap = cardCenterSnaps.object(forKey: cv) as? UISnapBehavior {
                                let pt = snap.snapPoint
                                cardSnapPoints.append(pt)
                            }
                        }

                        self.cardViews.remove(at: cardViewIndex)
                        self.cardViews.append(cardView)
                        self.containerView.bringSubview(toFront: cardView)
                        self.dynamicAnimator?.updateItem(usingCurrentState: self.containerView)

                        for i in 0..<cardSnapPoints.count {
                            let cv = self.cardViews[i]
                            let pt = cardSnapPoints[i]
                            if let attachment = self.cardCenterAttachments.object(forKey: cv) as? UIAttachmentBehavior {
                                attachment.anchorPoint = pt
                            }
                            if let snap = self.cardCenterSnaps.object(forKey: cv) as? UISnapBehavior {
                                snap.snapPoint = pt
                            }
                            self.dynamicAnimator?.updateItem(usingCurrentState: cv)
                        }
                        
                        self.delegate?.cardListView(self, didMoveItemAtIndexToFront: cardViewIndex)
                    }
                }
            }
            fallthrough
        case .cancelled:
            cleanupDrag()
        default:
            ()
        }
    }

    func handleCardTapGesture(_ gesture:UITapGestureRecognizer) {
        guard let tappedCardView = gesture.view else {
            return
        }
        
        switch gesture.state {
        case .ended:
            toggleFocus(tappedCardView)

        default: ()
        }
    }
}


@objc protocol CardListViewDelegate  {
    
    func numberOfItemsInCardListView(_ view: CardListView) -> Int

    func cardListView(_ view: CardListView, itemAtIndex row: Int) -> UIView
    
    func cardListView(_ view: CardListView, didMoveItemAtIndexToFront row: Int) -> Void
    
    @objc optional func cardListView(_ view: CardListView,willFocusItem cardView:UIView) -> Void
    @objc optional func cardListView(_ view: CardListView,didFocusItem cardView:UIView) -> Void

    @objc optional func cardListView(_ view: CardListView,willUnfocusItem cardView:UIView) -> Void
    @objc optional func cardListView(_ view: CardListView,didUnfocusItem cardView:UIView) -> Void

}
