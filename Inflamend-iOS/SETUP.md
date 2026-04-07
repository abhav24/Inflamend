# Inflamend iOS — SwiftUI Setup

## Create the Xcode Project

1. Open Xcode → New Project → iOS App
2. Product Name: `Inflamend`
3. Interface: **SwiftUI**, Language: **Swift**
4. Minimum Deployment: **iOS 16.0**
5. Save into this `Inflamend-iOS/` directory

## Add the Supabase Swift SDK

File → Add Package Dependencies → search for:
```
https://github.com/supabase/supabase-swift
```
Select `Up to Next Major Version` from `2.0.0`, then add the **Supabase** product to your target.

## Add Source Files

Drag all `.swift` files (and folders) from this directory into the Xcode project navigator, ensuring "Copy items if needed" is **unchecked** (they're already in place).

Structure:
```
Inflamend/
├── InflamendApp.swift
├── ContentView.swift
├── DesignSystem.swift
├── Config.swift
├── Models/
│   └── Models.swift
├── Services/
│   └── SupabaseClient.swift
├── ViewModels/
│   └── AuthViewModel.swift
└── Views/
    ├── Auth/
    │   ├── LoginView.swift
    │   └── SignupView.swift
    ├── Home/
    │   └── HomeView.swift
    ├── Log/
    │   └── LogView.swift
    ├── Insights/
    │   └── InsightsView.swift
    ├── Chat/
    │   └── ChatView.swift
    └── Profile/
        └── ProfileView.swift
```

## Configure Supabase

Edit `Config.swift` and fill in your project credentials:

```swift
enum Config {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-anon-key"
}
```

## Delete the default files

Remove the auto-generated `ContentView.swift` and `Assets.xcassets` entries that Xcode creates — they conflict with the ones in this project.

## Build & Run

Select an iPhone simulator (iOS 16+) and press ▶.
