import SwiftUI

enum SyneWeight: String {
    case regular   = "Syne-Regular"
    case bold      = "Syne-Bold"
    case extraBold = "Syne-ExtraBold"
}

enum DMSansWeight: String {
    case regular  = "DMSans-Regular"
    case medium   = "DMSans-Medium"
    case semiBold = "DMSans-SemiBold"
    case bold     = "DMSans-Bold"
}

extension Font {
    static func syne(_ weight: SyneWeight, size: CGFloat, relativeTo style: Font.TextStyle? = nil) -> Font {
        if let style {
            return .custom(weight.rawValue, size: size, relativeTo: style)
        }
        return .custom(weight.rawValue, fixedSize: size)
    }

    static func dmSans(_ weight: DMSansWeight, size: CGFloat, relativeTo style: Font.TextStyle? = nil) -> Font {
        if let style {
            return .custom(weight.rawValue, size: size, relativeTo: style)
        }
        return .custom(weight.rawValue, fixedSize: size)
    }
}
