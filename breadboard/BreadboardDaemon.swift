import AppKit

struct BreadboardDaemon {
    static func run() {
        NSApp.setActivationPolicy(.prohibited)

        let store = RemapStore(daemonMode: true)
        store.startConfigPolling()
        store.writeDaemonStatus()

        RunLoop.current.run()
    }
}
