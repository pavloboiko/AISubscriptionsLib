//
//  File.swift
//  PurchaseClientDemo
//
//  Created by Serjant Alexandru on 3/29/21.
//

import Foundation

enum LogSource {
    case api
    case device
    case bonus
    case info
    case storage
    case user
    case migration
    case purchase
    case network
    case myAccount
    case consumables
    
    var prefix: String {
        switch self {
        case .api:
            return "API SERVICE"
        case .device:
            return "DEVICE SERVICE"
        case .bonus:
            return "BONUS SERVICE"
        case .info:
            return "INFO SERVICE"
        case .storage:
            return "STORAGE SERVICE"
        case .user:
            return "USER SERVICE"
        case .migration:
            return "MIGRATION SERVICE"
        case .purchase:
            return "PURCHASE SERVICE"
        case .network:
            return "NETWORK"
        case .myAccount:
            return "MyAcc Model"
        case .consumables:
            return "CONSUMABLES"
        }
        return "AILibs"
    }
    
}

public enum LogLevel {
    case none, info, description, error, debug
    
    var access: [LogLevel] {
        switch self {
        case .none:
            return []
        case .info:
            return [.info, .description, .error, .debug]
        case .description:
            return [.description, .error, .debug]
        case .error:
            return [.error, .debug]
        case .debug:
            return [.debug]
        }
    }
    
}

class CLog {
    
    static let shared = CLog()

    var level: LogLevel = .none
    
    var metric: AppMetricProtocol?
    
    static func print(_ level: LogLevel, _ type: LogSource, _ messages: Any...) {
        if level.access.contains(CLog.shared.level) {
            Swift.print("[AILib][\(type.prefix)]", messages.map { String(describing: $0) }.joined(separator: " "))
        }
    }
    
}
