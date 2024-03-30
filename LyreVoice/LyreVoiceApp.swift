import SwiftUI
import Foundation

// Define a context to pass to the callback function
struct NotificationContext {
    let callback: () -> Void
}

// Notification manager that sets up listening for Darwin Notifications
class NotificationManager {
    static let shared = NotificationManager()
    
    private var context: NotificationContext?
    
    func startListening(for notificationName: String, using block: @escaping () -> Void) {
        context = NotificationContext(callback: block)
        
        let cfNotificationName = CFNotificationName(notificationName as CFString)
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        { _, observer, _, _, _ in
                                            guard let observer = observer else { return }
                                            let manager = Unmanaged<NotificationManager>.fromOpaque(observer).takeUnretainedValue()
                                            manager.context?.callback()
                                        },
                                        cfNotificationName.rawValue,
                                        nil,
                                        CFNotificationSuspensionBehavior.deliverImmediately)
    }
}

// ContentView that listens for notifications and updates its view accordingly
struct ContentView: View {
    @State private var notificationReceived = false

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            if notificationReceived {
                Text("Notification Received")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            NotificationManager.shared.startListening(for: "com.example.KeyboardExtension.Notification") {
                // This block is called when the notification is received
                self.notificationReceived = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@main
struct LyreVoice: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

