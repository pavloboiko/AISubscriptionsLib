//
//  PurchaseType.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/3/21.
//

import Foundation

public enum PurchaseType: String, Codable {
    case renewable = "AR"
    case nonRenewable = "NR"
    case consumable = "C"
    case nonConsumable = "NC"
}


