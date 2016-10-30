//
//  CardEntity.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 15/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//  http://basilsalad.com

import UIKit

open class CardEntity: NSObject,NSCoding {
    
    static let ErrorDomain = "CardEntityErrorDomain"
    
    public enum ErrorCode : Int {
        case none = 0
        case cardNumberChecksumFailed = 1
    }
    
    public enum NetworkType : String {
        case Unknown = ""
        case Visa = "visa"
        case MasterCard = "mastercard"
    }
    
    open var cardNumber : String?
    
    open var cardholderName : String?
    
    open var securityCode : String?
    
    open var expiryDayOfMonth : Int?
    
    open var expiryYear : Int?
    
    open var networkType = NetworkType.Unknown
    
    open var obfuscatedCardNumber : String? {
        get {
            if let cardNumber = self.cardNumber {
                let displayNumbers = String(cardNumber.characters.suffix(4))
                return "••••\u{2007}\(displayNumbers)"
            } else {
                return nil
            }
        }
    }
    
    public override init() {
        // empty
    }
    
    // MARK: - NSCoding
    
    public required init(coder aDecoder: NSCoder) {
        let decodeInt = {
            (key:String) -> Int? in
            if let num = aDecoder.decodeObject(forKey: key) as? NSNumber {
                return Int(num.int32Value)
            }
            return nil
        }
        cardNumber = aDecoder.decodeObject(forKey: "cardNumber") as? String
        cardholderName = aDecoder.decodeObject(forKey: "cardholderName") as? String
        securityCode = aDecoder.decodeObject(forKey: "securityCode") as? String
        expiryDayOfMonth = decodeInt("expiryDayOfMonth")
        expiryYear = decodeInt("expiryYear")
        networkType = NetworkType(rawValue:aDecoder.decodeObject(forKey: "networkType") as? String ?? "") ?? .Unknown
    }
    
    open func encode(with aCoder: NSCoder) {
        let encodeInt = {
            (v:Int?,key:String) in
            if let value = v {
                aCoder.encodeCInt(Int32(value), forKey: key)
            }
        }
        aCoder.encode(cardNumber, forKey: "cardNumber")
        aCoder.encode(cardholderName, forKey: "cardholderName")
        aCoder.encode(securityCode, forKey: "securityCode")
        encodeInt(expiryDayOfMonth,"expiryDayOfMonth")
        encodeInt(expiryYear,"expiryYear")
        aCoder.encode(networkType.rawValue, forKey: "networkType")
    }

    /**
     Validates the card details and modifies the entity data accordingly.
     This function may eventually call the network, hence has an asynchronous style signature.
    */
    open func validate(_ completionHandler: ((_ error : NSError?)->Void)? ) {
        guard   let cardNumber = self.cardNumber,
                    LuhnChecksum(cardNumber) else {
            let userInfo = [
                NSLocalizedDescriptionKey: NSLocalizedString("Card number checksum failure", comment: "Validation error")
            ]
            let error = NSError(domain: CardEntity.ErrorDomain, code: CardEntity.ErrorCode.cardNumberChecksumFailed.rawValue, userInfo: userInfo)
            completionHandler?(error)
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
        completionHandler?(nil)
    }
}


@objc public protocol CardEntityHolder {
    
    // We can't make this property optional because Swift 2.2 would choke on it.
    // http://stackoverflow.com/a/26083681/199360
    var card : CardEntity? { get set }
}


func LuhnChecksum(_ cardNumber:String) -> Bool {
    // https://en.wikipedia.org/wiki/Luhn_algorithm
    
    var sum = 0
    let reversedCharacters = cardNumber.characters.reversed().map { String($0) }
    for (idx, element) in reversedCharacters.enumerated() {
        guard let digit = Int(element) else { return false }
        switch ((idx % 2 == 1), digit) {
            case (true, 9): sum += 9
            case (true, 0...8): sum += (digit * 2) % 9
            default: sum += digit
        }
    }
    return sum % 10 == 0
}
