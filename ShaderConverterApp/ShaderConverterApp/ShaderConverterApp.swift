//
//  ShaderConverterApp.swift
//  ShaderConverterApp
//

import SwiftUI

@main
struct ShaderConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
