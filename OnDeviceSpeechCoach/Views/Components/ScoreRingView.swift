import SwiftUI

struct ScoreRingView: View {
    let score: Double
    let label: String
    var size: CGFloat = 120
    var animate: Bool = true

    @State private var progress: Double = 0

    private var color: Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return Color.orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
            VStack(spacing: 2) {
                Text("\(Int(score))")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: size * 0.11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animate {
                progress = score
            } else {
                progress = score
            }
        }
        .onChange(of: score) { _, new in
            progress = new
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ScoreRingView(score: 88, label: "Overall")
        ScoreRingView(score: 72, label: "Pace", size: 80)
        ScoreRingView(score: 55, label: "Clarity", size: 80)
    }
    .padding()
}
