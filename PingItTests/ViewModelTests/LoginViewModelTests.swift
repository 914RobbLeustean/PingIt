import Testing
@testable import PingIt

@Suite("LoginViewModel — service interaction")
@MainActor
struct LoginViewModelServiceTests {

    // MARK: - Helpers

    private func makeVM(authService: MockAuthService = MockAuthService()) -> LoginViewModel {
        let vm = LoginViewModel()
        vm.configure(authService: authService)
        return vm
    }

    // MARK: - authenticate — sign in

    @Test func authenticateCallsSignInWhenNotSignUp() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"
        vm.password = "pass123"
        vm.isSignUp = false

        await vm.authenticate()

        #expect(auth.signInCalled)
        #expect(auth.signUpCalled == false)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - authenticate — sign up

    @Test func authenticateCallsSignUpWhenSignUp() async {
        let auth = MockAuthService()
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"
        vm.password = "pass123"
        vm.username = "validuser"
        vm.isSignUp = true

        await vm.authenticate()

        #expect(auth.signUpCalled)
        #expect(auth.signInCalled == false)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - authenticate — error propagation

    @Test func authenticateSetsErrorMessageOnSignInFailure() async {
        let auth = MockAuthService()
        auth.errorToThrow = PingItError.signInFailed(underlying: URLError(.userAuthenticationRequired))
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"
        vm.password = "wrong"
        vm.isSignUp = false

        await vm.authenticate()

        #expect(vm.errorMessage != nil)
    }

    @Test func authenticateSetsErrorMessageOnSignUpFailure() async {
        let auth = MockAuthService()
        auth.errorToThrow = PingItError.signUpFailed(underlying: URLError(.userAuthenticationRequired))
        let vm = makeVM(authService: auth)
        vm.email = "taken@test.com"
        vm.password = "pass123"
        vm.username = "takenuser"
        vm.isSignUp = true

        await vm.authenticate()

        #expect(vm.errorMessage != nil)
    }

    // MARK: - toggleMode

    @Test func toggleModeClearsErrorMessage() async {
        let auth = MockAuthService()
        auth.errorToThrow = PingItError.signInFailed(underlying: URLError(.userAuthenticationRequired))
        let vm = makeVM(authService: auth)
        vm.email = "user@test.com"
        vm.password = "bad"
        vm.isSignUp = false

        await vm.authenticate()
        #expect(vm.errorMessage != nil)

        vm.toggleMode()
        #expect(vm.errorMessage == nil)
    }
}
