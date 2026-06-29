import Foundation

@MainActor
final class AIService {
    private let keychain = KeychainService()

    func extractPaperInfo(from rawText: String) async throws -> AISuggestion {
        let apiKey = (try? keychain.loadAPIKey()) ?? nil
        guard let key = apiKey, !key.isEmpty else {
            throw AIError.noAPIKey
        }

        let baseURL = UserDefaults.standard.string(forKey: "aiBaseURL") ?? "https://api.openai.com/v1"
        let model = UserDefaults.standard.string(forKey: "aiModel") ?? "gpt-4o"

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": AIPromptBuilder.buildExtractionPrompt(rawText: rawText)]
            ],
            "temperature": 0.3,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid response type")
        }

        if http.statusCode == 429 { throw AIError.rateLimited }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIError.networkError("HTTP \(http.statusCode): \(body.prefix(200))")
        }

        return try parseResponse(data)
    }

    // MARK: - Parse

    private func parseResponse(_ data: Data) throws -> AISuggestion {
        // Extract OpenAI-style response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }

        return try parseContent(content)
    }

    func parseContent(_ content: String) throws -> AISuggestion {
        // Strip markdown code fences if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let raw = cleaned.data(using: .utf8) else {
            throw AIError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(AISuggestion.self, from: raw)
        } catch {
            throw AIError.invalidResponse
        }
    }
}
