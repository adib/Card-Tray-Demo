//
//  CardTransactionListViewController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 14/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

class CardTransactionListViewController: UITableViewController {

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("transactionItemCell", forIndexPath: indexPath)
        return cell
    }

}
