import Foundation

struct MigrationResult {
    let data: AppData
    let warnings: [String]
}

enum DataMigration {
    private static let statusMap: [String: PaperStatus] = [
        "写作中": .writing,
        "投稿中": .submitted,
        "R&R": .rnr,
        "修改中": .rnr,
        "已接受": .accepted,
        "已发表": .published,
    ]

    // MARK: - Legacy JSON structure

    private struct LegacyPaper: Decodable {
        let id: String?
        let title: String
        let status: String?
        let journal: String?
        let deadline: LegacyDateValue?
        let totalSeconds: Int?
        let isRunning: Bool?
        let sessionStart: LegacySessionStart?
        let createdAt: String?

        // Fields that might be missing
        let note: String?
        let updatedAt: String?
    }

    private struct LegacyReview: Decodable {
        let id: String?
        let journal: String?
        let deadline: LegacyDateValue?
        let status: String?
        let note: String?
        let createdAt: String?
        let updatedAt: String?
    }

    private struct LegacySession: Decodable {
        let id: String?
        let type: String?
        let targetId: String?
        let targetName: String?
        let startedAt: String?
        let endedAt: String?
        let durationSeconds: Int?
        let note: String?
        let source: String?
    }

    private struct LegacyData: Decodable {
        let papers: [LegacyPaper]?
        let reviews: [LegacyReview]?
        let sessions: [LegacySession]?
    }

    // MARK: - Flexible value types

    private enum LegacyDateValue: Decodable {
        case string(String)
        case number(Double)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else if let num = try? container.decode(Double.self) {
                self = .number(num)
            } else {
                self = .string("")
            }
        }

        var date: Date? {
            switch self {
            case .string(let str):
                guard !str.isEmpty else { return nil }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = formatter.date(from: str) { return d }
                formatter.formatOptions = [.withInternetDateTime]
                return formatter.date(from: str)
            case .number(let num):
                // Unix timestamp: if > 1e12 treat as millis
                let seconds = num > 1_000_000_000_000 ? num / 1000 : num
                return Date(timeIntervalSince1970: seconds)
            }
        }
    }

    private enum LegacySessionStart: Decodable {
        case number(Double)
        case null

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let num = try? container.decode(Double.self) {
                self = .number(num)
            } else {
                self = .null
            }
        }

        var date: Date? {
            switch self {
            case .number(let num):
                let seconds = num > 1_000_000_000_000 ? num / 1000 : num
                return Date(timeIntervalSince1970: seconds)
            case .null:
                return nil
            }
        }
    }

    // MARK: - Migration

    static func migrateLegacyJSON(_ data: Data) throws -> MigrationResult {
        let legacy = try JSONDecoder().decode(LegacyData.self, from: data)
        var warnings: [String] = []

        let papers = (legacy.papers ?? []).map { lp -> Paper in
            var ws: [String] = []

            let resolvedStatus: PaperStatus
            if let rawStatus = lp.status {
                if let mapped = statusMap[rawStatus] {
                    resolvedStatus = mapped
                } else {
                    resolvedStatus = .writing
                    ws.append("「\(lp.title)」状态「\(rawStatus)」无法识别，已设为「写作中」")
                }
            } else {
                resolvedStatus = .writing
                ws.append("「\(lp.title)」缺少状态，已设为「写作中」")
            }

            if lp.note == nil { ws.append("「\(lp.title)」缺少 note，已设为空") }
            if lp.updatedAt == nil { ws.append("「\(lp.title)」缺少 updatedAt，已使用 createdAt") }

            let createdAtDate = parseISO(lp.createdAt)
            let updatedAtDate = lp.updatedAt.flatMap(parseISO) ?? createdAtDate ?? Date()

            warnings.append(contentsOf: ws)

            return Paper(
                id: lp.id ?? UUID().uuidString,
                title: lp.title,
                status: resolvedStatus,
                journal: lp.journal ?? "",
                deadline: lp.deadline?.date,
                totalSeconds: lp.totalSeconds ?? 0,
                isRunning: lp.isRunning ?? false,
                sessionStart: lp.sessionStart?.date,
                createdAt: createdAtDate ?? Date(),
                updatedAt: updatedAtDate,
                note: lp.note ?? ""
            )
        }

        let reviews = (legacy.reviews ?? []).map { lr -> Review in
            let createdAtDate = parseISO(lr.createdAt) ?? Date()
            return Review(
                id: lr.id ?? UUID().uuidString,
                journal: lr.journal ?? "",
                deadline: lr.deadline?.date,
                status: lr.status.map { $0 == "已完成" || $0 == "Completed" ? ReviewStatus.completed : .inProgress } ?? .inProgress,
                note: lr.note ?? "",
                createdAt: createdAtDate,
                updatedAt: lr.updatedAt.flatMap(parseISO) ?? createdAtDate
            )
        }

        let sessions = (legacy.sessions ?? []).map { ls -> Session in
            let startedAtDate = parseISO(ls.startedAt) ?? Date()
            return Session(
                id: ls.id ?? UUID().uuidString,
                type: ls.type == "Review" ? .review : .paper,
                targetId: ls.targetId ?? "",
                targetName: ls.targetName ?? "",
                startedAt: startedAtDate,
                endedAt: ls.endedAt.flatMap(parseISO),
                durationSeconds: ls.durationSeconds ?? 0,
                note: ls.note ?? "",
                source: ls.source == "Manually" || ls.source == "Manual" ? .manual : .timer
            )
        }

        let appData = AppData(
            papers: papers,
            reviews: reviews,
            sessions: sessions,
            settings: AppSettings(hasImportedLegacyData: true)
        )

        return MigrationResult(data: appData, warnings: warnings)
    }

    private static func parseISO(_ string: String?) -> Date? {
        guard let str = string, !str.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: str) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: str)
    }
}
