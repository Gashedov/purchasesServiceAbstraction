//
//  InAppPurchaseServiceProduct.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import StoreKit

struct InAppPurchaseServiceProduct: Identifiable, Equatable {
    var id: String

    var price: Decimal
    var localizedPriceString: String
    var priceFormatter: NumberFormatter?
    var subscriptionPeriod: SubscriptionPeriod?
    var introductoryDiscount: IntroductoryDiscount?
    
    struct SubscriptionPeriod: Equatable {
        var unit: Unit
        var value: Int
        
        enum Unit: Int {
            case day, week, month, year
        }
    }

    struct IntroductoryDiscount: Equatable {
        var subscriptionPeriod: SubscriptionPeriod
        var paymentMode: PaymentMode

        enum PaymentMode {
            case freeTrial, payUpFront, payAsYouGo
        }
    }
}
