import SwiftUI

struct MoreView: View {
    @Environment(\.openURL) private var openURL
    let onOpenInApp: (URL) -> Void

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Kyzz") {
                    linkRow("Site oficial", icon: "globe", url: AppConfig.siteURL)
                }

                Section("Conta") {
                    Button {
                        onOpenInApp(AppConfig.deleteAccountURL)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .frame(width: 24)
                                .foregroundColor(.red)

                            Text("Excluir conta")
                                .foregroundColor(.red)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Legal") {
                    linkRow("Termos de uso", icon: "doc.text.fill", url: AppConfig.termsURL)
                    linkRow("Política de privacidade", icon: "hand.raised.fill", url: AppConfig.privacyURL)
                    linkRow("Padrões de segurança", icon: "shield.fill", url: AppConfig.safetyURL)
                }

                Section("Contato") {
                    linkRow("Falar no WhatsApp", icon: "message.fill", url: AppConfig.whatsappURL)

                    ShareLink(item: AppConfig.shareText) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 24)
                                .foregroundColor(Theme.primary)

                            Text("Compartilhar o app")
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }

                Section("Sobre") {
                    HStack {
                        Text("Aplicativo")
                        Spacer()
                        Text(AppConfig.appName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Versão")
                        Spacer()
                        Text(version)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Mais")
        }
    }

    private func linkRow(_ title: String, icon: String, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(Theme.primary)

                Text(title)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }
}
