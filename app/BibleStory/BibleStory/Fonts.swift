import CoreText
import UIKit

/// Registers the bundled display/body fonts at launch so `Theme` can reference them
/// by PostScript name. We register at runtime with `CTFontManagerRegisterFontsForURL`
/// (rather than a `UIAppFonts` Info.plist array) so the app works whether or not the
/// generated Info.plist lists them — and `Theme` still degrades to the system fonts
/// if a face fails to load.
///
/// Bundled faces (both SIL OFL — see FONT-LICENSES/):
///   • IM Fell English (Roman + Italic) — headings, banner, titles      → "IM_FELL_English_Roman" / "IM_FELL_English_Italic"
///   • IM Fell English SC               — small-caps labels/verse ref    → "IM_FELL_English_SC"
///   • Atkinson Hyperlegible (Reg+Bold) — body / UI                      → "AtkinsonHyperlegible-Regular" / "-Bold"
enum AppFonts {
    /// TTF resource base-names bundled under BibleStory/Fonts/.
    static let bundledFileNames = [
        "AtkinsonHyperlegible-Regular",
        "AtkinsonHyperlegible-Bold",
        "IMFeENrm28P",   // IM FELL English — Roman
        "IMFeENit28P",   // IM FELL English — Italic
        "IMFeENsc28P",   // IM FELL English SC
    ]

    /// Register every bundled `.ttf` with the process font manager. Idempotent:
    /// re-registering a face simply returns false (which we ignore), so this is
    /// safe to call once at launch.
    static func register() {
        for name in bundledFileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already-registered is benign; anything else we just fall back on.
                error?.release()
            }
        }
    }
}
