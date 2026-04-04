import SwiftUI

extension View {
    // Shorthands that mirror Apple’s text styles
    func pxLargeTitle() -> some View { font(PixelFont.largeTitleFont()) }
    func pxTitle1()    -> some View { font(PixelFont.title1Font()) }
    func pxTitle2()    -> some View { font(PixelFont.title2Font()) }
    func pxTitle3()    -> some View { font(PixelFont.title3Font()) }
    func pxHeadline()  -> some View { font(PixelFont.headlineFont()) }
    func pxBody()      -> some View { font(PixelFont.bodyFont()) }
    func pxCallout()   -> some View { font(PixelFont.calloutFont()) }
    func pxSubheadline()-> some View { font(PixelFont.subheadlineFont()) }
    func pxFootnote()  -> some View { font(PixelFont.footnoteFont()) }
    func pxCaption1()  -> some View { font(PixelFont.caption1Font()) }
    func pxCaption2()  -> some View { font(PixelFont.caption2Font()) }

    // Custom size helper when you need a one-off
    func px(_ size: CGFloat) -> some View { font(PixelFont.custom(size)) }
}
