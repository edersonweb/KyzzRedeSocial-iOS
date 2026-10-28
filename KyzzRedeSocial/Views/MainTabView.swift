import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .home
    @StateObject private var webModel = WebViewModel()

    private enum Tab: Hashable {
        case home
        case network
        case more
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(
                onSignUp: { openNetwork(AppConfig.signupURL) },
                onLogin: { openNetwork(AppConfig.loginURL) }
            )
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }
            .tag(Tab.home)

            NetworkView(model: webModel)
                .tabItem {
                    Label("Rede", systemImage: "person.3.fill")
                }
                .tag(Tab.network)

            MoreView(onOpenInApp: { url in
                webModel.open(url: url)
                selection = .network
            })
            .tabItem {
                Label("Mais", systemImage: "ellipsis.circle.fill")
            }
            .tag(Tab.more)
        }
        .tint(Theme.primary)
    }

    private func openNetwork(_ url: URL) {
        webModel.open(url: url)
        selection = .network
    }
}
