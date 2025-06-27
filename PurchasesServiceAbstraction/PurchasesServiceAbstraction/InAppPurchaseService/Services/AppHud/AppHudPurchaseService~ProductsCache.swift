//
//  ProductsCache.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import ApphudSDK
import Foundation
import StoreKit

extension AppHudPurchaseService {
    actor ProductsCache {
        private var placementsProducts: [InAppPurchaseServicePlacement: [ApphudProduct]] = [:]
        private var serviceProducts: [InAppPurchaseServicePlacement: [InAppPurchaseServiceProduct]] = [:]
        
        func addProducts(_ products: [ApphudProduct], for placement: InAppPurchaseServicePlacement) async {
            placementsProducts[placement] = products

            let parsedProducts = await withTaskGroup(of: InAppPurchaseServiceProduct?.self) { group in
                for product in products {
                    group.addTask {
                        await self.parseApphudProduct(product)
                    }
                }

                var results: [InAppPurchaseServiceProduct] = []
                for await result in group {
                    if let product = result {
                        results.append(product)
                    }
                }
                return results
            }

            serviceProducts[placement] = parsedProducts
        }
        
        func updatePlacements(_ newPlacements: [InAppPurchaseServicePlacement: [ApphudProduct]]) {
            placementsProducts = newPlacements
        }
        
        func getProducts(_ placement: InAppPurchaseServicePlacement) -> [ApphudProduct]? {
            placementsProducts[placement]
        }
        
        func getPlacements() -> [InAppPurchaseServicePlacement: [ApphudProduct]] {
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
        
        func getServiceProduct(for apphudProduct: ApphudProduct) -> InAppPurchaseServiceProduct? {
            for placement in InAppPurchaseServicePlacement.allCases {
                if let product = serviceProducts[placement]?.first(where: { $0.id == apphudProduct.productId }) {
                    return product
                }
            }
            return nil
        }
        
        func getAppHudProduct(for serviceProsuct: InAppPurchaseServiceProduct) -> ApphudProduct? {
            for placement in InAppPurchaseServicePlacement.allCases {
                if let product = placementsProducts[placement]?.first(where: { $0.productId == serviceProsuct.id }) {
                    return product
                }
            }
            return nil
        }
    }
}

extension AppHudPurchaseService.ProductsCache {
    func parseApphudProduct(_ apphudProduct: ApphudProduct) async -> InAppPurchaseServiceProduct? {
        guard let product = try? await apphudProduct.product(),
              let subscription = product.subscription,
              let offer = subscription.introductoryOffer else { return nil }
        
        let locale = product.priceFormatStyle.locale
        
        let introductoryDiscount = InAppPurchaseServiceProduct.IntroductoryDiscount(
            subscriptionPeriod: parseSubscriptionPeriod(offer.period),
            paymentMode: parsePaymentMode(offer.paymentMode)
        )
        
        let price = getPriceWithCurrency(for: product.price, locale: locale)
        let priceFormatter = makePriceFormatter(locale: locale)
        
        return InAppPurchaseServiceProduct(
            id: apphudProduct.productId,
            price: product.price,
            localizedPriceString: price,
            priceFormatter: priceFormatter,
            subscriptionPeriod: parseSubscriptionPeriod(subscription.subscriptionPeriod),
            introductoryDiscount: introductoryDiscount
        )
        
    }

    // MARK: - Helper Parsers
    private func parseSubscriptionPeriod(
        _ period: Product.SubscriptionPeriod
    ) -> InAppPurchaseServiceProduct.SubscriptionPeriod {
        return .init(
            unit: parseSubscriptionPeriodUnit(period.unit),
            value: period.value
        )
    }

    private func parseSubscriptionPeriodUnit(
        _ unit: Product.SubscriptionPeriod.Unit
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
        _ mode: Product.SubscriptionOffer.PaymentMode
    ) -> InAppPurchaseServiceProduct.IntroductoryDiscount.PaymentMode {
        switch mode {
        case .freeTrial: return .freeTrial
        case .payAsYouGo: return .payAsYouGo
        case .payUpFront: return .payUpFront
        default: return .freeTrial
        }
    }
    
    private func getPriceWithCurrency(for price: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? ""
    }
    
    private func makePriceFormatter(locale: Locale) -> NumberFormatter? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter
    }
}
