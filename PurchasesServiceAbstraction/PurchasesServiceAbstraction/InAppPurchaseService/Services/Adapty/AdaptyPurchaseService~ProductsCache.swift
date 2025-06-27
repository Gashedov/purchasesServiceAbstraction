//
//  ProductsCache.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import Adapty
import Foundation

extension AdaptyPurchaseService {
    actor ProductsCache {
        private var placementsProducts: [InAppPurchaseServicePlacement: [AdaptyPaywallProduct]] = [:]
        private var serviceProducts: [InAppPurchaseServicePlacement: [InAppPurchaseServiceProduct]] = [:]
        
        func addProducts(_ products: [AdaptyPaywallProduct], for placement: InAppPurchaseServicePlacement) {
            placementsProducts[placement] = products
            serviceProducts[placement] = products.map { parseAdaptyProduct($0) }
        }
        
        func updatePlacements(_ newPlacements: [InAppPurchaseServicePlacement: [AdaptyPaywallProduct]]) {
            placementsProducts = newPlacements
        }
        
        func getProducts(_ placement: InAppPurchaseServicePlacement) -> [AdaptyPaywallProduct]? {
            placementsProducts[placement]
        }
        
        func getPlacements() -> [InAppPurchaseServicePlacement: [AdaptyPaywallProduct]] {
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
        
        func getServiceProduct(for adaptyProduct: AdaptyPaywallProduct) -> InAppPurchaseServiceProduct? {
            for placement in InAppPurchaseServicePlacement.allCases {
                if let product = serviceProducts[placement]?.first(where: { $0.id == adaptyProduct.vendorProductId }) {
                    return product
                }
            }
            return nil
        }
        
        func getAdaptyProduct(for serviceProsuct: InAppPurchaseServiceProduct) -> AdaptyPaywallProduct? {
            for placement in InAppPurchaseServicePlacement.allCases {
                if let product = placementsProducts[placement]?.first(where: { $0.vendorProductId == serviceProsuct.id }) {
                    return product
                }
            }
            return nil
        }
    }
}

extension AdaptyPurchaseService.ProductsCache {
    func parseAdaptyProduct(
        _ product: AdaptyPaywallProductWithoutDeterminingOffer
    ) -> InAppPurchaseServiceProduct {
        let introductoryDiscount: InAppPurchaseServiceProduct.IntroductoryDiscount? = {
            guard let offer = (product as? AdaptyPaywallProduct)?.subscriptionOffer else {
                return nil
            }
            return InAppPurchaseServiceProduct.IntroductoryDiscount(
                subscriptionPeriod: parseSubscriptionPeriod(offer.subscriptionPeriod),
                paymentMode: parsePaymentMode(offer.paymentMode)
            )
        }()
        
        let priceFormatter = makePriceFormatter(
            locale: Locale(identifier: Locale.current.identifier),
            currencyCode: product.currencyCode
        )

        return InAppPurchaseServiceProduct(
            id: product.vendorProductId,
            price: product.price,
            localizedPriceString: product.localizedPrice ?? "",
            priceFormatter: priceFormatter,
            subscriptionPeriod: product.subscriptionPeriod.map(parseSubscriptionPeriod),
            introductoryDiscount: introductoryDiscount
        )
    }

    // MARK: - Helper Parsers

    private func parseSubscriptionPeriod(
        _ adaptyPeriod: AdaptySubscriptionPeriod
    ) -> InAppPurchaseServiceProduct.SubscriptionPeriod {
        return .init(
            unit: parseSubscriptionPeriodUnit(adaptyPeriod.unit),
            value: adaptyPeriod.numberOfUnits
        )
    }

    private func parseSubscriptionPeriodUnit(
        _ unit: AdaptySubscriptionPeriod.Unit
    ) -> InAppPurchaseServiceProduct.SubscriptionPeriod.Unit {
        return switch unit {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        case .unknown: .year
        }
    }

    private func parsePaymentMode(
        _ mode: AdaptySubscriptionOffer.PaymentMode
    ) -> InAppPurchaseServiceProduct.IntroductoryDiscount.PaymentMode {
        switch mode {
        case .freeTrial:  return .freeTrial
        case .payUpFront: return .payUpFront
        case .payAsYouGo: return .payAsYouGo
        case .unknown: return .freeTrial
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
