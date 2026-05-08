import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        WebContentView(htmlFileName: "privacy")
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}
