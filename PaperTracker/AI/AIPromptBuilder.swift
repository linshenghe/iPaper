import Foundation

/// Builds prompts for the AI to extract structured paper info from raw text.
enum AIPromptBuilder {
    static func buildExtractionPrompt(rawText: String) -> String {
        """
        You are a structured data extractor. From the user's raw text, extract academic paper information.

        Return ONLY valid JSON (no markdown, no explanation):

        {
          "title": "paper title",
          "journal": "target journal name",
          "status": "Writing | Submitted | R&R | Accepted | Published",
          "deadline": "YYYY-MM-DD or empty string",
          "note": "any relevant notes",
          "confidence": 0.0-1.0
        }

        Rules:
        - Use empty string "" for unknown fields.
        - Status must be one of: Writing, Submitted, R&R, Accepted, Published.
        - deadline must be YYYY-MM-DD format or empty string.
        - confidence is your confidence score 0.0-1.0 across all fields.

        Raw text:
        \(rawText)
        """
    }
}
