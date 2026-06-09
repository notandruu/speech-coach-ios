import XCTest
import CoreML
@testable import OnDeviceSpeechCoach

final class ModelInputBuilderTests: XCTestCase {
    private let builder = ModelInputBuilder()
    private let expectedCount = AppConstants.Audio.melBins * AppConstants.Audio.melFrames

    func testValidInputProducesCorrectShape() throws {
        let input = Array(repeating: Float(0.5), count: expectedCount)
        let array = try builder.buildInput(from: input)

        XCTAssertEqual(array.shape.count, 4)
        XCTAssertEqual(array.shape[0].intValue, 1)
        XCTAssertEqual(array.shape[1].intValue, 1)
        XCTAssertEqual(array.shape[2].intValue, AppConstants.Audio.melBins)
        XCTAssertEqual(array.shape[3].intValue, AppConstants.Audio.melFrames)
    }

    func testValuesArePreserved() throws {
        var input = Array(repeating: Float(0.0), count: expectedCount)
        input[0] = 0.123
        input[expectedCount - 1] = 0.987

        let array = try builder.buildInput(from: input)
        XCTAssertEqual(array[0].floatValue, 0.123, accuracy: 0.0001)
        XCTAssertEqual(array[expectedCount - 1].floatValue, 0.987, accuracy: 0.0001)
    }

    func testInsufficientDataThrows() {
        let tooShort = Array(repeating: Float(0), count: 100)
        XCTAssertThrowsError(try builder.buildInput(from: tooShort)) { error in
            guard case ModelInputError.insufficientData = error else {
                XCTFail("Expected insufficientData error")
                return
            }
        }
    }

    func testExactSizeInput() throws {
        let exact = Array(repeating: Float(1.0), count: expectedCount)
        XCTAssertNoThrow(try builder.buildInput(from: exact))
    }

    func testLargerThanNeededInputSucceeds() throws {
        let large = Array(repeating: Float(0.5), count: expectedCount + 1000)
        XCTAssertNoThrow(try builder.buildInput(from: large))
    }
}
