//
//  Date+Extensions.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/4/21.
//

import Foundation

extension Date {
 
    func string(_ format: DateFormatter.Style = .short) -> String {
        let formater = DateFormatter()
        formater.dateStyle = format
        formater.timeStyle = format
        return formater.string(from: self)
    }
    
    var zeroSeconds: Date? {
        let calendar = Foundation.Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: dateComponents)
    }
}
