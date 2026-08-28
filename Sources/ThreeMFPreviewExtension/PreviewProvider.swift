import CoreGraphics
import Foundation
import os
import Quartz
import ThreeMFKit
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let extractor = ThreeMFPreviewExtractor()
  private let logger = Logger(subsystem: "com.printfilemanager.ThreeMFQuickLook", category: "PreviewProvider")

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
      let hasSecurityScopedAccess = request.fileURL.startAccessingSecurityScopedResource()
      defer {
        if hasSecurityScopedAccess {
          request.fileURL.stopAccessingSecurityScopedResource()
        }
      }

      logger.info("Preview request started file=\(request.fileURL.path, privacy: .private) securityScoped=\(hasSecurityScopedAccess)")

        switch extractor.preview(for: request.fileURL, maxPixelDimension: 1_600) {
        case .preview(let image):
        logger.info("Preview extracted file=\(request.fileURL.lastPathComponent, privacy: .private) bytes=\(image.data.count) width=\(image.pixelSize.width) height=\(image.pixelSize.height)")
            let contentType = UTType(image.contentTypeIdentifier) ?? .png
            let fileName = request.fileURL.lastPathComponent

            // Returning the image bytes directly is simpler, but then the preview is a bare image
            // with nothing for VoiceOver to announce -- the whole content of the preview is
            // non-text with no text alternative. Wrapping it in HTML and attaching the image by
            // cid: lets it carry a real alt description, at no cost to how it looks: the image
            // still fills the view and is still the same bytes.
            return QLPreviewReply(dataOfContentType: .html, contentSize: image.pixelSize) { reply in
                reply.stringEncoding = .utf8
                reply.attachments = [
                    PreviewMarkup.attachmentIdentifier: QLPreviewReplyAttachment(
                        data: image.data,
                        contentType: contentType
                    )
                ]
                reply.title = fileName
                return Data(
                    PreviewMarkup.image(fileName: fileName, pixelSize: image.pixelSize).utf8
                )
            }

        case .fallback(let fallback):
            // The extensions also register for public.zip-archive so they still fire when a
            // slicer owns the .3mf type. Ordinary archives must be handed back to the system
            // rather than shown our "no preview" card.
            guard fallback.reason != .notAThreeMFPackage else {
                logger.info("Not a 3MF package, deferring to the system file=\(request.fileURL.lastPathComponent, privacy: .private)")
                throw CocoaError(.fileReadCorruptFile)
            }

        logger.error("Preview extraction fell back file=\(request.fileURL.path, privacy: .private)")
            return QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 640, height: 420)) { reply in
                reply.stringEncoding = .utf8
                return Data(
                    PreviewMarkup.fallback(
                        fileName: fallback.fileName,
                        message: Self.fallbackMessage(for: fallback.reason)
                    ).utf8
                )
            }
        }
    }

    private static func fallbackMessage(for reason: PreviewFallbackReason) -> String {
        switch reason {
        case .unreadablePackage:
            return "This file could not be opened as a 3MF package."
        case .noSupportedImage:
            return "No embedded 3MF preview image was found."
        case .imageNormalizationFailed:
            return "The embedded preview image could not be read."
        case .notAThreeMFPackage:
            return "This archive is not a 3MF package."
        }
    }

}
