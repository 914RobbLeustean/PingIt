import Foundation
import Testing
@testable import PingIt

@Suite("ProfileViewModel")
@MainActor
struct ProfileViewModelTests {

    // MARK: - Helpers

    private func makeVM() -> ProfileViewModel {
        makeVM(authService: MockAuthService(), userService: MockUserService())
    }

    private func makeVM(
        authService: MockAuthService,
        userService: MockUserService,
        imageStorageService: MockImageStorageService = MockImageStorageService()
    ) -> ProfileViewModel {
        let vm = ProfileViewModel()
        vm.configure(authService: authService, userService: userService, imageStorageService: imageStorageService)
        return vm
    }

    private func authenticatedAuth(uid: String = "user1") -> MockAuthService {
        let auth = MockAuthService()
        auth.currentUser = MockAuthUser(uid: uid)
        return auth
    }

    // MARK: - loadProfile

    @Test func loadProfileFetchesUser() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        user.userToReturn = User(username: "testuser", email: "test@test.com", usernameLowercase: "testuser")
        let vm = makeVM(authService: auth, userService: user)

        await vm.loadProfile()

        #expect(user.fetchUserCalled)
        #expect(vm.user?.username == "testuser")
        #expect(vm.editedUsername == "testuser")
        #expect(vm.errorMessage == nil)
    }

    @Test func loadProfileSetsErrorOnFailure() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        user.errorToThrow = PingItError.firestoreReadFailed(underlying: URLError(.notConnectedToInternet))
        let vm = makeVM(authService: auth, userService: user)

        await vm.loadProfile()

        #expect(vm.user == nil)
        #expect(vm.errorMessage != nil)
    }

    @Test func loadProfileDoesNothingWhenNotAuthenticated() async {
        let auth = MockAuthService()
        auth.currentUser = nil
        let user = MockUserService()
        let vm = makeVM(authService: auth, userService: user)

        await vm.loadProfile()

        #expect(user.fetchUserCalled == false)
    }

    // MARK: - saveUsername

    @Test func saveUsernameUpdatesUser() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        user.userToReturn = User(username: "oldname", email: "test@test.com", usernameLowercase: "oldname")
        let vm = makeVM(authService: auth, userService: user)
        await vm.loadProfile()

        vm.editedUsername = "newname1"
        await vm.saveUsername()

        #expect(user.updateUsernameCalled)
        #expect(user.lastUpdatedUsername == "newname1")
        #expect(vm.errorMessage == nil)
    }

    @Test func saveUsernameRejectsShortUsername() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        let vm = makeVM(authService: auth, userService: user)
        vm.editedUsername = "ab" // Too short

        await vm.saveUsername()

        #expect(user.updateUsernameCalled == false)
        #expect(vm.errorMessage != nil)
    }

    @Test func saveUsernameRejectsLongUsername() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        let vm = makeVM(authService: auth, userService: user)
        vm.editedUsername = String(repeating: "a", count: Constants.Username.maxLength + 1)

        await vm.saveUsername()

        #expect(user.updateUsernameCalled == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - canSaveUsername

    @Test func canSaveUsernameFalseWhenNoChanges() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        user.userToReturn = User(username: "sameuser", email: "test@test.com", usernameLowercase: "sameuser")
        let vm = makeVM(authService: auth, userService: user)
        await vm.loadProfile()

        // editedUsername == user.username → no changes
        #expect(vm.canSaveUsername == false)
    }

    @Test func canSaveUsernameTrueWhenValidChange() async {
        let auth = authenticatedAuth()
        let user = MockUserService()
        user.userToReturn = User(username: "oldname", email: "test@test.com", usernameLowercase: "oldname")
        let vm = makeVM(authService: auth, userService: user)
        await vm.loadProfile()

        vm.editedUsername = "newname1"
        #expect(vm.canSaveUsername)
    }
}
