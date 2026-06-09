"""
Convert fluency_model.pt → FluencyScorer.mlpackage for iOS.

Usage:
    python convert_to_coreml.py [--weights fluency_model.pt] [--out ../OnDeviceSpeechCoach/OnDeviceSpeechCoach/Resources/FluencyScorer.mlpackage]
"""

import argparse
from pathlib import Path

import coremltools as ct
import torch

from model import FluencyCNN

MEL_BINS = 64
MEL_FRAMES = 128


def convert(weights_path: Path, out_path: Path) -> None:
    # Load model
    model = FluencyCNN()
    state = torch.load(weights_path, map_location="cpu", weights_only=True)
    model.load_state_dict(state)
    model.eval()

    # Trace with example input [1, 1, 64, 128]
    example = torch.rand(1, 1, MEL_BINS, MEL_FRAMES)
    traced = torch.jit.trace(model, example)

    # Convert
    mlmodel = ct.convert(
        traced,
        inputs=[
            ct.TensorType(
                name="mel_spectrogram",
                shape=example.shape,
                dtype=float,
            )
        ],
        outputs=[
            ct.TensorType(name="scores", dtype=float)
        ],
        minimum_deployment_target=ct.target.iOS17,
        compute_precision=ct.precision.FLOAT16,
    )

    # Metadata
    mlmodel.short_description = "On-device speech fluency scorer"
    mlmodel.author = "On-Device Speech Coach"
    mlmodel.version = "1.0.0"

    mlmodel.input_description["mel_spectrogram"] = "Log-mel spectrogram [1, 1, 64, 128]"
    mlmodel.output_description["scores"] = "[clarity_score, confidence] in [0, 1]"

    out_path.parent.mkdir(parents=True, exist_ok=True)
    mlmodel.save(str(out_path))
    print(f"Saved Core ML model → {out_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--weights", type=Path, default=Path("fluency_model.pt"))
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("../OnDeviceSpeechCoach/OnDeviceSpeechCoach/Resources/FluencyScorer.mlpackage"),
    )
    args = parser.parse_args()

    if not args.weights.exists():
        raise FileNotFoundError(
            f"Weights not found: {args.weights}\nRun train_fluency_model.py first."
        )

    convert(args.weights, args.out)


if __name__ == "__main__":
    main()
