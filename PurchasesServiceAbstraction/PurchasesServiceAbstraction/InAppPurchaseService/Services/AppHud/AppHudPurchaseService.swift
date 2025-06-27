//
//  AppHudPurchaseService.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import StoreKit
import Combine
import ApphudSDK

final class AppHudPurchaseService: InAppPurchaseService {
    private let productsCache = ProductsCache()

    @MainActor var subscriptionIsActive: Bool = false
    @MainActor private let subscriptionIsActiveSubject = CurrentValueSubject<Bool, Never>(false)
    @MainActor var subscriptionIsActivePublisher: AnyPublisher<Bool, Never> {
        subscriptionIsActiveSubject.eraseToAnyPublisher()
    }
    
    func configure() {
        Apphud.start(apiKey: "YOUR_KEY")
        Apphud.setDelegate(self)
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
    
    func restorePurchases() async throws -> Bool {
        let error = await Apphud.restorePurchases()
        return try await checkSubscriptionStatus()
    }
    
    func purchaseSubscription(_ product: InAppPurchaseServiceProduct) async throws -> Bool {
        guard let apphudProduct = await productsCache.getAppHudProduct(for: product) else { return false }
        let result = await Apphud.purchase(apphudProduct)
        return try await checkSubscriptionStatus()
    }
    
    func checkSubscriptionStatus() async throws -> Bool {
        let subscription = await Apphud.subscription()
        let nonRenewingPurchases = await Apphud.nonRenewingPurchases()
        let isActive = subscription?.isActive() == true ||
        nonRenewingPurchases?.contains(where: { $0.isActive() }) == true
        await MainActor.run {
            updateSubscriptionIsActive(to: isActive)
        }

        return isActive
    }
    
    @MainActor
    private func updateSubscriptionIsActive(to newValue: Bool) {
        subscriptionIsActive = newValue
        subscriptionIsActiveSubject.send(newValue)
    }
    
    @discardableResult
    private func fetchProducts(for placement: InAppPurchaseServicePlacement) async throws -> [ApphudProduct] {
        if let products = await productsCache.getProducts(placement), !products.isEmpty {
            return products
        }
        
        let apphudPlacement = await Apphud.placement(placement.key)
        let products = apphudPlacement?.paywall?.products ?? []
        await productsCache.addProducts(products, for: placement)
        return products
    }
}

extension AppHudPurchaseService: ApphudDelegate {
    func apphudSubscriptionsUpdated(_ subscriptions: [ApphudSubscription]) {
        for subscription in subscriptions {
            if subscription.isActive() {
                Task { await MainActor.run { updateSubscriptionIsActive(to: true) } }
                return
            }
        }
        Task { await MainActor.run { updateSubscriptionIsActive(to: false) } }
    }
}

