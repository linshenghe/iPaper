import XCTest
@testable import PaperTracker

@MainActor
final class DataStoreTests: XCTestCase {
    var tempDir: URL!
    var dataURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("papertracker-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        dataURL = tempDir.appendingPathComponent("data.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Init creates parent directory

    func test_init_createsParentDirectory() throws {
        let nestedURL = tempDir.appendingPathComponent("sub/data.json")
        _ = DataStore(dataURL: nestedURL)
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedURL.deletingLastPathComponent().path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    // MARK: - Missing file generates empty AppData

    func test_init_missingFile_createsEmptyAppData() throws {
        let store = DataStore(dataURL: dataURL)
        let data = store.appData
        XCTAssertEqual(data.papers.count, 0)
        XCTAssertEqual(data.reviews.count, 0)
        XCTAssertEqual(data.sessions.count, 0)
    }

    // MARK: - Corrupted file sets activeError and does not overwrite

    func test_init_corruptedJSON_setsActiveError() throws {
        try "{not json".write(to: dataURL, atomically: true, encoding: .utf8)
        let store = DataStore(dataURL: dataURL)
        XCTAssertNotNil(store.activeError)
    }

    func test_init_corruptedJSON_doesNotOverwriteFile() throws {
        try "{not json".write(to: dataURL, atomically: true, encoding: .utf8)
        _ = DataStore(dataURL: dataURL)
        let contents = try String(contentsOf: dataURL, encoding: .utf8)
        XCTAssertEqual(contents, "{not json")
    }

    // MARK: - Save and reload round-trip

    func test_saveAndReload_roundTripsData() throws {
        let store = DataStore(dataURL: dataURL)

        let paper = Paper(
            id: "p_test",
            title: "测试论文",
            status: .writing,
            journal: "测试期刊",
            deadline: nil,
            totalSeconds: 120,
            isRunning: false,
            sessionStart: nil,
            createdAt: Date(),
            updatedAt: Date(),
            note: "测试备注"
        )

        let review = Review(
            id: "r_test",
            journal: "审稿期刊",
            deadline: Date(),
            status: .inProgress,
            note: "审稿备注",
            createdAt: Date(),
            updatedAt: Date()
        )

        let session = Session(
            id: "s_test",
            type: .paper,
            targetId: "p_test",
            targetName: "测试论文",
            startedAt: Date(),
            endedAt: Date(),
            durationSeconds: 3600,
            note: "日志备注",
            source: .timer
        )

        store.appData = AppData(
            papers: [paper],
            reviews: [review],
            sessions: [session],
            settings: AppSettings()
        )

        try store.save()

        // Reload from same file
        let store2 = DataStore(dataURL: dataURL)
        let data = store2.appData

        XCTAssertEqual(data.papers.count, 1)
        XCTAssertEqual(data.papers[0].id, "p_test")
        XCTAssertEqual(data.papers[0].title, "测试论文")
        XCTAssertEqual(data.papers[0].status, .writing)
        XCTAssertEqual(data.papers[0].totalSeconds, 120)

        XCTAssertEqual(data.reviews.count, 1)
        XCTAssertEqual(data.reviews[0].id, "r_test")

        XCTAssertEqual(data.sessions.count, 1)
        XCTAssertEqual(data.sessions[0].id, "s_test")
        XCTAssertEqual(data.sessions[0].durationSeconds, 3600)
    }

    // MARK: - Save error reporting

    func test_saveReportingFailure_setsActiveError() throws {
        let directoryURL = tempDir.appendingPathComponent("not-a-file")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let store = DataStore(dataURL: directoryURL)
        let saved = store.saveOrReportError()

        XCTAssertFalse(saved)
        XCTAssertEqual(store.activeError?.title, "尚未保存到磁盘")
        XCTAssertNil(store.appData.settings.lastSavedAt)
    }
}
