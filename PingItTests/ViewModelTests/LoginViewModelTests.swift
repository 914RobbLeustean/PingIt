import Testing
@testable import PingIt

@Suite("LoginViewModel")
@MainActor
struct LoginViewModelTests {

    // MARK: - Helpers

    private func makeVM() -> LoginViewModel {
        makeVM(authService: MockAuthService())
    }

    private func makeVM(authService: MockAuthService) -> LoginViewModel {
        let vm = LoginViewModel()
        vm.configure(authService: authService)
        return vm
    }

    // MARK: - canSubmit

    @Test func canSubmitFalseWhenEmailEmpty() {
        let vm = makeVM()
        vm.email = ""
        vm.password = "Password1"
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenPasswordEmpty() {
        let vm = makeVM()
        vm.email = "user@test.com"
        vm.password = ""
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenEmailInvalid() {
        let vm = makeVM()
        vm.email = "notanemail"
        vm.password = "Password1"
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitTrueWithValidCredentials() {
        let vm = makeVM()
        vm.email = "user@test.com"
        vm.password = "Password1"
        #expect(vm.canSubmit)
    }

    // MARK: - emailValidationMessage

    @Test func emailValidationMessageNilWhenEmpty() {
        let vm = makeVM()
        vm.email = ""
        #expect(vm.emailValidationMessage == nil)
    }

    @Test func emailValidationMessageNilWhenValid() {
        let vm = makeVM()
        vm.email = "user@test.com"
        #expect(vm.emailValidationMessage == nil)
    }

    @Test func emailValidationMessageSetWhenInvalid() {
        let vm = makeVM()
        vm.email = "notanemail"
        #expect(vm.emailValidationMessage != nil)
    }

    // MARK: - authenticate — sign in

    @Test func authenticateCallsSignIn() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"
        vm.password = "Password1"

        await vm.authenticate()

        #expect(auth.signInCalled)
        #expect(auth.signUpCalled == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func authenticateSetsErrorMessageOnFailure() async {
        let auth = MockAuthService()
        auth.errorToThrow = PingItError.wrongPassword
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"
        vm.password = "wrongpass"

        await vm.authenticate()

        #expect(vm.errorMessage != nil)
    }
}
