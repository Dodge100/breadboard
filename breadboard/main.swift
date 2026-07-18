import SwiftUI

if CommandLine.arguments.contains("--daemon") {
    BreadboardDaemon.run()
} else {
    breadboardApp.main()
}
