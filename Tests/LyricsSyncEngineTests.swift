import XCTest
@testable import LiveLyricsCore

final class LyricsSyncEngineTests: XCTestCase {

    private let lines = [
        LyricLine(id: 0, time: 10, text: "A"),
        LyricLine(id: 1, time: 20, text: "B"),
        LyricLine(id: 2, time: 30, text: "C"),
    ]

    func testReturnsNilBeforeFirstLine() {
        XCTAssertNil(LyricsSyncEngine.activeIndex(in: lines, at: 5))
    }

    func testReturnsActiveLineExactBoundary() {
        XCTAssertEqual(LyricsSyncEngine.activeIndex(in: lines, at: 20), 1)
    }

    func testReturnsActiveLineBetweenBoundaries() {
        XCTAssertEqual(LyricsSyncEngine.activeIndex(in: lines, at: 25), 1)
    }

    func testReturnsLastLineAfterEnd() {
        XCTAssertEqual(LyricsSyncEngine.activeIndex(in: lines, at: 999), 2)
    }

    func testEmptyLinesReturnsNil() {
        XCTAssertNil(LyricsSyncEngine.activeIndex(in: [], at: 10))
    }

    func testTimeUntilNextLine() {
        let delta = LyricsSyncEngine.timeUntilNextLine(in: lines, at: 12)
        XCTAssertEqual(delta ?? -1, 8, accuracy: 0.001)
    }
}
