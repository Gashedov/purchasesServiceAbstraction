//
//  InAppPurchaseServicePlacement.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//


enum InAppPurchaseServicePlacement: CaseIterable {
    case main
    
    var key: String {
        switch self {
        case .main: "main"
        }
    }
}
