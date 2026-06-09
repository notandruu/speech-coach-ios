# Claude instructions for On-Device Speech Coach

You are building an iOS app in Swift/SwiftUI.

Priorities:
1. Correctness and buildability.
2. Clear architecture.
3. Local-first privacy.
4. Testable audio/scoring logic.
5. Resume-grade code quality.

Do not add cloud services, analytics SDKs, or raw audio upload.
Do not invent unverified performance numbers.
Prefer small, reviewable changes.

After each milestone:
- run tests if possible
- explain what changed
- list any manual Xcode steps
- list remaining TODOs

Architecture:
- SwiftUI views
- ViewModels for screen state
- Audio services isolated under Audio/
- Core ML wrapper isolated under ML/
- SwiftData models under Models/
- Persistence wrapper under Persistence/
- XCTest coverage for scoring, features, persistence, and performance
