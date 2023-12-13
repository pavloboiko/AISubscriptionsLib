//
//  NotificationsName.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/8/21.
//

import Foundation

enum PurchaseNotification: String {

    case validateReceipt = "Notification.Key.validateReceipt"
    case validateReceiptError = "Notification.Key.validateReceiptError"
    case restore = "Notification.Key.restore"
    case purchase = "Notification.Key.purchase"

    var name : Notification.Name  {
        return Notification.Name(rawValue: self.rawValue )
    }
    
}

extension PurchaseNotification {
    func post(_ object: Any? = nil) {
        NotificationCenter.default.post(Notification(name: self.name,
                                                     object: object,
                                                     userInfo: [:]))
    }
}
