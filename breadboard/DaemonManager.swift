import Foundation

struct DaemonManager {
    static let label = "com.breadboard.daemon"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent("\(label).plist")
    }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    @discardableResult
    static func install() -> Bool {
        guard let executableURL = Bundle.main.executableURL else { return false }

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executableURL.path, "--daemon"],
            "KeepAlive": true,
            "RunAtLoad": true,
            "ThrottleInterval": 5
        ]

        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else { return false }
        try? data.write(to: plistURL)

        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["load", plistURL.path]
        try? task.run()
        task.waitUntilExit()

        return task.terminationStatus == 0
    }

    @discardableResult
    static func uninstall() -> Bool {
        guard isInstalled else { return true }

        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["unload", plistURL.path]
        try? task.run()
        task.waitUntilExit()

        try? FileManager.default.removeItem(at: plistURL)

        return task.terminationStatus == 0
    }

    static var isRunning: Bool {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["list"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.contains(label)
    }

    static func installIfNeeded() {
        let defaults = UserDefaults.standard
        let lastPath = defaults.string(forKey: "daemonExecutablePath")
        let currentPath = Bundle.main.executableURL?.path
        guard lastPath != currentPath || !isInstalled else { return }
        if install() {
            defaults.set(currentPath, forKey: "daemonExecutablePath")
        }
    }
}
