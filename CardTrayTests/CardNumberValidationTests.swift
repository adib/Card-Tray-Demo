//
//  CardNumberValidationTests.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 15/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import XCTest
@testable import CardTray

class CardNumberValidationTests: XCTestCase {
    
    // Test numbers
    // https://www.paypalobjects.com/en_US/vhelp/paypalmanager_help/credit_card_numbers.htm
    
    
    
    func runCardNumberValidation(cardNumber:String,expectedIssuer: CardEntity.IssuerType) {
        let card = CardEntity()
        card.cardNumber = cardNumber
        let expectation = self.expectationWithDescription("validated card number \(cardNumber)")
        card.validate { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(card.issuer, expectedIssuer)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    

    func testValidateVisaNumber() {
        runCardNumberValidation("4012888888881881", expectedIssuer: .Visa)
        runCardNumberValidation("4111111111111111", expectedIssuer: .Visa)
    }
    
    func testValidateMasterCardNumber() {
        runCardNumberValidation("5555555555554444", expectedIssuer: .MasterCard)
        runCardNumberValidation("5105105105105100", expectedIssuer: .MasterCard)
    }

}
