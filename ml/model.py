"""FluencyCNN — lightweight spectrogram → (clarity_score, confidence) model."""

import torch
import torch.nn as nn


class FluencyCNN(nn.Module):
    """
    Input:  [batch, 1, 64, 128]  (mel bins × time frames)
    Output: [batch, 2]           (clarity_score, confidence) in [0, 1]
    """

    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv2d(1, 8, kernel_size=3, padding=1),
            nn.BatchNorm2d(8),
            nn.ReLU(),
            nn.MaxPool2d(2),                      # → [8, 32, 64]

            nn.Conv2d(8, 16, kernel_size=3, padding=1),
            nn.BatchNorm2d(16),
            nn.ReLU(),
            nn.MaxPool2d(2),                      # → [16, 16, 32]

            nn.Conv2d(16, 32, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.AdaptiveAvgPool2d((4, 4)),          # → [32, 4, 4]

            nn.Flatten(),                          # → 512
            nn.Linear(512, 64),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(64, 2),
            nn.Sigmoid(),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


if __name__ == "__main__":
    m = FluencyCNN()
    dummy = torch.rand(1, 1, 64, 128)
    out = m(dummy)
    print(f"Model output shape: {out.shape}")   # [1, 2]
    print(f"Parameter count: {sum(p.numel() for p in m.parameters()):,}")
