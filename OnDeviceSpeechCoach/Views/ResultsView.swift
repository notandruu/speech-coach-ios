import SwiftUI

struct ResultsView: View {
    let breakdown: ScoreBreakdown
    let prompt: PracticePrompt
    @State private var viewModel: ResultsViewModel
    @Environment(\.dismiss) private var dismiss

    init(breakdown: ScoreBreakdown, prompt: PracticePrompt) {
        self.breakdown = breakdown
        self.prompt = prompt
        _viewModel = State(wrappedValue: ResultsViewModel(breakdown: breakdown, prompt: prompt))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overallSection
                scoresGrid
                metricsSection
                feedbackSection
                actionRow
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { viewModel.onAppear() }
    }

    // MARK: - Sections

    private var overallSection: some View {
        VStack(spacing: 8) {
            ScoreRingView(score: breakdown.overall, label: "Overall", size: 140, animate: viewModel.animateScores)
            Text(breakdown.overallGrade)
                .font(.title3.bold())
                .foregroundStyle(gradeColor)
            Text(prompt.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var scoresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ScoreRingView(score: breakdown.pace, label: "Pace", size: 90, animate: viewModel.animateScores)
            ScoreRingView(score: breakdown.pauses, label: "Pauses", size: 90, animate: viewModel.animateScores)
            ScoreRingView(score: breakdown.clarity, label: "Clarity", size: 90, animate: viewModel.animateScores)
            ScoreRingView(score: breakdown.volumeConsistency, label: "Volume", size: 90, animate: viewModel.animateScores)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Details")
                .font(.headline)
                .padding(.bottom, 8)

            Group {
                MetricRowView(
                    label: "Words per minute",
                    value: "\(Int(breakdown.wordsPerMinute)) WPM",
                    systemImage: "speedometer"
                )
                Divider()
                MetricRowView(
                    label: "Duration",
                    value: String(format: "%.1f s", breakdown.durationSeconds),
                    systemImage: "timer"
                )
                Divider()
                MetricRowView(
                    label: "Pauses detected",
                    value: "\(breakdown.pauseCount)",
                    systemImage: "pause.circle"
                )
                Divider()
                MetricRowView(
                    label: "Longest pause",
                    value: String(format: "%.1f s", breakdown.longestPauseSeconds),
                    systemImage: "clock.badge.exclamationmark"
                )
                Divider()
                MetricRowView(
                    label: "Model confidence",
                    value: "\(Int(breakdown.confidence * 100))%",
                    systemImage: "brain.head.profile"
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Feedback")
                .font(.headline)
            ForEach(breakdown.feedback) { item in
                FeedbackCardView(feedback: item)
            }
        }
    }

    private var actionRow: some View {
        NavigationLink {
            RecordingView(prompt: prompt)
        } label: {
            Label("Try Again", systemImage: "arrow.counterclockwise")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.12))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.bottom, 8)
    }

    private var gradeColor: Color {
        switch breakdown.overall {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}

#Preview {
    NavigationStack {
        ResultsView(breakdown: .preview, prompt: PracticePrompt.samples[1])
    }
}
