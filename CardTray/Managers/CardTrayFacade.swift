//
//  CardTrayFacade.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 11/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

public class CardTrayFacade: NSObject {
    public lazy private(set) var  mainViewController : UIViewController = {
       [unowned self] in
        let bundle = NSBundle(forClass: self.dynamicType)
        let storyboard = UIStoryboard(name: "CardManagement", bundle: bundle)
        let ctrl = storyboard.instantiateInitialViewController()
        return ctrl!
    }()
}
