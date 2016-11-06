// Card Tray Demo
// Copyright (C) 2016  Sasmito Adibowo – http://cutecoder.org

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import UIKit
import CardTray

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var cardTrayFacade = {
        return CardTrayFacade()
    }()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let showMainCtrl = {
            let cardTrayCtrl = self.cardTrayFacade.mainViewController
            let navCtrl = UINavigationController(rootViewController: cardTrayCtrl)
            
            let window = UIWindow()
            window.backgroundColor = UIColor.white
            window.rootViewController = navCtrl
            window.makeKeyAndVisible()
            self.window = window
        }
        
        let userDefaults = UserDefaults.standard
        let hadWrittenSampleCardsKey = "BSSampleCardsWasWritten"
        if !userDefaults.bool(forKey: hadWrittenSampleCardsKey) {
            // We write sample cards into the list before showing the UI
            
            let cardList = CardListModel()
            cardList.load({
                (errorOrNil) in
                
                // we've attempted a load of the existing card list. 
                // whatever the result is, assume the sample cards was written
                userDefaults.set(true, forKey: hadWrittenSampleCardsKey)
                
                // only actually create cards if we can't load anything
                if cardList.cards?.isEmpty ?? true {
                    // These are "test" card numbers
                    // https://www.paypalobjects.com/en_US/vhelp/paypalmanager_help/credit_card_numbers.htm
                    let sampleCards = [
                        ("4111111111111111",CardEntity.NetworkType.Visa),
                        ("5555555555554444",CardEntity.NetworkType.MasterCard)
                    ]
                    for (cardNumber,cardType) in sampleCards {
                        let card = CardEntity()
                        card.cardNumber = cardNumber
                        card.networkType = cardType
                        cardList.add(card)
                    }
                    cardList.save({ (errorOrNil) in
                        showMainCtrl()
                    })
                } else {
                    showMainCtrl()
                }
            })
        } else {
            showMainCtrl()
        }
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

