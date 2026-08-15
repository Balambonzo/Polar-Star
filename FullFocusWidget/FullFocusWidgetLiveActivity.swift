//
//  FullFocusWidgetLiveActivity.swift
//  FullFocusWidget
//
//  Created by Alberto Toscano on 07/08/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FullFocusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FullFocusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FullFocusWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FullFocusWidgetAttributes {
    fileprivate static var preview: FullFocusWidgetAttributes {
        FullFocusWidgetAttributes(name: "World")
    }
}

extension FullFocusWidgetAttributes.ContentState {
    fileprivate static var smiley: FullFocusWidgetAttributes.ContentState {
        FullFocusWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FullFocusWidgetAttributes.ContentState {
         FullFocusWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FullFocusWidgetAttributes.preview) {
   FullFocusWidgetLiveActivity()
} contentStates: {
    FullFocusWidgetAttributes.ContentState.smiley
    FullFocusWidgetAttributes.ContentState.starEyes
}
