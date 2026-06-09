# Profiling Guide

## Prerequisites
- Xcode 15+
- Physical device preferred (Neural Engine not available in Simulator)
- Build with Release configuration for accurate numbers

## Instruments workflows

### 1. Feature extraction latency (Time Profiler + Signposts)

```
Xcode → Product → Profile (⌘I)
Choose: Time Profiler
Also add: os_signpost instrument

1. Launch app, navigate to Recording screen.
2. Record a ~30s clip.
3. Tap Stop.
4. In Instruments, look for the "FeatureExtraction" signpost interval.
   Target: p95 < 300ms for a 30-second clip.
```

### 2. Core ML inference latency

```
Instruments template: Core ML

1. Launch from Instruments.
2. Record a clip and stop.
3. Observe:
   - Model load time (first inference)
   - Prediction time (subsequent calls)
   - Compute unit used: Neural Engine / CPU / GPU
   Target: p95 < 100ms after model warmup.

Also check the CoreMLInference signpost interval added via os_signpost.
```

### 3. Memory footprint

```
Instruments template: Allocations

1. Launch app.
2. Start recording.
3. Stop recording and wait for results.
4. Check peak memory during the recording + processing phase.
   Target: < 150MB combined.
```

### 4. App launch time

```
Instruments template: App Launch

1. Profile a cold launch.
2. Check time from process start to first frame.
   Target: < 1.5s on a recent device.
```

### 5. UI responsiveness during recording

```
Instruments template: SwiftUI

1. Navigate to RecordingView.
2. Tap Start.
3. Observe frame rate and hitch markers.
   Target: 60fps with no hitches during level meter updates.
```

## Signpost intervals in code

| Interval name       | File                          | What it measures              |
|---------------------|-------------------------------|-------------------------------|
| FeatureExtraction   | AudioFeatureExtractor.swift   | Full feature extraction pass  |
| CoreMLInference     | FluencyModelRunner.swift      | Core ML prediction call       |

## Capturing a baseline

After profiling, record actual numbers here:

| Metric                           | Target    | Measured |
|----------------------------------|-----------|----------|
| Feature extraction p95 (30s)     | < 300ms   |          |
| Core ML inference p95            | < 100ms   |          |
| Peak memory (record + score)     | < 150MB   |          |
| App launch (cold)                | < 1.5s    |          |
| Results screen frame rate        | 60fps     |          |

Fill in measured values after running Instruments. Do not put targets in the README
as if they were measured results.
