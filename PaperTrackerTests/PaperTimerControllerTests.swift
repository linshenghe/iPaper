import XCTest
@testable import PaperTracker

@MainActor
final class PaperTimerControllerTests: XCTestCase {
    var tempDir: URL!
    var dataURL: URL!
    var dataStore: DataStore!
    var controller: PaperTimerController!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("papertracker-timer-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        dataURL = tempDir.appendingPathComponent("data.json")
        dataStore = DataStore(dataURL: dataURL)
        controller = PaperTimerController(dataStore: dataStore)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Mutual exclusion

    func test_start_autoStopsOtherRunningPaper() throws {
        let p1 = makePaper(id: "p1", isRunning: true, totalSeconds: 100)
        let p2 = makePaper(id: "p2", isRunning: false)
        dataStore.appData = AppData(papers: [p1, p2])

        controller.start(paperID: "p2")

        let papers = dataStore.appData.papers
        let updated1 = papers.first(where: { $0.id == "p1" })!
        let updated2 = papers.first(where: { $0.id == "p2" })!
        XCTAssertFalse(updated1.isRunning)
        XCTAssertTrue(updated2.isRunning)
    }

    // MARK: - Stop accumulates seconds

    func test_stop_accumulatesTotalSeconds() throws {
        let p1 = makePaper(id: "p1", isRunning: true, totalSeconds: 10, sessionStart: Date().addingTimeInterval(-90))
        dataStore.appData = AppData(papers: [p1])

        controller.stop(paperID: "p1")

        let updated = dataStore.appData.papers.first(where: { $0.id == "p1" })!
        XCTAssertFalse(updated.isRunning)
        XCTAssertGreaterThanOrEqual(updated.totalSeconds, 95)  // 10 + ~90 seconds
    }

    // MARK: - Stop creates session

    func test_stop_createsSession() throws {
        let p1 = makePaper(id: "p1", isRunning: true, totalSeconds: 0, sessionStart: Date().addingTimeInterval(-60))
        dataStore.appData = AppData(papers: [p1])
        let sessionCountBefore = dataStore.appData.sessions.count

        controller.stop(paperID: "p1")

        XCTAssertEqual(dataStore.appData.sessions.count, sessionCountBefore + 1)
        let session = dataStore.appData.sessions.last!
        XCTAssertEqual(session.type, .paper)
        XCTAssertEqual(session.targetId, "p1")
        XCTAssertGreaterThan(session.durationSeconds, 0)
        XCTAssertEqual(session.source, .timer)
    }

    // MARK: - Recovery

    func test_recoverIfNeeded_creditsElapsedTime() throws {
        let sessionStart = Date().addingTimeInterval(-120)
        let p1 = makePaper(id: "p1", isRunning: true, totalSeconds: 50, sessionStart: sessionStart)
        dataStore.appData = AppData(papers: [p1])

        controller.recoverIfNeeded()

        let recovered = dataStore.appData.papers.first(where: { $0.id == "p1" })!
        XCTAssertTrue(recovered.isRunning)
        XCTAssertGreaterThanOrEqual(recovered.totalSeconds, 165)  // 50 + ~120s
    }

    // MARK: - displayedSeconds

    func test_displayedSeconds_returnsTotalWhenNotRunning() {
        let p1 = makePaper(id: "p1", isRunning: false, totalSeconds: 3600)
        let now = Date()
        let displayed = controller.displayedSeconds(for: p1, now: now)
        XCTAssertEqual(displayed, 3600)
    }

    func test_displayedSeconds_addsElapsedWhenRunning() {
        let sessionStart = Date().addingTimeInterval(-30)
        let p1 = makePaper(id: "p1", isRunning: true, totalSeconds: 100, sessionStart: sessionStart)
        let now = Date()
        let displayed = controller.displayedSeconds(for: p1, now: now)
        XCTAssertGreaterThanOrEqual(displayed, 125)  // 100 + ~30s
    }

    // MARK: - Helpers

    private func makePaper(id: String, isRunning: Bool, totalSeconds: Int = 0, sessionStart: Date? = nil) -> Paper {
        Paper(
            id: id,
            title: "Test \(id)",
            status: .writing,
            journal: "",
            deadline: nil,
            totalSeconds: totalSeconds,
            isRunning: isRunning,
            sessionStart: sessionStart,
            createdAt: Date(),
            updatedAt: Date(),
            note: ""
        )
    }
}
