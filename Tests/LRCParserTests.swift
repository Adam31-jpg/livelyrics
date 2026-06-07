import XCTest
@testable import LiveLyricsCore

/// Tests du parseur LRC. Logique pure → tournent en quelques ms, sans appareil ni réseau.
final class LRCParserTests: XCTestCase {

    func testParsesBasicTimestamps() {
        let lrc = """
        [00:12.00]Première ligne
        [00:17.20]Deuxième ligne
        [00:21.10]Troisième ligne
        """
        let lines = LRCParser.parse(lrc)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].time, 12.0, accuracy: 0.001)
        XCTAssertEqual(lines[1].time, 17.2, accuracy: 0.001)
        XCTAssertEqual(lines[0].text, "Première ligne")
    }

    func testIgnoresMetadataTags() {
        let lrc = """
        [ar:Artiste]
        [ti:Titre]
        [length:03:21]
        [00:05.00]Vraie parole
        """
        let lines = LRCParser.parse(lrc)
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text, "Vraie parole")
    }

    func testHandlesMultipleTimestampsPerLine() {
        let lrc = "[00:10.00][00:40.00]Refrain répété"
        let lines = LRCParser.parse(lrc)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].time, 10.0, accuracy: 0.001)
        XCTAssertEqual(lines[1].time, 40.0, accuracy: 0.001)
        XCTAssertEqual(lines[0].text, lines[1].text)
    }

    func testHandlesMillisecondFractions() {
        let lines = LRCParser.parse("[01:02.345]Test")
        XCTAssertEqual(lines[0].time, 62.345, accuracy: 0.001)
    }

    func testBlankLineDetected() {
        let lines = LRCParser.parse("[00:30.00]")
        XCTAssertEqual(lines.count, 1)
        XCTAssertTrue(lines[0].isBlank)
    }
}
