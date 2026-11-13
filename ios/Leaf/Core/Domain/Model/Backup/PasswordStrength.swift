import SwiftUI

/// Password strength levels, passphrase evaluation rules, and informative guidance for backup encryption passphrases.
/// Enforces a minimum length of 12 characters and rewards unpredictable, long passphrases (such as Diceware phrases).
/// Avoids arbitrary mandates for uppercase, digits, or symbols, and prevents spaces or repetitive patterns from falsely inflating scores.
public enum PasswordStrength: Int, CaseIterable, Sendable {
    case veryWeak = 0
    case weak = 1
    case fair = 2
    case strong = 3
    case veryStrong = 4

    public var title: String {
        switch self {
        case .veryWeak: return "Too Short"
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }

    public var color: Color {
        switch self {
        case .veryWeak, .weak: return LeafTheme.expenseCoral
        case .fair: return LeafTheme.warningGold
        case .strong: return LeafTheme.brandEmerald
        case .veryStrong: return Color.green
        }
    }

    public var progressRatio: Double {
        switch self {
        case .veryWeak: return 0.15
        case .weak: return 0.35
        case .fair: return 0.60
        case .strong: return 0.85
        case .veryStrong: return 1.0
        }
    }

    public var guidanceMessage: String {
        switch self {
        case .veryWeak:
            return "Passphrase must contain at least 12 characters."
        case .weak:
            return "Too predictable or repetitive. Use multiple distinct words or unpredictable characters."
        case .fair:
            return "Moderate strength. Adding another distinct word or more characters will make it much stronger."
        case .strong:
            return "Strong passphrase with good entropy and unpredictability."
        case .veryStrong:
            return "Excellent! Long, unpredictable passphrases provide the highest level of brute-force protection."
        }
    }

    /// Evaluates passphrase strength with entropy analysis, repetition detection, and multi-word phrase recognition.
    /// Rejects passphrases shorter than 12 characters or composed mostly of whitespace.
    public static func evaluate(_ text: String) -> PasswordStrength {
        if text.count < 12 {
            return .veryWeak
        }

        // 1. Whitespace analysis: Spaces alone must NOT inflate password strength
        let nonWhitespaceChars = text.filter { !$0.isWhitespace }
        if nonWhitespaceChars.count < 10 {
            return .veryWeak
        }

        let lower = text.lowercased()
        let uniqueChars = Set(lower)

        // 2. Character diversity check: low unique characters indicates repetition (e.g. "aaaaaaaaaaaa", "abababababab")
        if uniqueChars.count <= 3 {
            return .weak
        }
        if text.count >= 16 && uniqueChars.count <= 5 {
            return .weak
        }

        // 3. Repeated pattern check (e.g. "passwordpassword", "appleappleapple", "123123123123")
        for patternLen in 1...min(8, lower.count / 2) {
            let pattern = String(lower.prefix(patternLen))
            let repeated = String(repeating: pattern, count: lower.count / patternLen)
            if lower.hasPrefix(repeated) && (lower.count - repeated.count) <= patternLen {
                return .weak
            }
        }

        // 4. Sequential character check (e.g. "123456789012", "abcdefghijkl")
        if isSequentialPattern(lower) {
            return .weak
        }

        // 5. Multi-word passphrase analysis (e.g. Diceware / distinct word sequences)
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_.")))
            .filter { $0.count >= 2 }
        let uniqueWords = Set(words.map { $0.lowercased() })

        let hasDistinctWords = words.count >= 3 && uniqueWords.count >= 3
        let isLongMultiWord = words.count >= 4 && uniqueWords.count >= 4 && text.count >= 20

        // 6. Unicode character support
        let hasUnicode = text.unicodeScalars.contains { !$0.isASCII }

        // 7. Calculate final score based on length, entropy, and phrase structure
        if isLongMultiWord || (text.count >= 24 && uniqueChars.count >= 10) {
            return .veryStrong
        }

        if hasDistinctWords || (text.count >= 18 && uniqueChars.count >= 8) || (hasUnicode && text.count >= 16 && uniqueChars.count >= 7) || (text.count >= 12 && uniqueChars.count >= 10) {
            return .strong
        }

        if text.count >= 14 && uniqueChars.count >= 6 {
            return .fair
        }

        // 12-13 characters with reasonable variety
        return uniqueChars.count >= 6 ? .fair : .weak
    }

    /// Detects whether more than 60% of the string is composed of ascending or descending ASCII sequences.
    private static func isSequentialPattern(_ text: String) -> Bool {
        let scalars = Array(text.unicodeScalars)
        guard scalars.count >= 8 else { return false }

        var sequentialCount = 0
        for i in 0..<(scalars.count - 1) {
            let diff = Int(scalars[i + 1].value) - Int(scalars[i].value)
            if diff == 1 || diff == -1 {
                sequentialCount += 1
            }
        }

        let ratio = Double(sequentialCount) / Double(scalars.count)
        return ratio >= 0.65
    }
}
