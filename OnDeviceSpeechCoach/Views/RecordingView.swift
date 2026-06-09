import SwiftUI
import SwiftData

struct RecordingView: View {
    let prompt: PracticePrompt
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RecordingViewModel

    init(prompt: PracticePrompt) {
        self.prompt = prompt
        _viewModel = State(wrappedValue: RecordingViewModel(prompt: prompt))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .requestingPermission:
                idleView
            case .permissionDenied:
                permissionDeniedView
            case .recording:
                recordingView
            case .processing:
                processingView
            case .done(let breakdown):
                ResultsView(breakdown: breakdown, prompt: prompt)
            case .failed(let message):
                errorView(message: message)
            }
        }
        .navigationTitle(prompt.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(context: context)
        }
    }

    // MARK: - States

    private var idleView: some View {
        ScrollView {
            VStack(spacing: 28) {
                promptCard
                privacyBadge
                startButton
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var recordingView: some View {
        VStack(spacing: 28) {
            Spacer()
            promptCard
                .padding(.horizontal)
            timerDisplay
            LiveLevelMeterView(level: viewModel.normalizedLevel)
                .frame(height: 60)
                .padding(.horizontal)
            privacyBadge
            Spacer()
            stopButton
                .padding(.horizontal)
                .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing your speech…")
                .font(.headline)
            Text("This runs entirely on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Microphone Access Required", systemImage: "mic.slash")
        } description: {
            Text("Open Settings and allow microphone access to record your speech. No audio is uploaded.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") { viewModel.retry() }
                .buttonStyle(.borderedProminent)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Subviews

    private var promptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(prompt.text)
                .font(.body)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var timerDisplay: some View {
        Text(formatTime(viewModel.elapsedSeconds))
            .font(.system(size: 54, weight: .thin, design: .monospaced))
            .foregroundStyle(.primary)
    }

    private var privacyBadge: some View {
        Label("Audio stays on this device", systemImage: "lock.shield")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var startButton: some View {
        Button {
            Task { await viewModel.startRecording() }
        } label: {
            Label("Start Recording", systemImage: "mic.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var stopButton: some View {
        Button {
            Task { await viewModel.stopRecording() }
        } label: {
            Label("Stop & Analyze", systemImage: "stop.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

#Preview {
    NavigationStack {
        RecordingView(prompt: PracticePrompt.samples[1])
    }
    .modelContainer(PersistenceController.preview.container)
}
