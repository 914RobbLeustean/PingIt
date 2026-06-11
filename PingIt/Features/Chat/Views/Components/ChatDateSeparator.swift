import SwiftUI

struct ChatDateSeparator: View {
    let date: Date

    private var label: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.pingBorder)
                .frame(height: 1)

            Text(label)
                .font(.dmSans(.regular, size: 11, relativeTo: .caption))
                .foregroundStyle(Color.pingTextSecondary)
                .fixedSize()

            Rectangle()
                .fill(Color.pingBorder)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Messages from \(label)")
    }
}
