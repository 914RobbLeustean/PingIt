import Testing
@testable import PingIt

@Suite("RegisterViewModel")
@MainActor
struct RegisterViewModelTests {

    // MARK: - Helpers

    private func makeVM(
        authService: MockAuthService? = nil,
        userService: MockUserService? = nil
    ) -> RegisterViewModel {
        let authService = authService ?? MockAuthService()
        let userService = userService ?? MockUserService()
        let vm = RegisterViewModel()
        vm.configure(authService: authService, userService: userService)
        return vm
    }

    private func fillValidForm(_ vm: RegisterViewModel) {
        vm.email = "user@test.com"
        vm.username = "validuser"
        vm.password = "Password1"
        vm.confirmPassword = "Password1"
        vm.hasAcceptedTerms = true
        vm.passwordDidChange()
        vm.setUsernameAvailabilityForTesting(.available)
    }

    // MARK: - canSubmit

    @Test func canSubmitFalseWhenEmailInvalid() {
        let vm = makeVM()
        fillValidForm(vm)
        vm.email = "notanemail"
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenUsernameFormatInvalid() {
        let vm = makeVM()
        fillValidForm(vm)
        vm.username = "ab" // too short
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenUsernameNotAvailable() {
        let vm = makeVM()
        fillValidForm(vm)
        vm.setUsernameAvailabilityForTesting(.taken)
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenPasswordTooWeak() {
        let vm = makeVM()
        fillValidForm(vm)
        vm.password = "weak"
        vm.confirmPassword = "weak"
        vm.passwordDidChange()
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenPasswordsDontMatch() {
        let vm = makeVM()
        fillValidForm(vm)
        vm.confirmPassword = "Different1"
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenTermsNotAccepted() {
        let vm = makeVM()
        fillValidForm(vm)
        vm.hasAcceptedTerms = false
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitTrueWhenAllValid() {
        let vm = makeVM()
        fillValidForm(vm)
        #expect(vm.canSubmit)
    }

    // MARK: - emailValidationMessage

    @Test func emailValidationMessageNilWhenEmpty() {
        let vm = makeVM()
        vm.email = ""
        #expect(vm.emailValidationMessage == nil)
    }

    @Test func emailValidationMessageSetForInvalidEmail() {
        let vm = makeVM()
        vm.email = "bademail"
        #expect(vm.emailValidationMessage != nil)
    }

    // MARK: - passwordsMatchMessage

    @Test func passwordsMatchMessageNilWhenConfirmEmpty() {
        let vm = makeVM()
        vm.password = "Password1"
        vm.confirmPassword = ""
        #expect(vm.passwordsMatchMessage == nil)
    }

    @Test func passwordsMatchMessageSetWhenMismatch() {
        let vm = makeVM()
        vm.password = "Password1"
        vm.confirmPassword = "Different1"
        #expect(vm.passwordsMatchMessage != nil)
    }

    @Test func passwordsMatchMessageNilWhenMatch() {
        let vm = makeVM()
        vm.password = "Password1"
        vm.confirmPassword = "Password1"
        #expect(vm.passwordsMatchMessage == nil)
    }

    // MARK: - passwordValidation

    @Test func passwordValidationUpdatesOnPasswordDidChange() {
        let vm = makeVM()
        vm.password = "Password1"
        vm.passwordDidChange()
        #expect(vm.passwordValidation.allRulesMet)
    }

    @Test func weakPasswordNotAllRulesMet() {
        let vm = makeVM()
        vm.password = "weak"
        vm.passwordDidChange()
        #expect(!vm.passwordValidation.allRulesMet)
    }

    // MARK: - usernameFormatMessage

    @Test func usernameFormatMessageNilWhenEmpty() {
        let vm = makeVM()
        vm.username = ""
        #expect(vm.usernameFormatMessage == nil)
    }

    @Test func usernameFormatMessageSetWhenTooShort() {
        let vm = makeVM()
        vm.username = "ab"
        #expect(vm.usernameFormatMessage != nil)
    }

    @Test func usernameFormatMessageSetForInvalidChars() {
        let vm = makeVM()
        vm.username = "bad user!"
        #expect(vm.usernameFormatMessage != nil)
    }

    // MARK: - register

    @Test func registerCallsSignUp() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        fillValidForm(vm)

        await vm.register()

        #expect(auth.signUpCalled)
        #expect(vm.errorMessage == nil)
    }

    @Test func registerSetsErrorOnFailure() async {
        let auth = MockAuthService()
        auth.errorToThrow = PingItError.emailAlreadyInUse
        let vm = makeVM(authService: auth)
        fillValidForm(vm)

        await vm.register()

        #expect(vm.errorMessage != nil)
    }

    @Test func registerDoesNothingWhenCannotSubmit() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        // All fields empty — canSubmit == false

        await vm.register()

        #expect(auth.signUpCalled == false)
    }
}
