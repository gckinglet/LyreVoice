import SwiftUI

class NotificationState: ObservableObject {
    static let shared = NotificationState()
    @Published var notificationReceived = false
}

struct ContentView: View {
    @ObservedObject var state = NotificationState.shared

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            if state.notificationReceived {
                Text("Notification Received")
                    .foregroundColor(.red)
                    .padding()
                // Optionally, reset the state to allow for multiple notifications
                Button("Reset") {
                    state.notificationReceived = false
                }
            }
        }
        .padding()
    }
}
