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
    
    var cardViews = Array<CardItemView>()
    
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
    
    let cardItemOffset = CGFloat(20)
    
    var dynamicAnimator : UIDynamicAnimator? {
        didSet {
            dynamicAnimator?.delegate = self
        }
    }
    
    /**
     Maps CardItemView to UIAttachmentBehavior
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
        var currentOffset = cardItemOffset
        for cardView in cardViews {
            if let constraint = topOffsetConstraints.objectForKey(cardView) as? NSLayoutConstraint {
                constraint.constant = currentOffset
                currentOffset += cardItemOffset
            }
        }
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    func reloadData() {
        guard let delegate = self.delegate else {
            return
        }
        
        for view in cardViews {
            view.removeFromSuperview()
        }
        cardViews.removeAll()

        let leftMargin = 8
        let rightMargin = 8
        
        // temporary colors
        let colors = [UIColor.greenColor(),UIColor.yellowColor(),UIColor.redColor(),UIColor.blueColor()]
        let numberOfItems = delegate.numberOfItemsInCardListView(self)
        cardViews.reserveCapacity(numberOfItems)
        var currentOffset = cardItemOffset
        
        for i in 0..<numberOfItems {
            let itemView = CardItemView()
            itemView.translatesAutoresizingMaskIntoConstraints = false
            itemView.backgroundColor = colors[i]

            containerView.addSubview(itemView)
            
            //  the size of credit cards is 85.60 × 53.98 mm ratio is 1.5858
            let ratioConstraint = NSLayoutConstraint(item: itemView, attribute: .Width, relatedBy: .Equal, toItem: itemView, attribute: .Height, multiplier: CGFloat(1.5858), constant: 0)
            let topConstraint = NSLayoutConstraint(item: itemView, attribute: .Top, relatedBy: .Equal, toItem: containerView, attribute: .Top, multiplier: 1, constant: CGFloat(currentOffset))
            
            containerView.addConstraint(NSLayoutConstraint(item: itemView, attribute: .Leading, relatedBy: .Equal, toItem: containerView, attribute: .Leading, multiplier: 1, constant: CGFloat(leftMargin)))
            containerView.addConstraint(NSLayoutConstraint(item: itemView, attribute: .Trailing, relatedBy: .Equal, toItem: containerView, attribute: .Trailing, multiplier: 1, constant: -CGFloat(rightMargin)))
            containerView.addConstraint(ratioConstraint)
            containerView.addConstraint(topConstraint)
            
            cardViews.append(itemView)
            topOffsetConstraints.setObject(topConstraint, forKey: itemView)
            
            currentOffset += cardItemOffset
            
            let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCardDragGesture))
            dragGesture.maximumNumberOfTouches = 1
            itemView.addGestureRecognizer(dragGesture)
            
            // Apparently UIInterpolatingMotionEffect is not compatible with UIDynamicAnimator
        }
    }
    
    // MARK: UIDynamicAnimatorDelegate
    
    func  dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        setNeedsUpdateConstraints()
    }
    
    
    // MARK: - handlers
    
    func handleCardDragGesture(gesture : UIPanGestureRecognizer) {
        guard let draggedView = gesture.view else {
            return
        }
        let touchPoint = gesture.locationInView(containerView)
        
        switch gesture.state {
        case .Began:
            if let existingDrag = cardDragAttachment {
                dynamicAnimator?.removeBehavior(existingDrag)
            }
            let attachment = UIAttachmentBehavior(item: draggedView, attachedToAnchor: touchPoint)
            dynamicAnimator?.addBehavior(attachment)
            cardDragAttachment = attachment
        case .Changed:
            if let attachment = cardDragAttachment {
                attachment.anchorPoint = touchPoint
            }
        case .Ended:
            if let  cardView = draggedView as? CardItemView,
                    cardViewIndex = cardViews.indexOf(cardView) {
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
                        
                        cardViews.removeAtIndex(cardViewIndex)
                        cardViews.append(cardView)
                        containerView.bringSubviewToFront(cardView)

                        dynamicAnimator?.updateItemUsingCurrentState(containerView)
                        for i in 0..<cardSnapPoints.count {
                            let cv = cardViews[i]
                            let pt = cardSnapPoints[i]
                            if let attachment = cardCenterAttachments.objectForKey(cv) as? UIAttachmentBehavior {
                                attachment.anchorPoint = pt
                            }
                            if let snap = cardCenterSnaps.objectForKey(cv) as? UISnapBehavior {
                                snap.snapPoint = pt
                            }
                            dynamicAnimator?.updateItemUsingCurrentState(cv)
                        }
                    }
                }
            }
            fallthrough
        case .Cancelled:
            if let attachment = cardDragAttachment {
                dynamicAnimator?.removeBehavior(attachment)
                cardDragAttachment = nil
            }
        default:
            ()
        }

    }

}


@objc protocol CardListViewDelegate  {
    
    func numberOfItemsInCardListView(view: CardListView) -> Int
    
}