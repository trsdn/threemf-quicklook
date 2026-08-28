import XCTest
import CoreGraphics

/// The markup is the only thing a VoiceOver user ever receives from this preview, and the file
/// name interpolated into it comes from a downloaded archive. Neither had a test.
final class PreviewMarkupTests: XCTestCase {

    // MARK: - Text alternative

    func testThePreviewImageCarriesADescriptiveAlternative() {
        let html = PreviewMarkup.image(fileName: "dragon.3mf", pixelSize: CGSize(width: 800, height: 600))

        XCTAssertTrue(
            html.contains(#"alt="Embedded preview image from dragon.3mf, 800 by 600 pixels""#),
            "the alt text must name the file and its size, not just say \"image\""
        )
    }

    func testThePreviewImageIsNeverLeftWithoutAnAlternative() {
        let html = PreviewMarkup.image(fileName: "x.3mf", pixelSize: CGSize(width: 10, height: 10))

        // An <img> with no alt is exactly the failure this markup exists to avoid, and an empty
        // alt would mark a decorative image -- wrong for the entire content of the preview.
        XCTAssertTrue(html.contains("<img "))
        XCTAssertFalse(html.contains(#"alt="""#), "an empty alt marks the image as decorative")
    }

    func testTheImageIsReferencedByTheAttachmentIdentifierTheProviderAttaches() {
        let html = PreviewMarkup.image(fileName: "a.3mf", pixelSize: CGSize(width: 2, height: 2))

        XCTAssertTrue(html.contains("src=\"cid:\(PreviewMarkup.attachmentIdentifier)\""))
    }

    func testTheDecorativeFallbackIconIsHiddenFromAssistiveTechnology() {
        let html = PreviewMarkup.fallback(fileName: "a.3mf", message: "No preview found.")

        XCTAssertTrue(html.contains(#"aria-hidden="true""#))
        XCTAssertTrue(html.contains("<h1>a.3mf</h1>"), "the file name must be real text")
        XCTAssertTrue(html.contains("<p>No preview found.</p>"), "the reason must be real text")
    }

    // MARK: - Untrusted file names

    func testAFileNameCannotInjectMarkupIntoTheBody() {
        let hostile = "<script>alert(1)</script>.3mf"
        let html = PreviewMarkup.fallback(fileName: hostile, message: "nope")

        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testAFileNameCannotEscapeAnAttributeValue() {
        // The alt attribute is the interesting one: a bare quote there would end the attribute and
        // let the rest of the name become markup.
        let hostile = #"a" onerror="alert(1)" x=".3mf"#
        let html = PreviewMarkup.image(fileName: hostile, pixelSize: CGSize(width: 4, height: 4))

        XCTAssertFalse(html.contains("onerror=\"alert"))
        XCTAssertTrue(html.contains("&quot;"))
    }

    func testAmpersandsAreEscapedBeforeAnythingElse() {
        // Escaping "&" after "<" would double-escape and display "&amp;lt;" to the user.
        let html = PreviewMarkup.fallback(fileName: "a&b<c.3mf", message: "x")

        XCTAssertTrue(html.contains("a&amp;b&lt;c.3mf"))
        XCTAssertFalse(html.contains("&amp;lt;"))
    }

    func testOrdinaryFileNamesAreLeftAlone() {
        let html = PreviewMarkup.fallback(fileName: "Spur gear (24 teeth)-5.3mf", message: "x")

        XCTAssertTrue(html.contains("Spur gear (24 teeth)-5.3mf"))
    }

    // MARK: - Dimensions

    func testFractionalPixelSizesAreRoundedRatherThanPrintedAsFloats() {
        let html = PreviewMarkup.image(fileName: "a.3mf", pixelSize: CGSize(width: 799.6, height: 600.4))

        XCTAssertTrue(html.contains(#"width="800""#))
        XCTAssertTrue(html.contains(#"height="600""#))
        XCTAssertFalse(html.contains("799.6"))
    }

    func testADegenerateSizeStillProducesValidMarkup() {
        // An extractor bug or an odd package could yield a zero size; width="0" would hide the
        // image entirely, so the floor is deliberate.
        let html = PreviewMarkup.image(fileName: "a.3mf", pixelSize: .zero)

        XCTAssertTrue(html.contains(#"width="1""#))
        XCTAssertTrue(html.contains(#"height="1""#))
    }

    // MARK: - Shape

    func testBothDocumentsDeclareEncodingAndLanguage() {
        for html in [
            PreviewMarkup.image(fileName: "a.3mf", pixelSize: CGSize(width: 1, height: 1)),
            PreviewMarkup.fallback(fileName: "a.3mf", message: "x")
        ] {
            XCTAssertTrue(html.hasPrefix("<!doctype html>"))
            XCTAssertTrue(html.contains(#"<html lang="en">"#))
            XCTAssertTrue(html.contains(#"<meta charset="utf-8">"#))
        }
    }

    func testBothDocumentsAdaptToDarkMode() {
        // Quick Look is shown over the user's desktop; a white card in dark mode is jarring.
        for html in [
            PreviewMarkup.image(fileName: "a.3mf", pixelSize: CGSize(width: 1, height: 1)),
            PreviewMarkup.fallback(fileName: "a.3mf", message: "x")
        ] {
            XCTAssertTrue(html.contains("prefers-color-scheme: dark"))
        }
    }
}
