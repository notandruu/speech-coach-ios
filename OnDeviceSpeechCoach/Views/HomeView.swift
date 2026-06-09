import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = HomeViewModel()
    @State private var showPromptSelection = false
    @State private var showHistory = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    dailyPromptCard
                    if !viewModel.recentSessions.isEmpty {
                        recentScoreSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Speech Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPromptSelection) {
                PromptSelectionView()
            }
            .task {
                viewModel.configure(context: context)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Practice")
                .font(.title2.bold())
            Text("Speak clearly. Audio stays on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var dailyPromptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(viewModel.dailyPrompt.category.rawValue.capitalized, systemImage: "mic.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                Spacer()
                Text("~\(viewModel.dailyPrompt.estimatedSeconds)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.dailyPrompt.title)
                .font(.headline)

            Text(viewModel.dailyPrompt.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 12) {
                NavigationLink {
                    RecordingView(prompt: viewModel.dailyPrompt)
                } label: {
                    Label("Start Recording", systemImage: "mic.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    showPromptSelection = true
                } label: {
                    Image(systemName: "list.bullet")
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var recentScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)

            HStack(spacing: 16) {
                scoreStat(label: "Average", value: viewModel.averageScore.map { "\(Int($0))" } ?? "—")
                Divider().frame(height: 36)
                scoreStat(label: "Best", value: viewModel.bestScore.map { "\(Int($0))" } ?? "—")
                Divider().frame(height: 36)
                scoreStat(label: "Sessions", value: "\(viewModel.recentSessions.count)")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            ForEach(viewModel.recentSessions) { session in
                recentSessionRow(session)
            }
        }
    }

    private func scoreStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func recentSessionRow(_ session: PracticeSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.promptTitle)
                    .font(.subheadline.weight(.medium))
                Text(session.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(session.overallScore))")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(scoreColor(session.overallScore))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    HomeView()
        .modelContainer(PersistenceController.preview.container)
}
