//
//  MonthYearPickerController.swift
//  CardTrayDemo
//
//  Created by Sasmito Adibowo on 16/6/16.
//  Copyright © 2016 Basil Salad Software. All rights reserved.
//

import UIKit

/**
 Picker controller for card expiration dates.
 This doesn't use the locale's date/time formats but assumes a fixed format.
 
 http://baymard.com/blog/how-to-format-expiration-date-fields
 */
class CardExpirationPickerController: UIResponder,UIPickerViewDataSource,UIPickerViewDelegate {

    @IBOutlet var pickerView:UIPickerView? {
        willSet {
            if let oldPicker = pickerView {
                oldPicker.dataSource = nil
                oldPicker.delegate = nil
            }
        }
        didSet {
            if let pv = pickerView {
                pv.dataSource = self
                pv.delegate = self
            }
        }
    }
    
    @IBOutlet var textField : UITextField? {
        willSet {
            if let tf = textField {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: tf)
            }
        }
        didSet {
            if let tf = textField {
                NSNotificationCenter.defaultCenter().addObserver(self,selector:#selector(textFieldDidChange), name: UITextFieldTextDidChangeNotification, object: tf)
            }
        }
    }
    
    private(set) lazy var calendar : NSCalendar = {
        // force the use of ISO calendar for credit card date formats
        // http://baymard.com/blog/how-to-format-expiration-date-fields
        return NSCalendar(identifier:NSCalendarIdentifierISO8601)!
    }()

    lazy var yearLookup : [(String,Int?)] = {
        [unowned self] in
        var l = Array<(String,Int?)>()
        l.append(("",nil))
        let yearRange = self.yearRange
        for year in yearRange.location..<yearRange.location+yearRange.length {
            l.append((String(format:"%04d",year),year))
        }
        return l
    }()
    
    lazy var monthLookup : [(String,Int?)] = {
        var l = Array<(String,Int?)>()
        l.append(("",nil))
        for month in 1...12 {
            l.append((String(format:"%02d",month),month))
        }
        return l
    }()
    
    lazy var yearRange : NSRange = {
        let calendar = self.calendar
        let currentDate = NSDate()
        var year = Int(0)
        calendar.getEra(nil,year:&year,month:nil,day:nil,fromDate:currentDate)
        // assume 20 year max like what Amazon is doing
        // http://stackoverflow.com/a/8536863
        let range = NSMakeRange(year, 20)
        return range
    }()
    
    private(set) lazy var dateTextFormatter : NSDateFormatter = {
        let f = NSDateFormatter()
        f.calendar = self.calendar
        f.dateFormat = "MM/yy"
        return f
    }()
    
    private(set) var selectedMonth : Int?
    
    private(set) var selectedYear : Int?
    
    deinit {
        self.textField = nil
        self.pickerView = nil
    }

    func viewDidLoad() {
        if let textField = self.textField {
            textField.inputView = self.pickerView
        }
    }
    
    func setSelectedMonth(month: Int?,year: Int?, animated: Bool) {
        if let m = month where 1...12 ~= m && selectedMonth != m  {
            selectedMonth = m
            if let pickerView = self.pickerView {
                var monthIndex : Int?
                for i in 0..<monthLookup.count {
                    if monthLookup[i].1 == m {
                        monthIndex = i
                        break
                    }
                }
                
                if let selectedMonthIndex = monthIndex {
                    pickerView.selectRow(selectedMonthIndex, inComponent: 0, animated: animated)
                }
            }
        }
        
        if let y = year where y > 0 && selectedYear != y {
            selectedYear = year
            if let pickerView = self.pickerView {
                var yearIndex : Int?
                for i in 0..<yearLookup.count {
                    if yearLookup[i].1 == y {
                        yearIndex = i
                        break
                    }
                }
                
                // year not found, insert it.
                if yearIndex == nil {
                    yearIndex = 0
                    yearLookup.insert((String(format:"%04d",y),y), atIndex: yearIndex!)
                    pickerView.reloadComponent(1)
                }
                pickerView.selectRow(yearIndex!, inComponent: 1, animated: animated)
            }
        }
    }
    
    
    func setSelectedText(userText:String,animated:Bool) -> Bool {
        var objectValue : AnyObject?
        if self.dateTextFormatter.getObjectValue(&objectValue, forString: userText, errorDescription: nil) {
            if let dateValue = objectValue as? NSDate {
                let dateComponents = self.calendar.components([.Month,.Year], fromDate: dateValue)
                if dateComponents.year >= yearRange.location {
                    setSelectedMonth(dateComponents.month, year: dateComponents.year, animated: animated)
                    return true
                }
            }
        }
        return false
    }
    
    var selectedText : String? {
        get {
            guard let   selectedMonth = self.selectedMonth,
                selectedYear  = self.selectedYear else {
                    return nil
            }
            let calendar = self.calendar
            let comps = NSDateComponents()
            comps.calendar = calendar
            comps.month = selectedMonth
            comps.year = selectedYear
            if let date = calendar.dateFromComponents(comps) {
                return self.dateTextFormatter.stringFromDate(date)
            }
            return nil
        }
    }
    
    func setNeedsReadText() {
        let sel = #selector(readText)
        NSObject.cancelPreviousPerformRequestsWithTarget(self,selector:sel,object:nil)
        self.performSelector(sel,withObject:nil,afterDelay:0.2)
        
    }
    
    func readText() {
        guard let   textField = self.textField,
                    text = textField.text else {
            return
        }
        self.setSelectedText(text,animated:true)
    }
    
    func setNeedsWriteText() {
        let sel = #selector(writeText)
        NSObject.cancelPreviousPerformRequestsWithTarget(self,selector:sel,object:nil)
        self.performSelector(sel,withObject:nil,afterDelay:0.2)
    }
    
    func writeText() {
        guard let   textField = self.textField,
                    text = self.selectedText else {
                return
        }
        textField.text = text
    }
    
    // MARK: - Handlers
    
    func textFieldDidChange(notification:NSNotification) {
        setNeedsReadText()
    }
    
    // MARK: - UIPickerViewDataSource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        // month and year
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            // month
            return monthLookup.count
        case 1:
            // year
            return yearLookup.count
        default:
            return 0
        }
    }
    
    // MARK: UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            // month
            return monthLookup[row].0
        case 1:
            // year
            return yearLookup[row].0
        default:
            return ""
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: //month
            let (_,selMonth) = monthLookup[row]
            selectedMonth = selMonth
            setNeedsWriteText()
        case 1: // year
            let (_,year) = yearLookup[row]
            selectedYear = year
            setNeedsWriteText()
        default: ()
        }
    }
}
