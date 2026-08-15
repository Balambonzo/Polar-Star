import WidgetKit
import SwiftUI

@main
struct FullFocusWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakHomeWidget()
        StreakLockScreenWidget()
    }
}
