import Testing
@testable import PingIt

@Suite("PasswordValidator")
struct PasswordValidatorTests {

    // MARK: - Empty password

    @Test func emptyPasswordReturnsEmptyStrength() {
        let result = PasswordValidator.validate("")
        #expect(result.strength == .empty)
    }

    @Test func emptyPasswordHasNoRulesMet() {
        let result = PasswordValidator.validate("")
        #expect(result.rules.allSatisfy { !$0.isMet })
    }

    // MARK: - Strength levels

    @Test func singleLowercaseLetterIsWeak() {
        let result = PasswordValidator.validate("a")
        #expect(result.strength == .weak)
    }

    @Test func shortUpperAndLowerIsModerate() {
        // meets uppercase + lowercase (2 rules) → moderate
        let result = PasswordValidator.validate("Aa")
        #expect(result.strength == .moderate)
    }

    @Test func threeRulesMetIsModerate() {
        // meets uppercase + lowercase + digit (3 rules) → moderate
        let result = PasswordValidator.validate("Aa1")
        #expect(result.strength == .moderate)
    }

    @Test func allRulesMetIsStrong() {
        // meets all 4 rules
        let result = PasswordValidator.validate("Abcdefg1")
        #expect(result.strength == .strong)
    }

    // MARK: - minLength rule

    @Test func sevenCharsFailsMinLength() {
        let result = PasswordValidator.validate("Abcdef1")
        let rule = result.rules.first { $0.id == .minLength }
        #expect(rule?.isMet == false)
    }

    @Test func eightCharsPassesMinLength() {
        let result = PasswordValidator.validate("Abcdefg1")
        let rule = result.rules.first { $0.id == .minLength }
        #expect(rule?.isMet == true)
    }

    // MARK: - uppercase rule

    @Test func noUppercaseFailsRule() {
        let result = PasswordValidator.validate("abcdefg1")
        let rule = result.rules.first { $0.id == .uppercase }
        #expect(rule?.isMet == false)
    }

    @Test func hasUppercasePassesRule() {
        let result = PasswordValidator.validate("Abcdefg1")
        let rule = result.rules.first { $0.id == .uppercase }
        #expect(rule?.isMet == true)
    }

    // MARK: - lowercase rule

    @Test func noLowercaseFailsRule() {
        let result = PasswordValidator.validate("ABCDEFG1")
        let rule = result.rules.first { $0.id == .lowercase }
        #expect(rule?.isMet == false)
    }

    @Test func hasLowercasePassesRule() {
        let result = PasswordValidator.validate("Abcdefg1")
        let rule = result.rules.first { $0.id == .lowercase }
        #expect(rule?.isMet == true)
    }

    // MARK: - digit rule

    @Test func noDigitFailsRule() {
        let result = PasswordValidator.validate("Abcdefgh")
        let rule = result.rules.first { $0.id == .digit }
        #expect(rule?.isMet == false)
    }

    @Test func hasDigitPassesRule() {
        let result = PasswordValidator.validate("Abcdefg1")
        let rule = result.rules.first { $0.id == .digit }
        #expect(rule?.isMet == true)
    }

    // MARK: - allRulesMet

    @Test func allRulesMetReturnsTrueForStrongPassword() {
        let result = PasswordValidator.validate("Abcdefg1")
        #expect(result.allRulesMet)
    }

    @Test func allRulesMetReturnsFalseForWeakPassword() {
        let result = PasswordValidator.validate("abc")
        #expect(!result.allRulesMet)
    }

    // MARK: - Rule count

    @Test func alwaysFourRules() {
        let result = PasswordValidator.validate("anything")
        #expect(result.rules.count == 4)
    }
}
