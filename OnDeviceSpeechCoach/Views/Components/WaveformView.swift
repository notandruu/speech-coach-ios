import SwiftUI

struct LiveLevelMeterView: View {
    let level: Float  // 0.0–1.0

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { bar in
                    let threshold = Float(bar) / 30
                    Capsule()
                        .fill(barColor(threshold: threshold, level: level))
                        .frame(width: (geo.size.width - 60) / 30, height: barHeight(bar: bar, geo: geo))
                        .animation(.easeInOut(duration: 0.05), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func barHeight(bar: Int, geo: GeometryProxy) -> CGFloat {
        let base: CGFloat = 4
        let mid = 15
        let maxExtra = geo.size.height - base
        let centrality = 1.0 - abs(Double(bar - mid)) / Double(mid)
        return base + maxExtra * CGFloat(centrality) * 0.6
    }

    private func barColor(threshold: Float, level: Float) -> Color {
        guard level >= threshold else { return Color(.systemGray5) }
        switch threshold {
        case 0..<0.6: return .green
        case 0.6..<0.85: return .yellow
        default: return .red
        }
    }
}

struct StaticWaveformView: View {
    let samples: [Float]

    var body: some View {
        GeometryReader { geo in
            if samples.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 2)
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                let step = max(1, samples.count / Int(geo.size.width / 3))
                let bars = stride(from: 0, to: samples.count, by: step).map { samples[$0] }

                HStack(alignment: .center, spacing: 1.5) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { _, value in
                        Capsule()
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: 2, height: max(4, geo.size.height * CGFloat(value)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

#Preview("Meter") {
    LiveLevelMeterView(level: 0.5)
        .frame(height: 60)
        .padding()
}

#Preview("Waveform") {
    StaticWaveformView(samples: (0..<100).map { _ in Float.random(in: 0.1...0.9) })
        .frame(height: 60)
        .padding()
}
