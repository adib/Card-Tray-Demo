//
//  CardListModel.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 17/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

public class CardListModel: NSObject {
    
    public override init() {
        
    }
    
    public lazy private(set) var cardListURL : NSURL = {
        let fileManager = NSFileManager.defaultManager()
        let appSupportDir = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).first!
        let cardDir = appSupportDir.URLByAppendingPathComponent("CardTray", isDirectory: true)
        do {
            try fileManager.createDirectoryAtURL(cardDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            
        }
        let cardFile = cardDir.URLByAppendingPathComponent("cards.plist", isDirectory: false)
        return cardFile
    }()

    private(set) var loaded = false
    
    private(set) var dirty = false
    
    @objc private(set) public var cards : Array<CardEntity>?
    
    static func automaticallyNotifiesObserversForCards() -> Bool {
        return true
    }
    
    public func moveToFront(index : Int) {
        guard cards != nil else {
            return
        }
        let card = cards![index]
        cards!.removeAtIndex(index)
        cards!.append(card)
        dirty = true
    }
    
    public func add(card: CardEntity) {
        if cards == nil {
            cards = Array<CardEntity>()
            cards?.reserveCapacity(6)
        }
        cards?.append(card)
        dirty = true
    }
    
    public func remove(cardToRemove:CardEntity?) -> Int? {
        if let  card = cardToRemove,
                index = cards?.indexOf(card) {
            cards?.removeAtIndex(index)
            dirty = true
            return index
        }
        return nil
    }
    
    
    
    public func load(completionHandler: ((NSError?)->Void)? ) {
        let targetURL = self.cardListURL
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            var returnError : NSError?
            var resultArray : Array<CardEntity>?
            defer {
                dispatch_async(dispatch_get_main_queue(), {
                    if returnError == nil && resultArray != nil {
                        // TODO: raise KVO?
                        self.cards = resultArray
                        self.loaded = true
                        self.dirty = false
                    }
                    
                    completionHandler?(returnError)
                })
            }
            do {
                let data = try NSData(contentsOfURL: targetURL, options: [.DataReadingMappedIfSafe,.DataReadingUncached])
                if let array = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? Array<CardEntity> {
                    resultArray = array
                }
            } catch let error as NSError {
                returnError = error
            }
        }
    }
    
    public func save(completionHandler: ((NSError?)->Void)? ) {
        guard dirty else {
            // not dirty.
            completionHandler?(nil)
            return
        }
        guard let cards = self.cards else {
            // todo: create error?
            completionHandler?(nil)
            return
        }
        let archivedData = NSKeyedArchiver.archivedDataWithRootObject(cards)
        let targetURL = self.cardListURL
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            var returnError : NSError?
            defer {
                dispatch_async(dispatch_get_main_queue(), {
                    if returnError == nil {
                        self.dirty = false
                    }
                    completionHandler?(returnError)
                })
            }
            do {
                try archivedData.writeToURL(targetURL, options: [.DataWritingAtomic,.DataWritingFileProtectionComplete])
                // In addition to passcode lock, we need to also prevent iTunes from creating a backup of the
                // card tray data. If the user doesn't set a passcode to those backups, then they are stored in the clear,
                // making it possible for malicious applications on the desktop to extract credit card numbers.
                try targetURL.setResourceValue(NSNumber(bool:true), forKey: NSURLIsExcludedFromBackupKey)
            } catch let error as NSError {
                returnError = error
            }
        }
    }
}
