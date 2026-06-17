import SwiftUI

@main
struct SpotlightProgressApp: App {
    @State private var monitor = DeviceMonitor()
    @State private var installer = DependencyInstaller()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitor)
                .environment(installer)
                .frame(minWidth: 920, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
