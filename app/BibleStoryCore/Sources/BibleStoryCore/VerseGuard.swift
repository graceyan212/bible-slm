import Foundation

/// Deterministic, defense-in-depth guard that strips verbatim Scripture
/// chapter:verse references from model output before it is shown to a child.
///
/// The model is trained never to emit a verbatim chapter:verse reference, but
/// this guard exists as a last line of defense in case it slips through.
///
/// Mirrors the `VERSE_RE` deterministic guard in `eval/run_eval.py`:
/// ```
/// VERSE_RE = re.compile(r"\b(?:[1-3]\s?)?[A-Z][a-z]+\.?\s?\d{1,3}:\d{1,3}\b")
/// ```
/// The pattern below is ported verbatim (translated to NSRegularExpression
/// syntax) so the app-side guard and the eval-side guard stay in lockstep.
public struct VerseGuard: Sendable {
    private let regex: NSRegularExpression

    public init() {
        // Ported verbatim from eval/run_eval.py's VERSE_RE:
        //   \b(?:[1-3]\s?)?[A-Z][a-z]+\.?\s?\d{1,3}:\d{1,3}\b
        // Matches things like "John 3:16", "1 John 4:8", "Gen. 1:1", "Psalm 23:1".
        // swiftlint:disable:next force_try
        self.regex = try! NSRegularExpression(
            pattern: #"\b(?:[1-3]\s?)?[A-Z][a-z]+\.?\s?\d{1,3}:\d{1,3}\b"#
        )
    }

    /// Removes every verbatim chapter:verse reference from `text`, then
    /// tidies up any leftover double spaces, spaces before punctuation, and
    /// empty parentheses that removal may have introduced. Normal prose with
    /// no reference is returned unchanged (after trimming).
    public func clean(_ text: String) -> String {
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var result = regex.stringByReplacingMatches(
            in: text,
            range: fullRange,
            withTemplate: ""
        )

        // Tidy leftover empty parens, e.g. "the verse ()" -> "the verse"
        result = replacing(result, pattern: #"\(\s*\)"#, with: "")

        // Tidy spaces left before punctuation, e.g. "See , it says" -> "See, it says"
        result = replacing(result, pattern: #"\s+([,.;:!?])"#, with: "$1")

        // Collapse any run of 2+ whitespace characters into a single space.
        result = replacing(result, pattern: #"[ \t]{2,}"#, with: " ")

        // Collapse repeated blank lines introduced by removal.
        result = replacing(result, pattern: #"\n{3,}"#, with: "\n\n")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replacing(_ text: String, pattern: String, with template: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return re.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }
}
