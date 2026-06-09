# ML Pipeline — FluencyScorer

Converts a PyTorch CNN into a Core ML model bundled with the iOS app.

## Architecture

```
Input:  [1, 1, 64, 128]  — log-mel spectrogram (batch=1, channels=1, bins=64, frames=128)
Output: [1, 2]           — [clarity_score, confidence], both in [0, 1]

Layers:
  Conv2d(1→8, 3×3) → BN → ReLU → MaxPool(2)
  Conv2d(8→16, 3×3) → BN → ReLU → MaxPool(2)
  Conv2d(16→32, 3×3) → ReLU → AdaptiveAvgPool(4×4)
  Flatten → Linear(512→64) → ReLU → Dropout(0.3) → Linear(64→2) → Sigmoid
```

~30K parameters — small enough for Neural Engine inference in <100ms.

## Setup

```bash
cd ml
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Train

```bash
python train_fluency_model.py
```

Trains on synthetic data by default (5 classes: clear, moderate, quiet, noisy, silent).
Weights saved to `fluency_model.pt`. Training takes ~10 seconds on CPU.

**For better quality:** Place labeled WAV clips in `ml/data/` and replace
`generate_synthetic_dataset()` in `train_fluency_model.py` with your own loader.
Label format: `(clarity_score, confidence)` floats in [0, 1] per clip.

## Convert to Core ML

```bash
python convert_to_coreml.py
```

Writes `FluencyScorer.mlpackage` to `../OnDeviceSpeechCoach/OnDeviceSpeechCoach/Resources/`.

Custom paths:
```bash
python convert_to_coreml.py --weights fluency_model.pt --out /path/to/FluencyScorer.mlpackage
```

## Validate

```bash
python validate_coreml.py
```

Runs a single forward pass and checks outputs are in [0, 1].

## Copy into Xcode

The default `--out` path already places the model inside the Xcode project. After running the
conversion script, open Xcode → verify `FluencyScorer.mlpackage` appears in
`Resources/` → build. Xcode compiles it into `.mlmodelc` automatically.

## Model quality note

The default synthetic dataset is demo-grade. Numbers from this model are directionally
correct but not calibrated against real speech. To improve:

1. Record 50–100 labeled clips per quality tier.
2. Add real data to `ml/data/` and update the training script.
3. Re-run `train_fluency_model.py` → `convert_to_coreml.py`.
4. Rebuild the iOS app.
