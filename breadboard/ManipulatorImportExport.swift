import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - UTType

extension UTType {
    /// The breadboard manipulator file format: a single `Manipulator` encoded as JSON.
    static var breadboardManipulator: UTType {
        UTType(exportedAs: "com.breadboard.manipulator", conformingTo: .json)
    }
}

// MARK: - File I/O

enum ManipulatorFile {
    /// The file extension for exported manipulator files (no leading dot).
    static let fileExtension = "breadboardmanipulator"

    // MARK: Export

    /// Encode a manipulator as JSON data.
    static func encode(_ manipulator: Manipulator) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(manipulator)
    }

    /// Write a single manipulator to a file URL.
    static func write(_ manipulator: Manipulator, to url: URL) throws {
        try encode(manipulator).write(to: url)
    }

    /// Show a save panel and export the given manipulator.
    /// - Returns: `true` if the file was written successfully.
    @MainActor
    @discardableResult
    static func export(_ manipulator: Manipulator) -> Bool {
        let panel = NSSavePanel()
        panel.title = "Export Manipulator"
        panel.nameFieldStringValue = sanitizedFilename(for: manipulator.name)
        panel.allowedContentTypes = [.breadboardManipulator]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        do {
            try write(manipulator, to: url)
            return true
        } catch {
            NSAlert(error: error).runModal()
            return false
        }
    }

    // MARK: Import

    /// Decode a manipulator from JSON data.
    static func decode(_ data: Data) throws -> Manipulator {
        try JSONDecoder().decode(Manipulator.self, from: data)
    }

    /// Read and decode a manipulator from a file URL.
    static func read(from url: URL) throws -> Manipulator {
        try decode(Data(contentsOf: url))
    }

    /// Show an open panel and return the selected manipulator.
    @MainActor
    static func importSingle() -> Manipulator? {
        let panel = NSOpenPanel()
        panel.title = "Import Manipulator"
        panel.allowedContentTypes = [.breadboardManipulator]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            return try read(from: url)
        } catch {
            NSAlert(error: error).runModal()
            return nil
        }
    }

    // MARK: Helpers

    /// Derive a safe file name from the manipulator name.
    private static func sanitizedFilename(for name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        let safe = name.unicodeScalars.filter { allowed.contains($0) }.map(Character.init)
        let trimmed = String(safe).trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Untitled" : trimmed
        return "\(base).\(fileExtension)"
    }
}

// MARK: - Drag-and-Drop support

/// A drop delegate that imports `.breadboardmanipulator` files into the store.
struct ManipulatorDropDelegate: DropDelegate {
    let store: RemapStore

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.fileURL])
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [.fileURL]).first else { return false }

        item.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
            guard let data,
                  let urlData = data as? Data,
                  let urlString = String(data: urlData, encoding: .utf8),
                  let url = URL(string: urlString),
                  url.pathExtension == ManipulatorFile.fileExtension
            else { return }

            Task { @MainActor in
                store.importManipulator(from: url)
            }
        }
        return true
    }
}
