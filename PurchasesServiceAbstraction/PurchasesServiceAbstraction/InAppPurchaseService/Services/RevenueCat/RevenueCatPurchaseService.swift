//
//  RevenueCatPurchaseService.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import Combine
import AdSupport
import UIKit
import RevenueCat

final class RevenueCatPurchaseService: InAppPurchaseService {
    private let productsCache = ProductsCache()
    
    @MainActor var subscriptionIsActive: Bool = false
    @MainActor private let subscriptionIsActiveSubject = CurrentValueSubject<Bool, Never>(false)
    @MainActor var subscriptionIsActivePublisher: AnyPublisher<Bool, Never> {
        subscriptionIsActiveSubject.eraseToAnyPublisher()
    }
    
    func configure() {
#if DEBUG
        Purchases.logLevel = .debug
#endif
        Purchases.configure(withAPIKey: "YOUR_KEY")
    }
    
    func products() async throws -> [InAppPurchaseServiceProduct] {
        for placement in InAppPurchaseServicePlacement.allCases {
            if let cachedProducts = await productsCache.getProducts(placement), !cachedProducts.isEmpty {
                continue
            } else {
                try await fetchProducts(for: placement)
            }
        }
        return await productsCache.getServiceProducts()
    }
    
    func products(for placement: InAppPurchaseServicePlacement) async throws -> [InAppPurchaseServiceProduct] {
        let cachedProducts = await productsCache.getServiceProducts(for: placement)
        if !cachedProducts.isEmpty {
            return cachedProducts
        } else {
            try await fetchProducts(for: placement)
            return await productsCache.getServiceProducts(for: placement)
        }
    }
    
    func purchaseSubscription(_ product: InAppPurchaseServiceProduct) async throws -> Bool {
        guard let package = await productsCache.getRevenueCatProduct(for: product) else { return false }
        let purchaseData = try await Purchases.shared.purchase(package: package)
        return await verifyStoreSubscriptionInfo(customerInfo: purchaseData.customerInfo)
    }
    
    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        return await verifyStoreSubscriptionInfo(customerInfo: customerInfo)
    }
    
    func checkSubscriptionStatus() async throws -> Bool {
        let customerInfo = try await Purchases.shared.customerInfo()
        return await verifyStoreSubscriptionInfo(customerInfo: customerInfo)
    }
    
    @discardableResult
    private func fetchProducts(for placement: InAppPurchaseServicePlacement) async throws -> [Package] {
        if let products = await productsCache.getProducts(placement), !products.isEmpty {
            return products
        }
        
        var offerings: Offerings
        if let cached = Purchases.shared.cachedOfferings {
            offerings = cached
        } else {
            offerings = try await Purchases.shared.offerings()
        }
        let offering = offerings.currentOffering(forPlacement: placement.key)
        let products = offering?.availablePackages ?? []
        await productsCache.addProducts(products, for: placement)
        return products
    }
    
    @MainActor @discardableResult
    private func verifyStoreSubscriptionInfo(
        customerInfo: CustomerInfo?,
        error: Error? = nil
    ) -> Bool {
        if let error {
            print("error occured: \(error.localizedDescription)")
            return false
        }
        
        let isSubscribed = customerInfo?.entitlements.active.isEmpty == false
        subscriptionIsActive = isSubscribed
        subscriptionIsActiveSubject.send(isSubscribed)
        return isSubscribed
    }
    
    func enableAdServicesAttributionTokenCollection() {
        Purchases.shared.attribution.enableAdServicesAttributionTokenCollection()
    }
    
    func setAdjustId(_ id: String) {
        Purchases.shared.attribution.setAdjustID(id)
    }
    
    func collectDeviceIdentifiers() {
        Purchases.shared.attribution.collectDeviceIdentifiers()
    }
    
    func setDeviceIdentifiers(idfa: String?, idfv: String?) {
        if let idfa, idfa != "00000000-0000-0000-0000-000000000000" {
            Purchases.shared.attribution.setAttributes(["$idfa": idfa])
        }
    }
    
    func sendIP(_ ip: String?) {
        if let ip {
            Purchases.shared.attribution.setAttributes(["$ip": ip])
        }
    }
}
