//
//  ProductsCache.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import RevenueCat
import Foundation

extension RevenueCatPurchaseService {
    actor ProductsCache {
        private var placementsProducts: [InAppPurchaseServicePlacement: [Package]] = [:]
        private var serviceProducts: [InAppPurchaseServicePlacement: [InAppPurchaseServiceProduct]] = [:]
        
        func addProducts(_ products: [Package], for placement: InAppPurchaseServicePlacement) {
            placementsProducts[placement] = products
            serviceProducts[placement] = products.map { parseRevenueCatPackage($0) }
        }
        
        func updatePlacements(_ newPlacements: [InAppPurchaseServicePlacement: [Package]]) {
            placementsProducts = newPlacements
        }
        
        func getProducts(_ placement: InAppPurchaseServicePlacement) -> [Package]? {
            placementsProducts[placement]
        }
        
        func getPlacements() -> [InAppPurchaseServicePlacement: [Package]] {
            placementsProducts
        }
        
        func getServiceProducts() -> [InAppPurchaseServiceProduct] {
            var result: [InAppPurchaseServiceProduct] = []
            for placement in InAppPurchaseServicePlacement.allCases {
                result += serviceProducts[placement] ?? []
            }
            return result
        }
        
        func getServiceProducts(for placement: InAppPurchaseServicePlacement) -> [InAppPurchaseServiceProduct] {
            serviceProducts[placement] ?? []
        }
        
        func getServiceProduct(for package: Package) -> InAppPurchaseServiceProduct? {
            let productId = package.storeProduct.productIdentifier
            for placement in InAppPurchaseServicePlacement.allCases {
                if let product = serviceProducts[placement]?.first(where: { $0.id == productId }) {
                    return product
                }
            }
            return nil
        }
        
        func getRevenueCatProduct(for serviceProduct: InAppPurchaseServiceProduct) -> Package? {
            for placement in InAppPurchaseServicePlacement.allCases {
                if let product = placementsProducts[placement]?.first(where: { $0.storeProduct.productIdentifier == serviceProduct.id }) {
                    return product
                }
            }
            return nil
        }
    }
}

extension RevenueCatPurchaseService.ProductsCache {
    func parseRevenueCatPackage(
        _ package: Package
    ) -> InAppPurchaseServiceProduct {
        let storeProduct = package.storeProduct
        
        let introductoryDiscount: InAppPurchaseServiceProduct.IntroductoryDiscount? = {
            guard let intro = storeProduct.introductoryDiscount else { return nil }
            return InAppPurchaseServiceProduct.IntroductoryDiscount(
                subscriptionPeriod: parseSubscriptionPeriod(intro.subscriptionPeriod),
                paymentMode: parsePaymentMode(intro.paymentMode)
            )
        }()
        
        let priceFormatter = makePriceFormatter(
            locale: storeProduct.priceFormatter?.locale ?? Locale.current,
            currencyCode: storeProduct.currencyCode
        )
        
        return InAppPurchaseServiceProduct(
            id: storeProduct.productIdentifier,
            price: storeProduct.price as Decimal,
            localizedPriceString: storeProduct.localizedPriceString,
            priceFormatter: priceFormatter,
            subscriptionPeriod: storeProduct.subscriptionPeriod.map(parseSubscriptionPeriod),
            introductoryDiscount: introductoryDiscount
        )
    }

    // MARK: - Helper Parsers

    private func parseSubscriptionPeriod(
        _ period: SubscriptionPeriod
    ) -> InAppPurchaseServiceProduct.SubscriptionPeriod {
        return .init(
            unit: parseSubscriptionPeriodUnit(period.unit),
            value: period.value
        )
    }

    private func parseSubscriptionPeriodUnit(
        _ unit: SubscriptionPeriod.Unit
    ) -> InAppPurchaseServiceProduct.SubscriptionPeriod.Unit {
        switch unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .year
        }
    }

    private func parsePaymentMode(
        _ mode: StoreProductDiscount.PaymentMode
    ) -> InAppPurchaseServiceProduct.IntroductoryDiscount.PaymentMode {
        switch mode {
        case .freeTrial: return .freeTrial
        case .payUpFront: return .payUpFront
        case .payAsYouGo: return .payAsYouGo
        @unknown default: return .freeTrial
        }
    }
    
    private func makePriceFormatter(locale: Locale, currencyCode: String?) -> NumberFormatter? {
        guard let currencyCode = currencyCode else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        return formatter
    }
}
