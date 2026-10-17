import SwiftUI

@main
struct KyzzRedeSocialApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.light)
        }
    }
}
