"""
Train FluencyCNN on synthetic data (demo) or real labeled clips in ml/data/.

Synthetic data scheme:
  - Clear speech (sine wave mixture, high amplitude):  clarity≈0.9, confidence≈0.95
  - Quiet/muffled (low amplitude):                    clarity≈0.35, confidence≈0.5
  - Noisy (white noise):                              clarity≈0.2,  confidence≈0.3
  - Silent:                                           clarity≈0.1,  confidence≈0.1

For production quality, replace generate_synthetic_dataset() with a loader
that reads real labeled WAV clips from ml/data/.
"""

import random
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset

from model import FluencyCNN

# ── Config ──────────────────────────────────────────────────────────────────
MEL_BINS = 64
MEL_FRAMES = 128
EPOCHS = 40
BATCH_SIZE = 32
LR = 1e-3
SAMPLES_PER_CLASS = 200
SEED = 42
OUTPUT_PATH = Path("fluency_model.pt")
# ─────────────────────────────────────────────────────────────────────────────


def generate_synthetic_dataset() -> tuple[torch.Tensor, torch.Tensor]:
    """Returns (X, y) tensors with shape ([N,1,64,128], [N,2])."""
    rng = np.random.default_rng(SEED)
    X_list, y_list = [], []

    def make_spectrogram(amplitude: float, noise: float) -> np.ndarray:
        mel = rng.normal(0, amplitude, (1, MEL_BINS, MEL_FRAMES)).astype(np.float32)
        mel += rng.normal(0, noise, mel.shape)
        return np.clip(mel, -1, 1)

    classes = [
        # (amplitude, noise, clarity, confidence)
        (0.8,  0.05, 0.90, 0.95),   # clear speech
        (0.5,  0.10, 0.70, 0.80),   # moderate
        (0.15, 0.05, 0.35, 0.50),   # quiet
        (0.05, 0.60, 0.20, 0.30),   # noisy
        (0.01, 0.01, 0.10, 0.10),   # silent
    ]

    for amp, noise, clarity, confidence in classes:
        for _ in range(SAMPLES_PER_CLASS):
            spec = make_spectrogram(amp, noise)
            X_list.append(spec)
            # Add small label noise for regularization
            c = float(np.clip(clarity + rng.normal(0, 0.05), 0, 1))
            conf = float(np.clip(confidence + rng.normal(0, 0.05), 0, 1))
            y_list.append([c, conf])

    X = torch.tensor(np.array(X_list))
    y = torch.tensor(np.array(y_list, dtype=np.float32))
    return X, y


def train() -> None:
    torch.manual_seed(SEED)
    random.seed(SEED)

    X, y = generate_synthetic_dataset()
    print(f"Dataset: {X.shape}, labels: {y.shape}")

    # 80/20 split
    n = len(X)
    idx = torch.randperm(n)
    split = int(0.8 * n)
    train_ds = TensorDataset(X[idx[:split]], y[idx[:split]])
    val_ds = TensorDataset(X[idx[split:]], y[idx[split:]])

    train_loader = DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=BATCH_SIZE)

    model = FluencyCNN()
    optimizer = torch.optim.Adam(model.parameters(), lr=LR)
    criterion = nn.MSELoss()
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS)

    best_val_loss = float("inf")

    for epoch in range(1, EPOCHS + 1):
        model.train()
        train_loss = 0.0
        for xb, yb in train_loader:
            optimizer.zero_grad()
            pred = model(xb)
            loss = criterion(pred, yb)
            loss.backward()
            optimizer.step()
            train_loss += loss.item() * len(xb)
        train_loss /= len(train_ds)

        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for xb, yb in val_loader:
                pred = model(xb)
                val_loss += criterion(pred, yb).item() * len(xb)
        val_loss /= len(val_ds)
        scheduler.step()

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(model.state_dict(), OUTPUT_PATH)

        if epoch % 10 == 0 or epoch == 1:
            print(f"Epoch {epoch:3d}/{EPOCHS}  train={train_loss:.4f}  val={val_loss:.4f}")

    print(f"\nBest val loss: {best_val_loss:.4f}")
    print(f"Weights saved to {OUTPUT_PATH}")


if __name__ == "__main__":
    train()
