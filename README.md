# speech-coach-ios

Practice reading aloud and get instant feedback on your pace, pausing, clarity, and volume. All processing happens on your iPhone; nothing is sent anywhere.

## What it does

You pick a short passage, record yourself reading it, and the app breaks down how you did. It tells you if you were rushing, pausing too much, speaking inconsistently, or sounding unclear. Sessions are saved locally so you can track improvement over time.

The feedback is built from two sources: deterministic signal-processing metrics (pace from word count + duration, pauses from silence detection, volume variance from RMS) and a small CNN running through Core ML that estimates clarity from the mel spectrogram. No transcription, no cloud, no audio upload.

## Stack

- **SwiftUI** - all screens built natively, no third-party UI libs
- **AVFoundation** - local mono recording to a temporary WAV file
- **Accelerate / vDSP** - FFT, RMS, silence detection, spectrogram building
- **Core ML** - on-device CNN inference for clarity scoring
- **SwiftData** - local session history
- **XCTest** - unit tests, fixture-based audio tests, performance measure blocks

The PyTorch model lives in `ml/` with conversion scripts for coremltools. The iOS app ships without a backend dependency and falls back to deterministic scoring if the `.mlpackage` isn't bundled yet.

## Project layout

```
OnDeviceSpeechCoach/
  App/            constants, router
  Audio/          recorder, feature extractor, silence detector, waveform
  ML/             Core ML wrapper, scoring formula, feedback generation
  Models/         value types (prompt, session, features, score)
  Persistence/    SwiftData store
  Views/          6 screens + shared components
  ViewModels/     @Observable state for each screen

OnDeviceSpeechCoachTests/
  SilenceDetectorTests
  AudioFeatureExtractorTests
  FluencyScorerTests
  ModelInputBuilderTests
  SessionStoreTests
  RecordingPermissionTests
  PerformanceTests

ml/
  model.py               FluencyCNN (PyTorch)
  train_fluency_model.py synthetic + real data training
  convert_to_coreml.py   traces model and converts with coremltools
  validate_coreml.py     smoke test for the .mlpackage
```

## Getting the ML model

The `.mlpackage` isn't committed (it's several MB). Build it yourself:

```bash
cd ml
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python train_fluency_model.py   # writes fluency_model.pt
python convert_to_coreml.py     # writes Resources/FluencyScorer.mlpackage
python validate_coreml.py       # sanity check
```

The default training data is synthetic (five tiers from clear speech to silence). For better results, drop labeled WAV clips into `ml/data/` and swap out the data loader.

## Xcode setup

1. Create an iOS App target (iOS 17+, Swift, SwiftUI lifecycle)
2. Add all files from `OnDeviceSpeechCoach/` to the target
3. Add `FluencyScorer.mlpackage` to the target after running the ML pipeline
4. Add `PrivacyInfo.xcprivacy` to the target
5. Set `NSMicrophoneUsageDescription` in Info.plist
6. Run

The app builds and works without the model. Deterministic scoring kicks in automatically.

## Scoring

```
overall = 0.30 × pace + 0.30 × pauses + 0.25 × clarity + 0.15 × volume
```

Pace is computed from the prompt's known word count divided by active speech duration (total minus detected silence). Pauses are silence segments longer than 500ms, detected via vDSP RMS thresholding per 512-sample frame. Clarity comes from the CNN. Volume is RMS variance normalized to a 0–100 scale.

## Profiling

See [PROFILING.md](PROFILING.md) for Instruments workflows. Signposts are placed around feature extraction and Core ML inference so you can see them in the os_signpost instrument.

## Privacy

Temporary WAV files are deleted immediately after feature extraction. No audio is persisted unless you explicitly enable local saving in Settings. No network requests are made during recording or scoring.
