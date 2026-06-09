# On-Device Speech Coach — PRD

## One-liner
Privacy-preserving iOS app that lets users practice reading short passages aloud, records audio locally, extracts speech features on-device, runs a Core ML fluency model locally, and gives feedback on pace, pausing, clarity, and consistency without uploading raw audio.

## Primary user flow
1. User opens app → sees daily practice prompt and recent score
2. User chooses a prompt or uses default
3. User taps Record → microphone permission requested if needed
4. App records audio locally, shows live timer and waveform/level meter
5. User taps Stop
6. App extracts audio features locally (AVFoundation + Accelerate/vDSP)
7. App runs Core ML inference locally
8. App displays score breakdown: Overall, Pace, Pause, Clarity, Volume Consistency
9. App saves session locally with SwiftData
10. User views progress history over time

## Non-goals
- Not a cloud ML app — no backend, no raw audio upload
- Not full ASR / Siri clone
- Not a medical or diagnostic tool

## Privacy principle
Raw audio stays on the device. No analytics SDKs. No network calls for scoring.

## Scoring formula
```
overall = 0.30 * pace + 0.30 * pause + 0.25 * clarity + 0.15 * volume_consistency
```

## Performance targets (measure via Instruments, do not claim until verified)
- Feature extraction p95 < 300ms for 30s clip
- Core ML inference p95 < 100ms after warmup
- Memory during recording/scoring < 150MB
- App launch < 1.5s
