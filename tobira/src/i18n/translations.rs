use serde::Deserialize;
use std::collections::HashMap;

use super::language::Language;

/// Translation key struct for type safety
#[derive(Deserialize, Clone, Debug)]
pub struct TranslationKey {
    // Common
    pub app_name: String,
    pub app_description: String,
    pub loading: String,
    pub error: String,
    pub not_found: String,
    pub back_home: String,
    pub copyright: String,
    pub refresh_page: String,
    pub try_homepage: String,
    
    // Navigation
    pub home: String,
    pub events: String,
    pub about: String,
    
    // Home page
    pub welcome_title: String,
    pub welcome_message: String,
    pub events_title: String,
    pub no_events_found: String,
    
    // Events
    pub event_details: String,
    pub event_date: String,
    pub event_location: String,
    pub event_price: String,
    pub event_city: String,
    pub event_url: String,
    pub free_event: String,
    pub favorite_add: String,
    pub favorite_remove: String,
    
    // Filters
    pub search_events: String,
    pub filter_by_city: String,
    pub filter_date_from: String,
    pub filter_date_to: String,
    pub show_free_only: String,
    pub filter_apply: String,
    pub filter_clear: String,
    pub all_cities: String,
    
    // Footer
    pub footer_links: String,
    pub footer_copyright: String,
    
    // Authentication
    pub login: String,
    pub logout: String,
    pub profile: String,
    pub admin: String,
    pub login_title: String,
    pub login_subtitle: String,
    pub login_with_google: String,
    pub login_required: String,
    pub login_error: String,
    pub access_denied: String,
    pub access_denied_message: String,
    
    // Maintenance page
    pub maintenance_title: String,
    pub maintenance_message: String,
    pub maintenance_footer: String,
    pub estimated_completion: String,
    
    // Error page
    pub server_error_title: String,
    pub server_error_message: String,
    pub server_error_details: String,
    pub report_error: String,
}

/// Get all available translations
pub fn get_translations() -> HashMap<Language, TranslationKey> {
    let mut translations = HashMap::new();
    
    // English translations
    translations.insert(Language::EN, TranslationKey {
        // Common
        app_name: "iHoje".into(),
        app_description: "Your source for local events and concerts.".into(),
        loading: "Loading...".into(),
        error: "An error occurred.".into(),
        not_found: "Page not found.".into(),
        back_home: "Back to home".into(),
        copyright: "© 2025 iHoje - All events in one place".into(),
        refresh_page: "Refresh page".into(),
        try_homepage: "Try homepage".into(),
        
        // Navigation
        home: "Home".into(),
        events: "Events".into(),
        about: "About".into(),
        
        // Home page
        welcome_title: "Welcome to iHoje".into(),
        welcome_message: "Discover the best events happening near you.".into(),
        events_title: "Events".into(),
        no_events_found: "No events found.".into(),
        
        // Events
        event_details: "Event Details".into(),
        event_date: "Date".into(),
        event_location: "Location".into(),
        event_price: "Price".into(),
        event_city: "City".into(),
        event_url: "Event Link".into(),
        free_event: "Free".into(),
        favorite_add: "Add to favorites".into(),
        favorite_remove: "Remove from favorites".into(),
        
        // Filters
        search_events: "Search events...".into(),
        filter_by_city: "Filter by city".into(),
        filter_date_from: "From".into(),
        filter_date_to: "To".into(),
        show_free_only: "Show free events only".into(),
        filter_apply: "Apply".into(),
        filter_clear: "Clear".into(),
        all_cities: "All cities".into(),
        
        // Footer
        footer_links: "Links".into(),
        footer_copyright: "All rights reserved".into(),
        
        // Authentication
        login: "Login".into(),
        logout: "Logout".into(),
        profile: "Profile".into(),
        admin: "Admin Dashboard".into(),
        login_title: "Login to iHoje".into(),
        login_subtitle: "Sign in to access your account and manage events".into(),
        login_with_google: "Sign in with Google".into(),
        login_required: "You need to log in to access this page".into(),
        login_error: "Failed to log in. Please try again.".into(), 
        access_denied: "Access Denied".into(),
        access_denied_message: "You don't have permission to access this area.".into(),
        
        // Maintenance page
        maintenance_title: "We're under maintenance".into(),
        maintenance_message: "We're performing scheduled maintenance to improve your experience. Please check back soon.".into(),
        maintenance_footer: "Thank you for your patience.".into(),
        estimated_completion: "Estimated completion time:".into(),
        
        // Error page
        server_error_title: "Server Error".into(),
        server_error_message: "Something went wrong on our server. We're working to fix the issue.".into(),
        server_error_details: "Our team has been notified and is working to resolve the issue as quickly as possible.".into(),
        report_error: "If the problem persists, please contact support.".into(),
    });
    
    // Portuguese (Brazil) translations
    translations.insert(Language::PT_BR, TranslationKey {
        // Common
        app_name: "iHoje".into(),
        app_description: "Sua fonte para eventos e shows locais.".into(),
        loading: "Carregando...".into(),
        error: "Ocorreu um erro.".into(),
        not_found: "Página não encontrada.".into(),
        back_home: "Voltar para o início".into(),
        copyright: "© 2025 iHoje - Todos os eventos em um só lugar".into(),
        refresh_page: "Atualizar página".into(),
        try_homepage: "Tentar página inicial".into(),
        
        // Navigation
        home: "Início".into(),
        events: "Eventos".into(),
        about: "Sobre".into(),
        
        // Home page
        welcome_title: "Bem-vindo ao iHoje".into(),
        welcome_message: "Descubra os melhores eventos acontecendo perto de você.".into(),
        events_title: "Eventos".into(),
        no_events_found: "Nenhum evento encontrado.".into(),
        
        // Events
        event_details: "Detalhes do Evento".into(),
        event_date: "Data".into(),
        event_location: "Local".into(),
        event_price: "Preço".into(),
        event_city: "Cidade".into(),
        event_url: "Link do Evento".into(),
        free_event: "Gratuito".into(),
        favorite_add: "Adicionar aos favoritos".into(),
        favorite_remove: "Remover dos favoritos".into(),
        
        // Filters
        search_events: "Buscar eventos...".into(),
        filter_by_city: "Filtrar por cidade".into(),
        filter_date_from: "De".into(),
        filter_date_to: "Até".into(),
        show_free_only: "Mostrar apenas eventos gratuitos".into(),
        filter_apply: "Aplicar".into(),
        filter_clear: "Limpar".into(),
        all_cities: "Todas as cidades".into(),
        
        // Footer
        footer_links: "Links".into(),
        footer_copyright: "Todos os direitos reservados".into(),
        
        // Authentication
        login: "Entrar".into(),
        logout: "Sair".into(),
        profile: "Perfil".into(),
        admin: "Painel Administrativo".into(),
        login_title: "Entrar no iHoje".into(),
        login_subtitle: "Faça login para acessar sua conta e gerenciar eventos".into(),
        login_with_google: "Entrar com Google".into(),
        login_required: "Você precisa fazer login para acessar esta página".into(),
        login_error: "Falha ao fazer login. Por favor, tente novamente.".into(),
        access_denied: "Acesso Negado".into(),
        access_denied_message: "Você não tem permissão para acessar esta área.".into(),
        
        // Maintenance page
        maintenance_title: "Estamos em manutenção".into(),
        maintenance_message: "Estamos realizando uma manutenção programada para melhorar sua experiência. Por favor, volte em breve.".into(),
        maintenance_footer: "Obrigado pela sua paciência.".into(),
        estimated_completion: "Tempo estimado para conclusão:".into(),
        
        // Error page
        server_error_title: "Erro no Servidor".into(),
        server_error_message: "Algo deu errado no nosso servidor. Estamos trabalhando para resolver o problema.".into(),
        server_error_details: "Nossa equipe foi notificada e está trabalhando para resolver o problema o mais rápido possível.".into(),
        report_error: "Se o problema persistir, entre em contato com o suporte.".into(),
    });
    
    translations
}