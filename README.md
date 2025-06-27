# 🛒 InAppPurchaseService

A unified Swift interface to handle in-app purchases and subscriptions using **Adapty**, **RevenueCat**, or **Apphud** SDKs with a clean and testable abstraction.

Supports:
- Fetching products by placement
- Purchasing and restoring subscriptions
- Subscription status tracking via Combine
- Unified `InAppPurchaseServiceProduct` model

---

## ✅ Features

- 🔄 SDK Agnostic abstraction (`InAppPurchaseService`)
- 🎯 Centralized product model (`InAppPurchaseServiceProduct`)
- 🧠 Combine publisher for real-time subscription state
- 📦 Placement-based product loading
- 🔐 IDFA, IDFV, Firebase ID, IP management

---

## 📦 Supported Providers

| Provider     | SDK                         |
|--------------|-----------------------------|
| Adapty       | [Adapty](https://github.com/adaptyteam/AdaptySDK-iOS)     |
| RevenueCat   | [RevenueCat](https://github.com/RevenueCat/purchases-ios) |
| Apphud       | [Apphud](https://github.com/apphud/ApphudSDK)             |

---

## 🛠 Setup

### 1. Define your placements

```swift
enum InAppPurchaseServicePlacement: CaseIterable {
    case main
    
    var key: String {
        switch self {
        case .main: return "main"
        }
    }
}
```

### 2. Initialize your service

Choose one of the supported providers:

```swift
let purchaseService: InAppPurchaseService = AdaptyPurchaseService()
// OR
let purchaseService: InAppPurchaseService = RevenueCatPurchaseService()
// OR
let purchaseService: InAppPurchaseService = ApphudPurchaseService()
```

### 3. Configure the SDK

Call `configure()` once at app launch:

```swift
@MainActor
func setupPurchaseService() {
    purchaseService.configure()
}
```

## 🚀 Usage

### 📦 Fetch Products

Fetch all products for a specific placement:

```swift
let products = try await purchaseService.products(for: .main)
```
