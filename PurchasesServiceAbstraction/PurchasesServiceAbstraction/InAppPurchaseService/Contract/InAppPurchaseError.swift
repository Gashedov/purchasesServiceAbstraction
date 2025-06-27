//
//  InAppPurchaseError.swift
//  PurchasesServiceAbstraction
//
//  Created by Artem Gorshkov on 27.06.25.
//

import Foundation

enum InAppPurchaseError: LocalizedError {
    case purchaseNotVerified
    case getCustomerInfoError(Error)
    case retrievingPachasesError(Error)
    case currentOfferingNotFound
    case packageUnderGivenIndexNotFound(Int)
    case restoringPurchasesError(Error)
    case purchasingFailed(Error)
}

extension InAppPurchaseError {
    /// A localized message describing what error occurred.
    var errorDescription: String? {
        switch self {
        case .purchaseNotVerified: return NSLocalizedString("Purchase failed. You're using the free version.", comment: "")
        case .getCustomerInfoError(let error): return error.localizedDescription
        case .retrievingPachasesError: return NSLocalizedString("Purchase products couldn't be fetched.\nPlease check your internet connection and try again", comment: "")
        case .currentOfferingNotFound: return NSLocalizedString("Current offering not found", comment: "")
        case .packageUnderGivenIndexNotFound(let index): return String(format: NSLocalizedString("Package with index %d doesn't exist in current offering", comment: ""), index)
        case .restoringPurchasesError(_): return NSLocalizedString("Restore purchase process failed. \nPlease check your internet connection and try again", comment: "")
        case .purchasingFailed(_): return NSLocalizedString("Purchasing process failed. \nPlease check your internet connection and try again", comment: "")
        }
    }
}
