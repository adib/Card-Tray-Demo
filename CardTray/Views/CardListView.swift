//
//  CardListView.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardListView: UIView {
    
    @IBOutlet weak var delegate : CardListViewDelegate?
    
    var cardItems = Array<CardItemView>()
    
    var topOffsetConstraints = Array<NSLayoutConstraint>()
    
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
    
    let cardItemOffset = 20
    
    var dynamicAnimator : UIDynamicAnimator?
    
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
            for cardItem in cardItems {
                let itemFrame = cardItem.frame
                if !CGRectIsEmpty(itemFrame) {
                    let cardCenter = cardItem.center
                    let snap = UISnapBehavior(item: cardItem, snapToPoint: cardCenter)
                    snap.damping = 0.9
                    animator.addBehavior(snap)
                    
                    let attachment = UIAttachmentBehavior.slidingAttachmentWithItem(cardItem, attachmentAnchor: cardCenter, axisOfTranslation: CGVectorMake(0,1))
                    animator.addBehavior(attachment)
                    
                }
            }
            let noRotate = UIDynamicItemBehavior(items: cardItems)
            noRotate.allowsRotation = false
            animator.addBehavior(noRotate)
            dynamicAnimator = animator
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
        
        for view in cardItems {
            view.removeFromSuperview()
        }
        cardItems.removeAll()
        topOffsetConstraints.removeAll()

        let leftMargin = 8
        let rightMargin = 8
        
        // temporary colors
        let colors = [UIColor.greenColor(),UIColor.yellowColor(),UIColor.redColor(),UIColor.blueColor()]
        let numberOfItems = delegate.numberOfItemsInCardListView(self)
        cardItems.reserveCapacity(numberOfItems)
        topOffsetConstraints.reserveCapacity(numberOfItems)
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
            
            cardItems.append(itemView)
            topOffsetConstraints.append(topConstraint)
            
            currentOffset += cardItemOffset
            
            let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCardDragGesture))
            dragGesture.maximumNumberOfTouches = 1
            itemView.addGestureRecognizer(dragGesture)
            
            // Apparently UIInterpolatingMotionEffect is not compatible with UIDynamicAnimator
        }
    }
    
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
        case .Ended,.Cancelled:
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