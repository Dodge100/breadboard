import WidgetKit
import SwiftUI

// MARK: - Widget Bundle

@main
struct BreadboardWidgets: WidgetBundle {
    var body: some Widget {
        ActiveRemapsWidget()
        QuickActionsWidget()
        SystemMonitorWidget()
        VariableMonitorWidget()
    }
}
