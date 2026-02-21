# Calorie Tracker - iOS App

## Project Overview

A native iOS calorie tracking app built with SwiftUI and SwiftData. Users can log daily food intake via text (AI-powered calorie estimation), barcode scanning, or manual entry. The app calculates personalized daily calorie goals using the Mifflin-St Jeor equation, integrates with Apple HealthKit for biometric data, and provides weight tracking with visual progress charts.

## Tech Stack

- **UI**: SwiftUI (iOS 26) — uses Liquid Glass design language (`.glassEffect()` API)
- **Persistence**: SwiftData (`FoodEntry`, `WeightEntry`)
- **User Preferences**: `@AppStorage` / UserDefaults
- **Frameworks**: HealthKit, VisionKit (barcode scanning), Charts
- **APIs**: Google Gemini (gemini-2.0-flash, structured output for calorie estimation), Open Food Facts (barcode lookup)
- **Architecture**: MVVM with `@Observable`, environment-injected services

## Project Structure

```
calorie-tracker/
├── Models/
│   ├── FoodEntry.swift          # Food log entry (SwiftData model)
│   ├── WeightEntry.swift        # Weight log entry (SwiftData model)
│   └── CalorieEstimate.swift    # AI response DTO (Decodable)
├── Services/
│   ├── CalorieEstimationService.swift  # Google Gemini integration
│   ├── FoodLookupService.swift         # Open Food Facts barcode API
│   ├── HealthKitService.swift          # Apple Health data reader
│   └── VersionCheckService.swift       # Force-update / maintenance check
├── ViewModels/
│   └── DayLogViewModel.swift    # Entry creation logic (text, manual, barcode)
├── Utilities/
│   ├── TDEECalculator.swift     # BMR/TDEE/weight projection math
│   ├── DateFormatting.swift     # Date display helpers
│   └── Configuration.swift      # Secrets.plist loader (Gemini API key)
├── Views/
│   ├── DayLogView.swift         # Main screen - daily food log
│   ├── ProfileView.swift        # Profile, weight chart, calorie goal, streak grid
│   ├── RecalculateView.swift    # Re-run TDEE calculation (sheet)
│   ├── BarcodeScannerView.swift # Camera barcode scanner (VisionKit)
│   ├── FoodEntryRow.swift       # Single food entry row component
│   ├── EditEntrySheet.swift     # Edit food entry modal
│   ├── EntryInputBar.swift      # Text input + controls bar
│   ├── SplashView.swift         # Launch splash with animated icon
│   ├── ForceUpdateView.swift    # Non-dismissable force-update screen
│   ├── MaintenanceView.swift    # Non-dismissable maintenance screen
│   └── Onboarding/
│       ├── OnboardingView.swift        # 5-step onboarding container
│       ├── OnboardingWelcomeStep.swift # Welcome screen
│       ├── OnboardingBodyStep.swift    # Sex, age, height, weight + HealthKit import
│       ├── OnboardingActivityStep.swift # Activity level selection
│       ├── OnboardingGoalStep.swift    # Weight goal + target weight
│       └── OnboardingResultStep.swift  # TDEE breakdown + final goal
├── calorie_trackerApp.swift     # App entry point, SwiftData container setup
├── ContentView.swift            # Root view, service initialization
├── calorie-tracker.entitlements # HealthKit entitlement
└── Secrets.plist                # API keys (git-ignored)
```

## Key Features Implemented

### Food Logging (3 sources)
- **AI-powered**: User types "3x Apples" -> Gemini returns structured calorie/macro estimate
- **Barcode scanning**: VisionKit DataScanner -> Open Food Facts API lookup
- **Manual entry**: User types "Chicken 500" -> parsed as food name + calories

### Onboarding & TDEE Calculation
- 5-step onboarding: welcome -> body metrics -> activity level -> weight goal -> result
- Optional HealthKit import for sex, age, height, weight
- Mifflin-St Jeor BMR formula with activity multiplier
- Goal adjustment: -500 kcal (lose), 0 (maintain), +500 kcal (gain)
- Recalculate flow accessible from ProfileView

### Daily Log (DayLogView)
- Date navigation (prev/next day)
- Entries grouped by meal type (breakfast, lunch, dinner, snack)
- Calorie pill showing total vs goal
- Swipe-to-delete entries
- Tap entry to edit (name, calories, macros, meal type, quantity)
- AI/manual toggle on input bar

### Force Update / Maintenance (VersionCheckService)
- On every launch and background→foreground transition, `GET https://api.omidsprivatehub.tech/v1/version/check?version={CFBundleShortVersionString}`
- No auth headers; fails open (app proceeds normally on any error or non-200)
- `update_required == true` → non-dismissable `ForceUpdateView` with "Update Now" button opening `store_url`
- `is_maintenance == true` → non-dismissable `MaintenanceView` (no action)
- Both overlays render at `zIndex(2)`, above `SplashView` at `zIndex(1)`
- `showSplash` gates on `!versionService.hasChecked` so splash holds until check completes
- Current app version sent: `1.0` (MARKETING_VERSION in Xcode project)

### Profile & Analytics (ProfileView)
- Weight tracking with stepper and log history
- Weight progress chart (Charts framework, 30-entry area+line chart with target line)
- 12-week calorie streak grid (color-coded: green=on target, orange=slightly over, red=over)
- Weight projection (weeks to target, projected date)
- Adjustable daily calorie goal with slider

## Data Flow

### Entry Creation
```
User input -> DayLogViewModel -> Service (AI/Barcode/Manual) -> FoodEntry -> SwiftData -> @Query refresh -> UI update
```

### State Layers
| Layer | What | Where |
|-------|-------|-------|
| `@AppStorage` | User profile, calorie goal, onboarding flag | UserDefaults |
| `SwiftData` | Food entries, weight entries | Local DB |
| `@State` | Temporary UI state (focus, editing, sheets) | View memory |
| `@Environment` | Services (CalorieEstimationService, FoodLookupService) | View hierarchy |

## Configuration

### Secrets.plist (required, git-ignored)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>AIza...</string>
</dict>
</plist>
```

### Required Permissions (Info.plist)
- `NSCameraUsageDescription` - Barcode scanning
- `NSHealthShareUsageDescription` - HealthKit read access

## Key Models

### FoodEntry (SwiftData)
- `rawInput`, `foodName`, `calories`, `proteinGrams?`, `carbsGrams?`, `fatGrams?`
- `quantity` (default 1.0), `source` ("ai"/"manual"/"barcode"), `mealType`, `barcode?`
- `timestamp`, `isCalorieOverridden`
- Nested `MealType` enum with `defaultForCurrentTime()` based on hour

### WeightEntry (SwiftData)
- `weight` (kg), `timestamp`

### CalorieEstimate (Decodable DTO)
- `foodName`, `totalCalories`, `proteinGrams`, `carbsGrams`, `fatGrams`, `quantity`

## Conventions

- **No third-party dependencies** - uses only Apple frameworks + external APIs
- **Services** are `@Observable` classes injected via `.environment()`
- **Enums** in `TDEECalculator.swift` define `BiologicalSex`, `ActivityLevel`, `WeightGoal` with display properties
- **Date helpers** in `DateFormatting.swift` - contextual display ("Today", "Yesterday", etc.)
- **Minimum calorie goal**: 1200 kcal (safety floor in TDEECalculator)
- **Weight units**: kg throughout; calorie units: kcal
- **Glass morphism** UI style with `.glassEffect()` and ultra-thin materials
- **Matched geometry transitions** between DayLogView calorie pill and ProfileView

## iOS 26 Liquid Glass Sheets

The app targets iOS 26 and uses the Liquid Glass design system. Sheets get the automatic frosted glass background **only when a partial-height detent is declared** (`.medium`, `.fraction(x)`, etc.). Full-screen `.large`-only sheets get an opaque background.

### Recipe for Liquid Glass sheets

```swift
// At the call site — must have a partial detent:
.sheet(isPresented: $show) {
    MyView()
        .presentationDetents([.fraction(0.85)]) // or .medium, [.medium, .large], etc.
        // Do NOT set .presentationBackground — omit it entirely
}

// Inside the sheet view:

// If content is a ScrollView:
ScrollView { ... }
    .scrollContentBackground(.hidden)
    .containerBackground(.clear, for: .navigation) // removes NavigationStack's opaque layer

// If content is a Form/List:
Form { ... }
    .scrollContentBackground(.hidden)             // reveal glass behind form rows
    .containerBackground(.clear, for: .navigation)

// Plain VStack/content inside NavigationStack:
VStack { ... }
    .containerBackground(.clear, for: .navigation)
```

### Key rules
- `.containerBackground(.clear, for: .navigation)` is **required** when a `NavigationStack` wraps the sheet content — without it the NavigationStack injects its own opaque backdrop that blocks the glass
- `Do NOT` add `.presentationBackground` — the glass is automatic from the partial detent
- `ScrollView` is transparent by default; `Form`/`List` paint an opaque background that must be hidden
- Applied to: `ProfileView` (`.fraction(0.8)`), `RecalculateView` (`.fraction(0.85)`)

## Version Check API

- **Endpoint**: `GET https://api.omidsprivatehub.tech/v1/version/check?version={version}`
- **Response** (snake_case JSON → `VersionCheckResponse`):
  - `update_required` (Bool), `latest_version`, `min_version`, `store_url`, `message`, `is_maintenance` (Bool)
- **Failure behaviour**: any error or non-200 → `response = nil`, `hasChecked = true` → app proceeds

## Gemini Integration Details

- **Endpoint**: `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- **Model**: `gemini-2.0-flash`
- **Response format**: Structured JSON output via `responseSchema` with `responseMimeType: "application/json"`
- **System prompt**: Nutrition expert that parses quantities (e.g., "3x Apples" -> quantity: 3) and returns total calories for the full quantity

## Build & Run

1. Open `calorie-tracker.xcodeproj` in Xcode
2. Create `Secrets.plist` in `calorie-tracker/` with your `GEMINI_API_KEY`
3. Add `Secrets.plist` to the Xcode project (ensure it's in the app bundle)
4. Build and run on a physical device (camera required for barcode scanning)
