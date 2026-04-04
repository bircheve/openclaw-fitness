import SwiftUI

enum PixelFont {
    // Standard iOS text sizes (points)
    // Matches Apple's defaults so layouts behave predictably.
    static let largeTitle: CGFloat = 34
    static let title1: CGFloat     = 28
    static let title2: CGFloat     = 22
    static let title3: CGFloat     = 20
    static let headline: CGFloat   = 17
    static let body: CGFloat       = 17
    static let callout: CGFloat    = 16
    static let subheadline: CGFloat = 15
    static let footnote: CGFloat   = 13
    static let caption1: CGFloat   = 12
    static let caption2: CGFloat   = 11

    // Builders using system fonts
    static func custom(_ size: CGFloat) -> Font { .system(size: size) }

    static func largeTitleFont() -> Font { .largeTitle }
    static func title1Font()    -> Font { .title }
    static func title2Font()    -> Font { .title2 }
    static func title3Font()    -> Font { .title3 }
    static func headlineFont()  -> Font { .headline }
    static func bodyFont()      -> Font { .body }
    static func calloutFont()   -> Font { .callout }
    static func subheadlineFont()-> Font { .subheadline }
    static func footnoteFont()  -> Font { .footnote }
    static func caption1Font()  -> Font { .caption }
    static func caption2Font()  -> Font { .caption2 }
}
