//
//  CardEntity.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 15/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardEntity: NSObject,NSCoding {
    
    static let ErrorDomain = "CardEntityErrorDomain"
    
    enum ErrorCode : Int {
        case None = 0
        case CardNumberChecksumFailed = 1
    }
    
    enum NetworkType : String {
        case Unknown = ""
        case Visa = "visa"
        case MasterCard = "mastercard"
    }
    
    var cardNumber : String?
    
    var cardholderName : String?
    
    var securityCode : String?
    
    var expiryDayOfMonth : Int?
    
    var expiryYear : Int?
    
    var networkType = NetworkType.Unknown
    
    override init() {
        // empty
    }
    
    // MARK: - NSCoding
    
    required init(coder aDecoder: NSCoder) {
        let decodeInt = {
            (key:String) -> Int? in
            if let num = aDecoder.decodeObjectForKey(key) as? NSNumber {
                return Int(num.intValue)
            }
            return nil
        }
        cardNumber = aDecoder.decodeObjectForKey("cardNumber") as? String
        cardholderName = aDecoder.decodeObjectForKey("cardholderName") as? String
        securityCode = aDecoder.decodeObjectForKey("securityCode") as? String
        expiryDayOfMonth = decodeInt("expiryDayOfMonth")
        expiryYear = decodeInt("expiryYear")
        networkType = NetworkType(rawValue:aDecoder.decodeObjectForKey("networkType") as? String ?? "") ?? .Unknown
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        let encodeInt = {
            (v:Int?,key:String) in
            if let value = v {
                aCoder.encodeInt(Int32(value), forKey: key)
            }
        }
        aCoder.encodeObject(cardNumber, forKey: "cardNumber")
        aCoder.encodeObject(cardholderName, forKey: "cardholderName")
        aCoder.encodeObject(securityCode, forKey: "securityCode")
        encodeInt(expiryDayOfMonth,"expiryDayOfMonth")
        encodeInt(expiryYear,"expiryYear")
        aCoder.encodeObject(networkType.rawValue, forKey: "networkType")
    }

    /**
     Validates the card details and modifies the entity data accordingly.
     This function may eventually call the network, hence has an asynchronous style signature.
    */
    func validate(completionHandler: ((error : NSError?)->Void)? ) {
        guard   let cardNumber = self.cardNumber where
                    LuhnChecksum(cardNumber) else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Card number checksum failure", comment: "Validation error")
            ]
            let error = NSError(domain: CardEntity.ErrorDomain, code: CardEntity.ErrorCode.CardNumberChecksumFailed.rawValue, userInfo: userInfo)
            completionHandler?(error: error)
            return
        }
        
        // Card number structure from Wikipedia
        // https://en.wikipedia.org/wiki/Payment_card_number#Issuer_identification_number_.28IIN.29
        
        let characters = cardNumber.characters
        let numberLen = characters.count
        

        let validators : [(()->Bool,NetworkType)] = [
            // visa
            ({return (numberLen == 13 || numberLen == 16 || numberLen == 19) && cardNumber.hasPrefix("4")
            },.Visa),
            // mastercard check
            ({
                return numberLen == 16 && (2221...2720 ~= Int(String(characters.prefix(4))) ?? 0  || 51...55 ~= Int(String(characters.prefix(2))) ?? 0  )
            },.MasterCard)
        ]
        
        for (v,type) in validators {
            if v() {
                self.networkType = type
                break
            }
        }
        completionHandler?(error: nil)
    }
}


func LuhnChecksum(cardNumber:String) -> Bool {
    // https://en.wikipedia.org/wiki/Luhn_algorithm
    
    var sum = 0
    let reversedCharacters = cardNumber.characters.reverse().map { String($0) }
    for (idx, element) in reversedCharacters.enumerate() {
        guard let digit = Int(element) else { return false }
        switch ((idx % 2 == 1), digit) {
            case (true, 9): sum += 9
            case (true, 0...8): sum += (digit * 2) % 9
            default: sum += digit
        }
    }
    return sum % 10 == 0
}