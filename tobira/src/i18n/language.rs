use serde::Deserialize;
use web_sys;

/// Language enum defines available languages
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Deserialize)]
pub enum Language {
    EN,
    PT_BR,
}

impl Default for Language {
    fn default() -> Self {
        Language::EN
    }
}

impl std::fmt::Display for Language {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Language::EN => write!(f, "English"),
            Language::PT_BR => write!(f, "Português (Brasil)"),
        }
    }
}

impl Language {
    /// Returns the language code (e.g., "en", "pt-BR")
    pub fn code(&self) -> &'static str {
        match self {
            Language::EN => "en",
            Language::PT_BR => "pt-BR",
        }
    }

    /// Returns the flag emoji for the language
    pub fn flag(&self) -> &'static str {
        match self {
            Language::EN => "🇺🇸",
            Language::PT_BR => "🇧🇷",
        }
    }

    /// Returns all available languages
    pub fn all() -> Vec<Self> {
        vec![Language::EN, Language::PT_BR]
    }

    /// Detects the language from the browser's language setting
    pub fn from_browser_language(browser_lang: &str) -> Self {
        let lang_code = browser_lang.to_lowercase();

        if lang_code.starts_with("pt") || lang_code.starts_with("pt-br") {
            Language::PT_BR
        } else {
            Language::EN
        }
    }

    /// Attempts to detect the browser language using web API
    pub fn detect_from_browser() -> Self {
        web_sys::window()
            .and_then(|window| window.navigator().language())
            .map(|lang| Self::from_browser_language(&lang))
            .unwrap_or_default()
    }
}
