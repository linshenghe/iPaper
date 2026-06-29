import Foundation

/// Expected response shape from AI.
struct AISuggestion: Codable, Equatable {
    var title: String = ""
    var journal: String = ""
    var status: String = ""
    var deadline: String = ""
    var note: String = ""
    var confidence: Double = 0.0

    func onlyFields(_ fields: Set<String>) -> AISuggestion {
        AISuggestion(
            title: fields.contains("title") ? title : "",
            journal: fields.contains("journal") ? journal : "",
            status: fields.contains("status") ? status : "",
            deadline: fields.contains("deadline") ? deadline : "",
            note: fields.contains("note") ? note : "",
            confidence: confidence
        )
    }
}

enum AIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(String)
    case invalidResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "未配置 API key，请在 Settings 中设置。"
        case .invalidURL: return "AI Base URL 无效。"
        case .networkError(let detail): return "AI 请求失败：\(detail)"
        case .invalidResponse: return "AI 返回格式无法解析，请重试。"
        case .rateLimited: return "AI 请求频率过高，请稍后再试。"
        }
    }
}
