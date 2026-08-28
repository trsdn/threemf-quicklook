import CoreGraphics
import Foundation

/// Builds the HTML a Quick Look preview returns.
///
/// This is deliberately free of any QuickLook dependency so it can be tested without hosting an
/// app extension. That matters more than it sounds: an app extension is awkward to exercise from a
/// unit test, and the result was that the markup -- including the only text alternative a
/// VoiceOver user ever gets for the preview -- had nothing checking it at all.
enum PreviewMarkup {
    /// Referenced from the markup as `cid:preview`; the provider attaches the image bytes under
    /// the same identifier.
    static let attachmentIdentifier = "preview"

    /// Markup for a successfully extracted preview image.
    ///
    /// The image is wrapped rather than returned as raw bytes so it can carry an `alt`
    /// description. Returning the bytes directly is simpler, but then the entire content of the
    /// preview is non-text with no text alternative.
    ///
    /// The description names the file and the pixel dimensions. "Image" alone would tell a
    /// VoiceOver user nothing they did not already know from selecting the file; the dimensions
    /// are something a sighted user can judge at a glance and a screen-reader user otherwise
    /// cannot.
    static func image(fileName: String, pixelSize: CGSize) -> String {
        let width = max(1, Int(pixelSize.width.rounded()))
        let height = max(1, Int(pixelSize.height.rounded()))
        let title = escape(fileName)
        let alt = escape("Embedded preview image from \(fileName), \(width) by \(height) pixels")

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>\(title)</title>
          <style>
            html, body { margin: 0; height: 100%; background: #ffffff; }
            @media (prefers-color-scheme: dark) {
              html, body { background: #1c1c1e; }
            }
            body { display: grid; place-items: center; }
            img { max-width: 100%; max-height: 100%; }
          </style>
        </head>
        <body>
          <img src="cid:\(attachmentIdentifier)" alt="\(alt)" width="\(width)" height="\(height)">
        </body>
        </html>
        """
    }

    /// Markup shown when no preview image could be extracted.
    ///
    /// The decorative document shape is `aria-hidden`, because announcing "image" for a drawing
    /// that carries no information wastes a screen-reader user's time. The file name and the
    /// reason are real text.
    static func fallback(fileName: String, message: String) -> String {
        let name = escape(fileName)
        let reason = escape(message)

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>\(name)</title>
          <style>
            body {
              margin: 0;
              height: 100vh;
              display: grid;
              place-items: center;
              font: -apple-system-body;
              color: #1d1d1f;
              background: #f5f5f7;
            }
            @media (prefers-color-scheme: dark) {
              body { color: #f5f5f7; background: #1c1c1e; }
            }
            main { text-align: center; max-width: 420px; padding: 32px; }
            .icon {
              width: 84px;
              height: 108px;
              margin: 0 auto 20px;
              border-radius: 12px;
              background: linear-gradient(#ffffff, #e8e8ed);
              border: 1px solid #d2d2d7;
              box-shadow: 0 10px 30px rgba(0,0,0,0.08);
            }
            h1 { margin: 0 0 8px; font-size: 18px; font-weight: 600; }
            p { margin: 0; color: #6e6e73; font-size: 13px; }
            @media (prefers-color-scheme: dark) {
              p { color: #a1a1a6; }
            }
          </style>
        </head>
        <body>
          <main>
            <div class="icon" aria-hidden="true"></div>
            <h1>\(name)</h1>
            <p>\(reason)</p>
          </main>
        </body>
        </html>
        """
    }

    /// A file name is attacker-influenced -- it comes from a downloaded archive -- and is
    /// interpolated into both an element body and an attribute value, so quotes matter as much as
    /// angle brackets.
    static func escape(_ value: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(value.count)
        for character in value {
            switch character {
            case "&": escaped += "&amp;"
            case "<": escaped += "&lt;"
            case ">": escaped += "&gt;"
            case "\"": escaped += "&quot;"
            case "'": escaped += "&#39;"
            default: escaped.append(character)
            }
        }
        return escaped
    }
}
