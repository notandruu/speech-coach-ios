import XCTest
import AVFoundation
@testable import OnDeviceSpeechCoach

// MARK: - Stub permission providers

final class GrantedPermission: MicrophonePermissionProvider {
    func currentStatus() -> AVAudioApplication.recordPermission { .granted }
    func requestAccess() async -> Bool { true }
}

final class DeniedPermission: MicrophonePermissionProvider {
    func currentStatus() -> AVAudioApplication.recordPermission { .denied }
    func requestAccess() async -> Bool { false }
}

final class UndeterminedThenGranted: MicrophonePermissionProvider {
    func currentStatus() -> AVAudioApplication.recordPermission { .undetermined }
    func requestAccess() async -> Bool { true }
}

final class UndeterminedThenDenied: MicrophonePermissionProvider {
    func currentStatus() -> AVAudioApplication.recordPermission { .undetermined }
    func requestAccess() async -> Bool { false }
}

// MARK: - Tests

@MainActor
final class RecordingPermissionTests: XCTestCase {
    func testPermissionStateFromGranted() {
        let perm = GrantedPermission()
        let state = PermissionState(perm.currentStatus())
        XCTAssertEqual(state, .granted)
    }

    func testPermissionStateFromDenied() {
        let perm = DeniedPermission()
        let state = PermissionState(perm.currentStatus())
        XCTAssertEqual(state, .denied)
    }

    func testPermissionStateFromUndetermined() {
        let perm = UndeterminedThenGranted()
        let state = PermissionState(perm.currentStatus())
        XCTAssertEqual(state, .undetermined)
    }

    func testUndeterminedThenGrantedReturnsTrue() async {
        let perm = UndeterminedThenGranted()
        let granted = await perm.requestAccess()
        XCTAssertTrue(granted)
    }

    func testUndeterminedThenDeniedReturnsFalse() async {
        let perm = UndeterminedThenDenied()
        let granted = await perm.requestAccess()
        XCTAssertFalse(granted)
    }

    func testDeniedPermissionShowsDeniedState() async {
        let vm = RecordingViewModel(
            prompt: PracticePrompt.samples[0],
            permission: DeniedPermission()
        )
        await vm.startRecording()

        if case .permissionDenied = vm.state {
            // expected
        } else {
            XCTFail("Expected permissionDenied state, got \(vm.state)")
        }
    }
}
