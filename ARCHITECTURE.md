# Architecture

## Pattern
MVVM — Views bind to ViewModels; all audio, ML, and persistence logic lives in isolated service layers.

## Layers

```
Views          — SwiftUI screens + reusable Components
ViewModels     — @Observable state; coordinate services; no UI framework imports
Audio/         — AVFoundation recording, feature extraction, silence detection
ML/            — Core ML wrapper, scoring formula, feedback generation
Persistence/   — SwiftData store
Models/        — Plain Swift value types (Codable, Sendable where possible)
```

## Data flow
```
RecordingView
  └─ RecordingViewModel
       ├─ AudioRecorder        (AVFoundation)
       ├─ AudioFeatureExtractor (Accelerate/vDSP)
       ├─ ModelInputBuilder
       ├─ FluencyModelRunner   (Core ML)
       └─ FluencyScorer        (deterministic formula)
            └─ ScoreBreakdown + [SpeechFeedback]
                 └─ SessionStore (SwiftData)
```

## Threading
- Recording callbacks on dedicated audio thread; bridged to MainActor for UI updates
- Feature extraction on a background Task
- Core ML inference on a background Task; results published on MainActor

## Privacy
- AVAudioRecorder writes to a temporary local file
- File deleted immediately after feature extraction unless user enables "Save recordings locally"
- No URLSession calls in production code paths
- PrivacyInfo.xcprivacy declares microphone usage reason
