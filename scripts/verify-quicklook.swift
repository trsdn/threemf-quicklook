#!/usr/bin/env swift
//
// Asks macOS for a Quick Look thumbnail through QLThumbnailGenerator -- the same API Finder calls
// -- and reports what came back.
//
// This exists because the obvious tool does not work. `qlmanage -t` hangs forever against modern
// Quick Look extensions: it launches the extension and then never sends it a request, so the
// process sits idle in its run loop while qlmanage waits. That looks exactly like a broken
// extension and is not one. `qlmanage -p` does work but opens a window and waits for you to close
// it, which is no better in a script.
//
// Usage:
//     swift scripts/verify-quicklook.swift <file.3mf> [more files...]
//
// Exits non-zero if any file failed, so it can be used as a check.

import Foundation
import QuickLookThumbnailing

let arguments = Array(CommandLine.arguments.dropFirst())
guard !arguments.isEmpty else {
    FileHandle.standardError.write(
        Data("usage: verify-quicklook.swift <file.3mf> [more files...]\n".utf8))
    exit(2)
}

/// Long enough that a slow first launch of the extension is not reported as a failure, short
/// enough that a genuine hang does not look like the script is still working.
let timeout: TimeInterval = 30
var failures = 0

for path in arguments {
    let url = URL(fileURLWithPath: path)
    let name = url.lastPathComponent

    guard FileManager.default.fileExists(atPath: url.path) else {
        print("MISSING  \(name)")
        failures += 1
        continue
    }

    let request = QLThumbnailGenerator.Request(
        fileAt: url,
        size: CGSize(width: 512, height: 512),
        scale: 1,
        representationTypes: .thumbnail
    )

    let finished = DispatchSemaphore(value: 0)
    var line = "TIMEOUT  \(name) (no answer in \(Int(timeout))s)"

    let started = Date()
    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, error in
        if let representation {
            let width = Int(representation.cgImage.width)
            let height = Int(representation.cgImage.height)
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            line = "OK       \(name)  \(width)x\(height)  \(elapsed)ms"
        } else {
            line = "FAILED   \(name)  \(error?.localizedDescription ?? "no reason given")"
        }
        finished.signal()
    }

    if finished.wait(timeout: .now() + timeout) != .success || !line.hasPrefix("OK") {
        failures += 1
    }
    print(line)
}

if failures > 0 {
    print("\n\(failures) of \(arguments.count) failed.")
    exit(1)
}
