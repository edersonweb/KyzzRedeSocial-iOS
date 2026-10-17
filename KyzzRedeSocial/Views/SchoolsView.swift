import SwiftUI

struct SchoolsView: View {
    @Environment(\.openURL) private var openURL

    private let features: [SchoolFeature] = [
        SchoolFeature(
            icon: "person.2.fill",
            title: "Gestão de alunos e turmas",
            description: "Cadastre alunos, organize turmas, controle presença, notas, entregas e o histórico de cada estudante."
        ),
        SchoolFeature(
            icon: "laptopcomputer",
            title: "Aulas EAD e presenciais",
            description: "Crie aulas completas, com trilhas de aprendizagem, liberação por bloco e acompanhamento em tempo real."
        ),
        SchoolFeature(
            icon: "gamecontroller.fill",
            title: "Aulas gamificadas",
            description: "Jogos pedagógicos, vídeos interativos, cliques e diálogos que prendem a atenção do aluno."
        ),
        SchoolFeature(
            icon: "person.crop.circle",
            title: "Portal do aluno",
            description: "Acesso individual com atividades, notas e trilha de aprendizagem em qualquer dispositivo."
        ),
        SchoolFeature(
            icon: "checkmark.seal.fill",
            title: "Avaliações e provas",
            description: "Crie provas e atividades com correção, notas e relatórios de desempenho por turma."
        ),
        SchoolFeature(
            icon: "person.3.fill",
            title: "Rede Social Educativa",
            description: "Sua escola contribui para uma rede social educativa que favorece o aprendizado dos jovens."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                featuresCard
                freeCard
                institutionsCard

                Button {
                    openURL(AppConfig.whatsappURL)
                } label: {
                    Label("Falar no WhatsApp", systemImage: "message.fill")
                }
                .buttonStyle(FilledButtonStyle(color: Theme.secondary))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 42))
                .foregroundColor(.white)

            Text("Kyzz para escolas")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("O sistema completo para gerenciar alunos e turmas, criar aulas EAD e presenciais, com aulas gamificadas e interativas.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [Theme.primary, Theme.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Um sistema poderoso para a sua escola")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            ForEach(features) { feature in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Theme.primary.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        Text(feature.description)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }

    private var freeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Gratuito para a rede pública", systemImage: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.secondary)

            Text("Professores e escolas da rede pública usam o Kyzz sem nenhum custo. Use o e-mail institucional terminado em .gov ou .gov.br.")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                bullet("Sem mensalidade e sem taxa de adesão")
                bullet("2 turmas e 50 alunos por turma")
                bullet("Aulas com vídeo, PDF, slides, áudio e jogos")
                bullet("Avaliações com nota automática e relatórios")
            }

            Button {
                openURL(AppConfig.publicSchoolSignupURL)
            } label: {
                Text("Criar minha conta gratuita")
            }
            .buttonStyle(FilledButtonStyle(color: Theme.secondary))
            .padding(.top, 4)
        }
        .appCard()
        .padding(.horizontal, 16)
    }

    private var institutionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Escolas particulares e instituições", systemImage: "building.2.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.primary)

            Text("Atendemos escolas, faculdades, empresas e igrejas com condições específicas para várias turmas, professores e treinamentos.")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Planos a partir de R$ 50,00/mês. Fale com a equipe para receber a proposta ideal.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            Button {
                openURL(AppConfig.schoolsURL)
            } label: {
                Text("Ver planos no site")
            }
            .buttonStyle(OutlinedButtonStyle())
            .padding(.top, 4)
        }
        .appCard()
        .padding(.horizontal, 16)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Theme.secondary)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SchoolFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
