import Foundation

enum AppConfig {
    static let appName = "Kyzz Rede Social"

    static let siteURL = URL(string: "https://kyzz.com.br")!
    static let signupURL = URL(string: "https://kyzz.com.br/cadastro_rede_social.php")!
    static let loginURL = URL(string: "https://kyzz.com.br/login_rede_social.php")!
    static let feedURL = URL(string: "https://kyzz.com.br/rede_social.php")!
    static let termsURL = URL(string: "https://kyzz.com.br/termos_uso_rede_social.php")!
    static let privacyURL = URL(string: "https://kyzz.com.br/politica_privacidade_rede_social.php")!
    static let safetyURL = URL(string: "https://kyzz.com.br/padroes_seguranca_rede_social.php")!
    static let deleteAccountURL = URL(string: "https://kyzz.com.br/excluir_conta_rede_social.php")!
    static let whatsappURL = URL(string: "https://wa.me/5519988102977?text=Ol%C3%A1!%20Quero%20mais%20informa%C3%A7%C3%B5es%20sobre%20o%20Kyzz.")!

    static let allowedHosts = ["kyzz.com.br"]

    /// Páginas comerciais (planos/escolas) e home do site que não podem ser acessadas dentro do aplicativo.
    static let blockedPaths = [
        "kyzz_para_escolas.php",
        "checkout_plano.php",
        "obrigado_plano.php",
        "cadastro.php",
        "index.php"
    ]

    static let shareText = "Conheça o Kyzz, a rede social educativa: https://kyzz.com.br"
}
