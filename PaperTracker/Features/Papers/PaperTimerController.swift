import Combine
import Foundation

/// Manages timer lifecycle: start, stop, recover, and per-row display.
@MainActor
final class PaperTimerController: ObservableObject {
    private let dataStore: DataStore
    @Published var tick = Date()
    private var timerTask: Task<Void, Never>?

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Tick

    private func startTicking() {
        guard timerTask == nil else { return }
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                tick = Date()
            }
        }
    }

    private func stopTickingIfIdle() {
        let hasRunning = dataStore.appData.papers.contains(where: \.isRunning)
        if !hasRunning {
            timerTask?.cancel()
            timerTask = nil
        }
    }

    // MARK: - Start

    func start(paperID: String) {
        var papers = dataStore.appData.papers

        // Mutual exclusion: stop any other running paper
        for i in papers.indices where papers[i].isRunning && papers[i].id != paperID {
            stopInternal(&papers, paperID: papers[i].id)
        }

        guard let idx = papers.firstIndex(where: { $0.id == paperID }),
              !papers[idx].isRunning else { return }

        papers[idx].isRunning = true
        papers[idx].sessionStart = Date()
        papers[idx].updatedAt = Date()
        dataStore.appData.papers = papers
        startTicking()
    }

    // MARK: - Stop

    func stop(paperID: String) {
        var papers = dataStore.appData.papers
        stopInternal(&papers, paperID: paperID)
        dataStore.appData.papers = papers
        stopTickingIfIdle()
    }

    private func stopInternal(_ papers: inout [Paper], paperID: String) {
        guard let idx = papers.firstIndex(where: { $0.id == paperID }),
              papers[idx].isRunning else { return }

        let now = Date()
        let startedAt = papers[idx].sessionStart ?? now
        let elapsed = Int(now.timeIntervalSince(startedAt))

        papers[idx].isRunning = false
        papers[idx].totalSeconds += elapsed
        papers[idx].sessionStart = nil
        papers[idx].updatedAt = now

        // Auto-generate session
        let session = Session(
            id: UUID().uuidString,
            type: .paper,
            targetId: paperID,
            targetName: papers[idx].title,
            startedAt: startedAt,
            endedAt: now,
            durationSeconds: elapsed,
            note: "",
            source: .timer
        )
        dataStore.appData.sessions.append(session)
    }

    // MARK: - Recovery

    func recoverIfNeeded() {
        var papers = dataStore.appData.papers
        let now = Date()
        for i in papers.indices where papers[i].isRunning {
            if let start = papers[i].sessionStart {
                let elapsed = Int(now.timeIntervalSince(start))
                papers[i].totalSeconds += elapsed
                papers[i].sessionStart = now
                papers[i].updatedAt = now
            }
        }
        dataStore.appData.papers = papers
    }

    // MARK: - Display

    func displayedSeconds(for paper: Paper, now: Date) -> Int {
        guard paper.isRunning, let start = paper.sessionStart else {
            return paper.totalSeconds
        }
        let elapsed = Int(now.timeIntervalSince(start))
        return paper.totalSeconds + elapsed
    }
}
