import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .network
    @StateObject private var webModel = WebViewModel()

    private enum Tab: Hashable {
        case network
        case more
    }

    var body: some View {
        TabView(selection: $selection) {
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
}
