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
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UITextFieldTextDidChange, object: tf)
            }
        }
        didSet {
            if let tf = textField {
                NotificationCenter.default.addObserver(self,selector:#selector(textFieldDidChange), name: NSNotification.Name.UITextFieldTextDidChange, object: tf)
            }
        }
    }
    
    fileprivate(set) lazy var calendar : Calendar = {
        // force the use of ISO calendar for credit card date formats
        // http://baymard.com/blog/how-to-format-expiration-date-fields
        return Calendar(identifier:Calendar.Identifier.iso8601)
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
        let currentDate = Date()
        var year = Int(0)
        (calendar as NSCalendar).getEra(nil,year:&year,month:nil,day:nil,from:currentDate)
        // assume 20 year max like what Amazon is doing
        // http://stackoverflow.com/a/8536863
        let range = NSMakeRange(year, 20)
        return range
    }()
    
    fileprivate(set) lazy var dateTextFormatter : DateFormatter = {
        let f = DateFormatter()
        f.calendar = self.calendar
        f.dateFormat = "MM/yy"
        return f
    }()
    
    fileprivate(set) var selectedMonth : Int?
    
    fileprivate(set) var selectedYear : Int?
    
    deinit {
        self.textField = nil
        self.pickerView = nil
    }

    func viewDidLoad() {
        if let textField = self.textField {
            textField.inputView = self.pickerView
        }
    }
    
    func setSelectedMonth(_ month: Int?,year: Int?, animated: Bool) {
        if let m = month, 1...12 ~= m && selectedMonth != m  {
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
        
        if let y = year, y > 0 && selectedYear != y {
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
                    yearLookup.insert((String(format:"%04d",y),y), at: yearIndex!)
                    pickerView.reloadComponent(1)
                }
                pickerView.selectRow(yearIndex!, inComponent: 1, animated: animated)
            }
        }
    }
    
    @discardableResult
    func setSelectedText(_ userText:String,animated:Bool) -> Bool {
        var objectValue : AnyObject?
        if self.dateTextFormatter.getObjectValue(&objectValue, for: userText, errorDescription: nil) {
            if let dateValue = objectValue as? Date {
                let dateComponents = (self.calendar as NSCalendar).components([.month,.year], from: dateValue)
                if dateComponents.year! >= yearRange.location {
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
                let selectedYear  = self.selectedYear else {
                    return nil
            }
            let calendar = self.calendar
            var comps = DateComponents()
            (comps as NSDateComponents).calendar = calendar
            comps.month = selectedMonth
            comps.year = selectedYear
            if let date = calendar.date(from: comps) {
                return self.dateTextFormatter.string(from: date)
            }
            return nil
        }
    }
    
    func setNeedsReadText() {
        let sel = #selector(readText)
        NSObject.cancelPreviousPerformRequests(withTarget: self,selector:sel,object:nil)
        self.perform(sel,with:nil,afterDelay:0.2)
        
    }
    
    func readText() {
        guard let   textField = self.textField,
                    let text = textField.text else {
            return
        }
        self.setSelectedText(text,animated:true)
    }
    
    func setNeedsWriteText() {
        let sel = #selector(writeText)
        NSObject.cancelPreviousPerformRequests(withTarget: self,selector:sel,object:nil)
        self.perform(sel,with:nil,afterDelay:0.2)
    }
    
    func writeText() {
        guard let   textField = self.textField,
                    let text = self.selectedText else {
                return
        }
        textField.text = text
    }
    
    // MARK: - Handlers
    
    func textFieldDidChange(_ notification:Notification) {
        setNeedsReadText()
    }
    
    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // month and year
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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
