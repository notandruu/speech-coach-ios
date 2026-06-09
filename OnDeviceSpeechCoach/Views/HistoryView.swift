import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                viewModel.configure(context: context)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Sessions Yet",
            systemImage: "mic.slash",
            description: Text("Complete your first practice session to see your history here.")
        )
    }

    private var sessionList: some View {
        List {
            summarySection
            ForEach(viewModel.sessions) { session in
                sessionRow(session)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var summarySection: some View {
        Section("Summary") {
            HStack(spacing: 0) {
                statCell(label: "Average", value: viewModel.averageScore.map { "\(Int($0))" } ?? "—")
                Divider()
                statCell(label: "Best", value: viewModel.bestScore.map { "\(Int($0))" } ?? "—")
                Divider()
                statCell(label: "Sessions", value: "\(viewModel.sessions.count)")
            }

            if let area = viewModel.mostCommonWeakArea {
                Label("Most common improvement area: **\(area)**", systemImage: "chart.bar.xaxis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func sessionRow(_ session: PracticeSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.promptTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                scoreLabel(session.overallScore)
            }
            HStack(spacing: 16) {
                Text(session.createdAt, style: .date)
                Text(String(format: "%.0f WPM", session.wordsPerMinute))
                Text("\(session.pauseCount) pauses")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func scoreLabel(_ score: Double) -> some View {
        Text("\(Int(score))")
            .font(.headline.monospacedDigit())
            .foregroundStyle(scoreColor(score))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(scoreColor(score).opacity(0.12))
            .clipShape(Capsule())
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PersistenceController.preview.container)
}
