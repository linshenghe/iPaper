import XCTest
@testable import PaperTracker

final class CSVExporterTests: XCTestCase {
    func test_papersHeader() {
        let csv = CSVExporter.exportPapers([])
        let header = csv.components(separatedBy: "\n").first
        XCTAssertEqual(header, "title,status,journal,deadline,total_seconds,total_hours,note")
    }

    func test_reviewsHeader() {
        let csv = CSVExporter.exportReviews([])
        let header = csv.components(separatedBy: "\n").first
        XCTAssertEqual(header, "journal,deadline,status,note")
    }

    func test_sessionsHeader() {
        let csv = CSVExporter.exportSessions([])
        let header = csv.components(separatedBy: "\n").first
        XCTAssertEqual(header, "type,target,start,end,duration_seconds,duration_minutes,note")
    }

    func test_paperRow_escapesSpecialCharacters() {
        let paper = Paper(
            id: "p1", title: "A, \"comma\" test",
            status: .writing, journal: "Journal", deadline: nil,
            totalSeconds: 3600, isRunning: false, sessionStart: nil,
            createdAt: Date(), updatedAt: Date(), note: "测试"
        )
        let csv = CSVExporter.exportPapers([paper])
        let lines = csv.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2) // header + 1 row
        XCTAssertTrue(lines[1].contains("\"A, \"\"comma\"\" test\""))
    }
}
