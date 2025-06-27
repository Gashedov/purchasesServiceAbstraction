//
//  AdaptyPurchaseService.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import Adapty
import Foundation
import Combine

final class AdaptyPurchaseService: InAppPurchaseService {
    private let productsCache = ProductsCache()

    @MainActor var subscriptionIsActive: Bool = false
    @MainActor private let subscriptionIsActiveSubject = CurrentValueSubject<Bool, Never>(false)
    @MainActor var subscriptionIsActivePublisher: AnyPublisher<Bool, Never> {
        subscriptionIsActiveSubject.eraseToAnyPublisher()
    }
    
    func configure() {
        let configurationBuilder = AdaptyConfiguration
                .builder(withAPIKey: "YOUR_KEY")
                .with(observerMode: false)
                .with(idfaCollectionDisabled: false)
                .with(ipAddressCollectionDisabled: false)
        Adapty.delegate = self
        
        Adapty.activate(with: configurationBuilder.build()) { error in
            print("Adapty activation error: \(error?.localizedDescription ?? "")")
        }
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
    
    @discardableResult
    private func fetchProducts(for placement: InAppPurchaseServicePlacement) async throws -> [AdaptyPaywallProduct] {
        if let products = await productsCache.getProducts(placement), !products.isEmpty {
            return products
        }
        
        let paywall = try await Adapty.getPaywall(
            placementId: placement.key,
            locale: Locale.current.identifier
        )
        
        let products = try await Adapty.getPaywallProducts(paywall: paywall)
        await productsCache.addProducts(products, for: placement)
        return products
    }
    
    func checkSubscriptionStatus() async throws -> Bool {
        let profile = try await Adapty.getProfile()
        let isActive = profile.accessLevels["premium"]?.isActive == true
        await updateSubscriptionIsActive(to: isActive)
        return isActive
    }
    
    func purchaseSubscription(_ product: InAppPurchaseServiceProduct) async throws -> Bool {
        guard let adaptyProduct = await productsCache.getAdaptyProduct(for: product) else { return false }
        let info = try await Adapty.makePurchase(product: adaptyProduct)
        let isActive = info.profile?.accessLevels["premium"]?.isActive ?? false
        await updateSubscriptionIsActive(to: isActive)
        return isActive
    }
    
    func restorePurchases() async throws -> Bool {
        let profile = try await Adapty.restorePurchases()
        let isActive = profile.accessLevels["premium"]?.isActive ?? false
        await updateSubscriptionIsActive(to: isActive)
        return isActive
    }
    
    @MainActor
    private func updateSubscriptionIsActive(to newValue: Bool) {
        subscriptionIsActive = newValue
        subscriptionIsActiveSubject.send(newValue)
    }
}

extension AdaptyPurchaseService: AdaptyDelegate {
    nonisolated func didLoadLatestProfile(_ profile: AdaptyProfile) {
        let isActive = profile.accessLevels["premium"]?.isActive == true
        Task { await MainActor.run { updateSubscriptionIsActive(to: isActive) } }
    }
}

extension AdaptyPurchaseService {
    func addFirebaseInstanceId(_ appInstanceId: String?) async {
        guard let appInstanceId else { return }
        do {
            try await Adapty.setIntegrationIdentifier(
                key: "firebase_app_instance_id",
                value: appInstanceId
            )
        } catch {
            print("Firebase instance identifier did not set: \(error.localizedDescription)")
        }
        
    }
    
    func setUserId(_ id: String) {
        Adapty.identify(id) { error in
            if let error {
                print("User identify error: \(error.localizedDescription)")
            }
        }
    }
}

