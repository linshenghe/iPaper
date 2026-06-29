import Foundation

/// CSV export for papers, reviews, sessions. RFC 4180 style.
enum CSVExporter {
    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    // MARK: - Papers

    static func exportPapers(_ papers: [Paper]) -> String {
        let header = "title,status,journal,deadline,total_seconds,total_hours,note"
        let rows = papers.map { paper in
            let deadlineStr = paper.deadline
                .map { DateFormatting.displayFormatter.string(from: $0) } ?? ""
            let hours = String(format: "%.1f", Double(paper.totalSeconds) / 3600.0)
            return [
                escape(paper.title),
                escape(paper.status.rawValue),
                escape(paper.journal),
                escape(deadlineStr),
                "\(paper.totalSeconds)",
                hours,
                escape(paper.note),
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Reviews

    static func exportReviews(_ reviews: [Review]) -> String {
        let header = "journal,deadline,status,note"
        let rows = reviews.map { review in
            let deadlineStr = review.deadline
                .map { DateFormatting.displayFormatter.string(from: $0) } ?? ""
            let statusStr = review.status == .completed ? "Completed" : "In Progress"
            return [
                escape(review.journal),
                escape(deadlineStr),
                escape(statusStr),
                escape(review.note),
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Sessions

    static func exportSessions(_ sessions: [Session]) -> String {
        let header = "type,target,start,end,duration_seconds,duration_minutes,note"
        let rows = sessions.map { session in
            let startStr = DateFormatting.isoFormatter.string(from: session.startedAt)
            let endStr = session.endedAt.map { DateFormatting.isoFormatter.string(from: $0) } ?? ""
            let minutes = String(format: "%.1f", Double(session.durationSeconds) / 60.0)
            return [
                escape(session.type.rawValue),
                escape(session.targetName),
                escape(startStr),
                escape(endStr),
                "\(session.durationSeconds)",
                minutes,
                escape(session.note),
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - All-in-one

    static func exportAll(data: AppData) -> (papersCSV: String, reviewsCSV: String, sessionsCSV: String) {
        (
            exportPapers(data.papers),
            exportReviews(data.reviews),
            exportSessions(data.sessions)
        )
    }
}
