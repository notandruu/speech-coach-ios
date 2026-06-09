"""
Smoke-test FluencyScorer.mlpackage: run a forward pass and print output.

Usage:
    python validate_coreml.py [--model path/to/FluencyScorer.mlpackage]
"""

import argparse
from pathlib import Path

import coremltools as ct
import numpy as np

MEL_BINS = 64
MEL_FRAMES = 128


def validate(model_path: Path) -> None:
    print(f"Loading {model_path} …")
    mlmodel = ct.models.MLModel(str(model_path))

    spec = mlmodel.get_spec()
    print("\n— Inputs —")
    for inp in spec.description.input:
        shape = list(inp.type.multiArrayType.shape)
        print(f"  {inp.name}: {shape}")
    print("— Outputs —")
    for out in spec.description.output:
        shape = list(out.type.multiArrayType.shape)
        print(f"  {out.name}: {shape}")

    # Run inference
    test_input = np.random.rand(1, 1, MEL_BINS, MEL_FRAMES).astype(np.float32)
    result = mlmodel.predict({"mel_spectrogram": test_input})
    scores = result["scores"]

    clarity = float(scores.flatten()[0])
    confidence = float(scores.flatten()[1])

    print(f"\n— Forward pass output —")
    print(f"  clarity_score : {clarity:.4f}  (expected 0–1)")
    print(f"  confidence    : {confidence:.4f}  (expected 0–1)")

    assert 0 <= clarity <= 1, "clarity out of range"
    assert 0 <= confidence <= 1, "confidence out of range"
    print("\nValidation passed.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model",
        type=Path,
        default=Path("../OnDeviceSpeechCoach/Resources/FluencyScorer.mlpackage"),
    )
    args = parser.parse_args()

    if not args.model.exists():
        raise FileNotFoundError(
            f"Model not found: {args.model}\nRun convert_to_coreml.py first."
        )

    validate(args.model)


if __name__ == "__main__":
    main()
