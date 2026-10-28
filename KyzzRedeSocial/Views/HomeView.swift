import SwiftUI

struct HomeView: View {
    let onSignUp: () -> Void
    let onLogin: () -> Void

    private let features: [Feature] = [
        Feature(
            icon: "book.fill",
            title: "Livros e conteúdos",
            description: "Material para leitura, estudo e ampliação do repertório.",
            color: Theme.primary
        ),
        Feature(
            icon: "play.rectangle.fill",
            title: "Cursos gratuitos",
            description: "Aprenda dentro da plataforma com uma experiência voltada para evolução.",
            color: Theme.secondary
        ),
        Feature(
            icon: "sparkles",
            title: "Currículo com IA",
            description: "Recursos inteligentes para estudar, organizar ideias e crescer profissionalmente.",
            color: Theme.accent
        ),
        Feature(
            icon: "person.3.fill",
            title: "Comunidade educativa",
            description: "Um ambiente mais seguro e coerente com quem quer aprender e ensinar.",
            color: Theme.lime
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                introCard
                featuresSection

                Text("kyzz.com.br")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 8)
            }
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image("LogoKyzzWordmark")
                .resizable()
                .scaledToFit()
                .frame(height: 96)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                )
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

            Text("Rede Social Educativa")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("Uma rede social em que navegar também é estudar.")
                .font(.system(size: 16))
                .italic()
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 32)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [Theme.primary, Theme.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ao entrar na Rede Social Educativa do Kyzz, você encontra livros, cursos, currículo com IA e uma comunidade pensada para aprendizado, não para distração.")
                .font(.system(size: 15))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onSignUp) {
                Text("Criar conta")
            }
            .buttonStyle(FilledButtonStyle())

            Button(action: onLogin) {
                Text("Já tenho conta")
            }
            .buttonStyle(OutlinedButtonStyle())
        }
        .appCard()
        .padding(.horizontal, 16)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("O que você encontra")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(features) { feature in
                    FeatureCard(feature: feature)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

private struct FeatureCard: View {
    let feature: Feature

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(feature.color)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(feature.color.opacity(0.12))
                )

            Text(feature.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Text(feature.description)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .appCard(padding: 14)
    }
}
