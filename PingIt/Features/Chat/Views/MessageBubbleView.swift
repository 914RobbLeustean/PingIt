import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let sender: User?
    let showSenderInfo: Bool
    let isSenderPrivate: Bool
    let currentUserId: String?
    let onLongPress: () -> Void
    let onReaction: (String) -> Void

    private func handleLongPress() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onLongPress()
    }

    private var isLocationMessage: Bool {
        message.messageType == Constants.MessageType.location
            && message.latitude != nil
            && message.longitude != nil
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer(minLength: 60)
            } else {
                BubbleAvatar(
                    sender: sender,
                    isAnonymous: isSenderPrivate,
                    visible: showSenderInfo
                )
            }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 3) {
                if showSenderInfo && !isCurrentUser {
                    Text(displayName)
                        .font(.dmSans(.regular, size: 11, relativeTo: .caption))
                        .foregroundStyle(Color.pingTextSecondary)
                        .padding(.leading, 4)
                }

                bubbleContent
                    .onLongPressGesture(minimumDuration: 0.35, perform: handleLongPress)

                if let reactions = message.reactions, !reactions.isEmpty {
                    ReactionSummaryView(
                        reactions: reactions,
                        currentUserId: currentUserId,
                        onToggle: onReaction
                    )
                    .padding(isCurrentUser ? .trailing : .leading, 4)
                }

                if let createdAt = message.createdAt {
                    Text(createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.dmSans(.regular, size: 10, relativeTo: .caption2))
                        .foregroundStyle(Color.pingTextSecondary)
                        .padding(isCurrentUser ? .trailing : .leading, 4)
                }
            }

            if !isCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if isLocationMessage,
           let latitude = message.latitude,
           let longitude = message.longitude {
            ChatLocationBubble(
                latitude: latitude,
                longitude: longitude,
                locationName: message.locationName,
                isCurrentUser: isCurrentUser
            )
        } else {
            ChatTextBubble(text: message.text, isCurrentUser: isCurrentUser)
        }
    }

    private var displayName: String {
        if isSenderPrivate { return "Anonymous" }
        if let username = sender?.username { return "@\(username)" }
        return "@unknown"
    }

    private var accessibilityLabel: String {
        let senderName = isCurrentUser
            ? "You"
            : (isSenderPrivate ? "Anonymous" : (sender?.username ?? "Unknown"))
        return "\(senderName): \(message.text)"
    }
}

// MARK: - Text Bubble

private struct ChatTextBubble: View {
    let text: String
    let isCurrentUser: Bool

    var body: some View {
        Text(text)
            .font(.dmSans(.regular, size: 14, relativeTo: .body))
            .foregroundStyle(isCurrentUser ? .black : Color.pingTextPrimary)
            .lineSpacing(3)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isCurrentUser ? Color.pingAccent : Color.pingSurface)
            .clipShape(bubbleShape)
            .overlay(
                bubbleShape
                    .stroke(Color.white.opacity(isCurrentUser ? 0 : 0.07), lineWidth: 1)
            )
    }

    private var bubbleShape: ChatBubbleShape {
        if isCurrentUser {
            ChatBubbleShape(topLeading: 18, topTrailing: 18, bottomLeading: 18, bottomTrailing: 4)
        } else {
            ChatBubbleShape(topLeading: 4, topTrailing: 18, bottomLeading: 18, bottomTrailing: 18)
        }
    }
}

// MARK: - Location Bubble

private struct ChatLocationBubble: View {
    let latitude: Double
    let longitude: Double
    let locationName: String?
    let isCurrentUser: Bool

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        Button(action: openInMaps) {
            ZStack(alignment: .bottomLeading) {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                ))) {
                    Marker(locationName ?? "Shared location", coordinate: coordinate)
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .allowsHitTesting(false)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 64)
                .frame(maxWidth: .infinity, alignment: .bottom)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(locationName ?? "Shared location")
                        .font(.dmSans(.semiBold, size: 13, relativeTo: .footnote))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .frame(width: 230, height: 150)
            .clipShape(bubbleShape)
            .overlay(
                bubbleShape
                    .stroke(Color.white.opacity(isCurrentUser ? 0.2 : 0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Location: \(locationName ?? "Shared location"). Double tap to open in Maps.")
    }

    private var bubbleShape: ChatBubbleShape {
        if isCurrentUser {
            ChatBubbleShape(topLeading: 18, topTrailing: 18, bottomLeading: 18, bottomTrailing: 4)
        } else {
            ChatBubbleShape(topLeading: 4, topTrailing: 18, bottomLeading: 18, bottomTrailing: 18)
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = locationName ?? "Shared location"
        mapItem.openInMaps()
    }
}

// MARK: - Avatar

private struct BubbleAvatar: View {
    let sender: User?
    let isAnonymous: Bool
    let visible: Bool

    var body: some View {
        Group {
            if visible {
                if isAnonymous {
                    avatarBase
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.pingTextSecondary)
                        )
                } else if let urlString = sender?.profileImageUrl,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            initialOverlay
                        }
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(.circle)
                } else {
                    initialOverlay
                }
            } else {
                Color.clear.frame(width: 28, height: 28)
            }
        }
        .accessibilityHidden(true)
    }

    private var avatarBase: some View {
        Circle()
            .fill(Color.pingSurface)
            .frame(width: 28, height: 28)
            .overlay(
                Circle().strokeBorder(Color.pingBorder, lineWidth: 1)
            )
    }

    private var initialOverlay: some View {
        avatarBase
            .overlay(
                Text(String((sender?.username ?? "?").prefix(1)).uppercased())
                    .font(.dmSans(.bold, size: 11, relativeTo: .caption2))
                    .foregroundStyle(Color.pingTextSecondary)
            )
    }
}
