//
//  CardTrayFacade.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

open class CardTrayFacade: NSObject {
    open lazy fileprivate(set) var  mainViewController : UIViewController = {
       [unowned self] in
        let bundle = Bundle(for: type(of: self))
        let storyboard = UIStoryboard(name: "CardManagement", bundle: bundle)
        let ctrl = storyboard.instantiateInitialViewController()
        return ctrl!
    }()
}
