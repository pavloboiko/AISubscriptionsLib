//
//  ServicesContainer.swift
//  PurchaseClient
//
//  Created by Serjant Alexandru on 2/9/21.
//

import Foundation

struct ServicesContainer {
        
    var storage: StorageServiceProtocol
    var device: DeviceServiceProtocol
    var user: UserServiceProtocol
    var apiManager: APIServiceProtocol
    var purchase: PurchaseService
    var bonus: BonusServiceProtocol
    var consumables: ConsumableServiceProtocol
    var appInfo: AppInfoProtocol & AppInfoServiceProtocol
    var migrate: MigrationServiceProtocol
    static func builder() -> ServicesContainer {
        let storageService = StorageService()
        let apiManager = APIService(storage: storageService)
        let deviceService = DeviceService(apiManager: apiManager, storage: storageService)
        let userService = UserService(apiManager: apiManager, storage: storageService)
        let purchaseService = PurchaseService(apiService: apiManager, storage: storageService)
        let bonusService = BonusService(apiService: apiManager, storage: storageService)
        let consumables = ConsumableService(apiService: apiManager, storage: storageService)
        let appInfoService = AppInfoService(apiService: apiManager, storage: storageService)
        let migrateService = MigrationService(apiService: apiManager, storage: storageService)
        
        return ServicesContainer(storage: storageService,
                                 device: deviceService,
                                 user: userService,
                                 apiManager: apiManager,
                                 purchase: purchaseService,
                                 bonus: bonusService,
                                 consumables: consumables,
                                 appInfo: appInfoService,
                                 migrate: migrateService)
        
    }
    
}
