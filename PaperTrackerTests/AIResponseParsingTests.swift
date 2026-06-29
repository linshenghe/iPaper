import XCTest
@testable import PaperTracker

@MainActor
final class AIResponseParsingTests: XCTestCase {
    private let service = AIService()

    func test_parse_validJSON() throws {
        let json = """
        {
          "title": "中国引文偏见",
          "journal": "Nature",
          "status": "Submitted",
          "deadline": "2026-12-31",
          "note": "需要修改方法",
          "confidence": 0.85
        }
        """
        let result = try service.parseContent(json)
        XCTAssertEqual(result.title, "中国引文偏见")
        XCTAssertEqual(result.journal, "Nature")
        XCTAssertEqual(result.status, "Submitted")
        XCTAssertEqual(result.confidence, 0.85)
    }

    func test_parse_stripsFencedCodeBlock() throws {
        let fenced = """
        ```json
        {
          "title": "Test",
          "journal": "",
          "status": "Writing",
          "deadline": "",
          "note": "",
          "confidence": 0.5
        }
        ```
        """
        let result = try service.parseContent(fenced)
        XCTAssertEqual(result.title, "Test")
    }

    func test_parse_invalidJSON_throws() {
        let bad = "Not JSON at all just some text"
        XCTAssertThrowsError(try service.parseContent(bad)) { error in
            XCTAssertTrue(error is AIError)
        }
    }

    func test_parse_missingFields_fillsEmpty() throws {
        let json = """
        {
          "title": "Only Title",
          "journal": "",
          "status": "",
          "deadline": "",
          "note": "",
          "confidence": 0.0
        }
        """
        let result = try service.parseContent(json)
        XCTAssertEqual(result.title, "Only Title")
        XCTAssertEqual(result.status, "")
    }

    func test_parse_dateFallback() throws {
        let json = """
        {
          "title": "",
          "journal": "",
          "status": "",
          "deadline": "12/31/2026",
          "note": "",
          "confidence": 0.7
        }
        """
        let result = try service.parseContent(json)
        XCTAssertEqual(result.deadline, "12/31/2026")
    }

    func test_selectingFields_keepsOnlySelectedSuggestionValues() {
        let suggestion = AISuggestion(
            title: "Selected title",
            journal: "Ignored journal",
            status: "Submitted",
            deadline: "2026-12-31",
            note: "Ignored note",
            confidence: 0.7
        )

        let selected = suggestion.onlyFields(["title", "deadline"])

        XCTAssertEqual(selected.title, "Selected title")
        XCTAssertEqual(selected.deadline, "2026-12-31")
        XCTAssertEqual(selected.journal, "")
        XCTAssertEqual(selected.status, "")
        XCTAssertEqual(selected.note, "")
        XCTAssertEqual(selected.confidence, 0.7)
    }
}
