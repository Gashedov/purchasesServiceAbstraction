//
//  InAppPurchaseService.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import Foundation
import Combine

protocol InAppPurchaseService: AnyObject {
    var subscriptionIsActive: Bool { get }
    var subscriptionIsActivePublisher: AnyPublisher<Bool, Never> { get }
    
    @MainActor
    func configure()
    
    func restorePurchases() async throws -> Bool
    func purchaseSubscription(_ product: InAppPurchaseServiceProduct) async throws -> Bool
    func products() async throws -> [InAppPurchaseServiceProduct]
    func products(for placement: InAppPurchaseServicePlacement) async throws -> [InAppPurchaseServiceProduct]
    func checkSubscriptionStatus() async throws -> Bool
    
    func enableAdServicesAttributionTokenCollection()
    func setDeviceIdentifiers(idfa: String?, idfv: String?)
    func addFirebaseInstanceId(_: String?) async
    func setUserId(_: String)
    func sendIP(_ ip: String?)
}

extension InAppPurchaseService {
    func enableAdServicesAttributionTokenCollection() {}
    func setDeviceIdentifiers(idfa: String?, idfv: String?) {}
    func addFirebaseInstanceId(_: String?) async {}
    func setUserId(_: String) {}
    func sendIP(_ ip: String?) {}
}
