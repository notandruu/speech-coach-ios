import AVFoundation

// Protocol enables testing without real device permission dialogs.
protocol MicrophonePermissionProvider {
    func currentStatus() -> AVAudioApplication.recordPermission
    func requestAccess() async -> Bool
}

final class LiveMicrophonePermission: MicrophonePermissionProvider {
    func currentStatus() -> AVAudioApplication.recordPermission {
        AVAudioApplication.shared.recordPermission
    }

    func requestAccess() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
}

enum PermissionState {
    case undetermined
    case granted
    case denied

    init(_ permission: AVAudioApplication.recordPermission) {
        switch permission {
        case .granted: self = .granted
        case .denied: self = .denied
        default: self = .undetermined
        }
    }
}
