import SwiftUI

@main
struct KyzzRedeSocialApp: App {
    var body: some Scene {
        WindowGroup {
            WebAppView()
                .preferredColorScheme(.light)
        }
    }
}
