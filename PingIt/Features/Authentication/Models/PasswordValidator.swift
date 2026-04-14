import Foundation

/// Pure, stateless password validation logic. No dependencies.
struct PasswordValidator: Sendable {

    // MARK: - Rule

    enum RuleType: String, Sendable, CaseIterable {
        case minLength
        case uppercase
        case lowercase
        case digit
    }

    struct Rule: Sendable, Equatable, Identifiable {
        let id: RuleType
        let label: String
        let isMet: Bool
    }

    // MARK: - Strength

    enum Strength: Sendable, Equatable {
        case empty
        case weak
        case moderate
        case strong
    }

    // MARK: - Result

    struct Result: Sendable, Equatable {
        let rules: [Rule]
        let strength: Strength

        var allRulesMet: Bool { rules.allSatisfy(\.isMet) }
    }

    // MARK: - Validation

    static func validate(_ password: String) -> Result {
        guard !password.isEmpty else {
            let emptyRules = RuleType.allCases.map { ruleType in
                Rule(id: ruleType, label: label(for: ruleType), isMet: false)
            }
            return Result(rules: emptyRules, strength: .empty)
        }

        let rules = RuleType.allCases.map { ruleType in
            Rule(id: ruleType, label: label(for: ruleType), isMet: isMet(ruleType, password: password))
        }

        let metCount = rules.filter(\.isMet).count
        let strength: Strength = switch metCount {
        case 0...1: .weak
        case 2...3: .moderate
        default: .strong
        }

        return Result(rules: rules, strength: strength)
    }

    // MARK: - Private helpers

    private static func isMet(_ rule: RuleType, password: String) -> Bool {
        switch rule {
        case .minLength:
            password.count >= Constants.Password.minLength
        case .uppercase:
            password.contains(where: \.isUppercase)
        case .lowercase:
            password.contains(where: \.isLowercase)
        case .digit:
            password.contains(where: \.isNumber)
        }
    }

    private static func label(for rule: RuleType) -> String {
        switch rule {
        case .minLength:
            "At least \(Constants.Password.minLength) characters"
        case .uppercase:
            "One uppercase letter"
        case .lowercase:
            "One lowercase letter"
        case .digit:
            "One number"
        }
    }
}
