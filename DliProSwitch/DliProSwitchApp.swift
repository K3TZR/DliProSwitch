//
//  DliProSwitchApp.swift
//  DliProSwitch
//
//  Created by Douglas Adams on 1/11/23.
//

import Foundation
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@main
struct DliProSwitchApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  var appDelegate

  @StateObject var model = DataModel()
  let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "?"
  let build   = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as? String ?? "?"

  var body: some Scene {

    WindowGroup("v" + version + "." + build) {
      DashboardView(model: model )
        .padding()
        .toolbar {
          ToolbarItemGroup {
            Button("Settings") { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }
            Button("Refresh") { model.relaysRefresh() }
          }
        }
    }
    .windowStyle(.hiddenTitleBar)

    .commands {
      CommandGroup(before: .singleWindowList) {
        Button("Refresh") {
          model.relaysRefresh()
        }.keyboardShortcut("r", modifiers: [.option, .command])
      }
    }

    Settings {
      SettingsView(model: model)
    }
    .windowStyle(.hiddenTitleBar)
    .windowResizability(WindowResizability.contentSize)
    .defaultPosition(.topLeading)
  }
}
