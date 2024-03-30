import SwiftUI

@main
struct LyreVoice: App {
    // Use UIApplicationDelegateAdaptor to integrate AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

