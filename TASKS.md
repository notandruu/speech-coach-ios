# Tasks

## Milestone 1 — Project skeleton + SwiftUI navigation ✅
- [x] All screens stubbed with placeholder UI
- [x] Navigation between all screens
- [x] Preview data for all models

## Milestone 2 — SwiftData persistence ✅
- [x] @Model PracticeSession
- [x] SessionStore (save, fetch, delete all)
- [x] HistoryView displaying real sessions
- [x] SettingsView delete-all action
- [x] Persistence XCTests with in-memory container

## Milestone 3 — AVFoundation recording ✅
- [x] AudioSessionManager
- [x] AudioRecorder (start/stop/cancel)
- [x] Microphone permission flow
- [x] Recording timer
- [x] Audio level meter
- [x] Temporary file cleanup
- [x] Permission abstraction for testing

## Milestone 4 — Audio feature extraction ✅
- [x] AudioFeatureExtractor
- [x] SilenceDetector
- [x] WaveformExtractor
- [x] ModelInputBuilder (mel-spectrogram tensor)
- [x] Fixture-based XCTests

## Milestone 5 — Scoring engine ✅
- [x] FluencyScorer (deterministic pace/pause/volume)
- [x] SpeechFeedback generation
- [x] ScoreBreakdown
- [x] Scoring XCTests (ideal, too fast, too slow, clamp)

## Milestone 6 — Core ML wrapper ✅
- [x] FluencyModelRunner
- [x] MLMultiArray conversion
- [x] DEBUG fallback when model missing
- [x] Unit tests for tensor shape + fallback

## Milestone 7 — Python ML pipeline ✅
- [x] model.py (FluencyCNN)
- [x] train_fluency_model.py
- [x] convert_to_coreml.py
- [x] validate_coreml.py
- [x] ml/README.md

## Milestone 8 — UI polish ✅
- [x] ScoreRingView
- [x] FeedbackCardView
- [x] WaveformView / level meter
- [x] Empty states, error states, privacy copy

## Milestone 9 — Tests + profiling ✅
- [x] XCTest suite complete
- [x] os_signpost instrumentation
- [x] PROFILING.md

## Remaining manual Xcode steps
- Create new iOS App target in Xcode, min deployment iOS 17
- Add all Swift files to target
- Add FluencyScorer.mlpackage to Resources/
- Add PrivacyInfo.xcprivacy to target
- Set NSMicrophoneUsageDescription in Info.plist
- Enable SwiftData capability (automatic with import SwiftData)
- Run on simulator or device before profiling
