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
    
    func runCardNumberValidation(cardNumber:String,expectedNetwork: CardEntity.NetworkType) {
        let card = CardEntity()
        card.cardNumber = cardNumber
        let expectation = self.expectationWithDescription("validated card number \(cardNumber)")
        card.validate { (error) in
            XCTAssertNil(error)
            XCTAssertEqual(card.networkType, expectedNetwork)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    // Test numbers
    // https://www.paypalobjects.com/en_US/vhelp/paypalmanager_help/credit_card_numbers.htm
    
    func testValidateVisaNumber() {
        runCardNumberValidation("4012888888881881", expectedNetwork: .Visa)
        runCardNumberValidation("4111111111111111", expectedNetwork: .Visa)
    }
    
    func testValidateMasterCardNumber() {
        runCardNumberValidation("5555555555554444", expectedNetwork: .MasterCard)
        runCardNumberValidation("5105105105105100", expectedNetwork: .MasterCard)
    }

}
