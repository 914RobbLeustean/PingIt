import Testing
@testable import PingIt

@Suite("ForgotPasswordViewModel")
@MainActor
struct ForgotPasswordViewModelTests {

    // MARK: - Helpers

    private func makeVM(authService: MockAuthService = MockAuthService()) -> ForgotPasswordViewModel {
        let vm = ForgotPasswordViewModel()
        vm.configure(authService: authService)
        return vm
    }

    // MARK: - canSubmit

    @Test func canSubmitFalseWhenEmailEmpty() {
        let vm = makeVM()
        vm.email = ""
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitFalseWhenEmailInvalid() {
        let vm = makeVM()
        vm.email = "notanemail"
        #expect(vm.canSubmit == false)
    }

    @Test func canSubmitTrueWithValidEmail() {
        let vm = makeVM()
        vm.email = "user@test.com"
        #expect(vm.canSubmit)
    }

    // MARK: - sendReset

    @Test func sendResetCallsSendPasswordReset() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"

        await vm.sendReset()

        #expect(auth.sendPasswordResetCalled)
        #expect(auth.sendPasswordResetEmail == "user@test.com")
        #expect(vm.didSendReset)
        #expect(vm.errorMessage == nil)
    }

    @Test func sendResetSetsErrorOnFailure() async {
        let auth = MockAuthService()
        auth.errorToThrow = PingItError.passwordResetFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"

        await vm.sendReset()

        #expect(vm.didSendReset == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func sendResetDoesNothingWhenCannotSubmit() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        vm.email = "bademail"

        await vm.sendReset()

        #expect(auth.sendPasswordResetCalled == false)
    }
}
