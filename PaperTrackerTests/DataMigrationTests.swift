import XCTest
@testable import PaperTracker

@MainActor
final class DataMigrationTests: XCTestCase {
    // MARK: - Legacy data import

    func test_migrateLegacyJSON_importsPaperCorrectly() throws {
        let json = """
        {
          "papers": [
            {
              "id": "p_001",
              "title": "中国引文偏见",
              "status": "投稿中",
              "journal": "China Policy Journal",
              "deadline": "",
              "totalSeconds": 0,
              "isRunning": false,
              "sessionStart": null,
              "createdAt": "2026-06-29T00:00:00.000Z"
            }
          ],
          "reviews": [],
          "sessions": []
        }
        """.data(using: .utf8)!

        let result = try DataMigration.migrateLegacyJSON(json)

        XCTAssertEqual(result.data.papers.count, 1)
        let paper = result.data.papers[0]
        XCTAssertEqual(paper.id, "p_001")
        XCTAssertEqual(paper.title, "中国引文偏见")
        XCTAssertEqual(paper.status, .submitted)
        // Missing note/updatedAt will produce warnings — that's expected
    }

    // MARK: - sessionStart timestamp conversion

    func test_migrate_sessionStart_millisTimestamp_convertsToDate() throws {
        let json = """
        {
          "papers": [
            {
              "id": "p_002",
              "title": "测试",
              "status": "写作中",
              "journal": "",
              "deadline": "",
              "totalSeconds": 100,
              "isRunning": true,
              "sessionStart": 1719600000000,
              "createdAt": "2026-06-29T00:00:00.000Z"
            }
          ],
          "reviews": [],
          "sessions": []
        }
        """.data(using: .utf8)!

        let result = try DataMigration.migrateLegacyJSON(json)
        let paper = result.data.papers[0]
        XCTAssertNotNil(paper.sessionStart)
    }

    func test_migrate_sessionStart_null_staysNil() throws {
        let json = """
        {
          "papers": [
            {
              "id": "p_003",
              "title": "测试",
              "status": "写作中",
              "journal": "",
              "deadline": "",
              "totalSeconds": 0,
              "isRunning": false,
              "sessionStart": null,
              "createdAt": "2026-06-29T00:00:00.000Z"
            }
          ],
          "reviews": [],
          "sessions": []
        }
        """.data(using: .utf8)!

        let result = try DataMigration.migrateLegacyJSON(json)
        XCTAssertNil(result.data.papers[0].sessionStart)
    }

    // MARK: - Missing fields get defaults + warnings

    func test_migrate_missingFields_producesWarnings() throws {
        let json = """
        {
          "papers": [
            {
              "id": "p_004",
              "title": "缺字段论文",
              "status": "写作中",
              "journal": "",
              "deadline": "",
              "totalSeconds": 0,
              "isRunning": false,
              "sessionStart": null,
              "createdAt": "2026-06-29T00:00:00.000Z"
            }
          ],
          "reviews": [],
          "sessions": []
        }
        """.data(using: .utf8)!

        let result = try DataMigration.migrateLegacyJSON(json)
        let paper = result.data.papers[0]
        // note and updatedAt auto-filled
        XCTAssertEqual(paper.note, "")
        // updatedAt should be set to createdAt
        XCTAssertEqual(paper.updatedAt, paper.createdAt)

        let hasNoteWarning = result.warnings.contains { $0.contains("note") }
        let hasUpdatedWarning = result.warnings.contains { $0.contains("updatedAt") }
        XCTAssertTrue(hasNoteWarning || hasUpdatedWarning, "Should warn about missing fields")
    }

    // MARK: - Illegal status

    func test_migrate_illegalStatus_addsWarning_preservesTitle() throws {
        let json = """
        {
          "papers": [
            {
              "id": "p_005",
              "title": "非法状态论文",
              "status": "未知状态",
              "journal": "",
              "deadline": "",
              "totalSeconds": 0,
              "isRunning": false,
              "sessionStart": null,
              "createdAt": "2026-06-29T00:00:00.000Z"
            }
          ],
          "reviews": [],
          "sessions": []
        }
        """.data(using: .utf8)!

        let result = try DataMigration.migrateLegacyJSON(json)
        let paper = result.data.papers[0]
        // Status falls back to .writing but title is preserved for identification
        XCTAssertEqual(paper.title, "非法状态论文")
        XCTAssertEqual(paper.status, .writing)

        let hasWarning = result.warnings.contains { $0.contains("非法状态论文") && $0.contains("未知状态") }
        XCTAssertTrue(hasWarning)
    }
}
