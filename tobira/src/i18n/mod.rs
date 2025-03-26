mod components;
mod language;
mod translations;

// Export the language types
pub use language::Language;
pub use translations::TranslationKey;

// Export the components
pub use components::{I18nProvider, LanguageToggle, TranslatedText};

// Export the i18n traits and types
pub use simple_i18n as i18n;

// Define a temporary replacement for i18nrs
pub struct I18n<L, T> {
    language: L,
    translations: std::collections::HashMap<L, T>,
}

impl<L: Copy + Eq + std::hash::Hash, T> I18n<L, T> {
    pub fn new(translations: std::collections::HashMap<L, T>, default_language: L) -> Self {
        Self {
            language: default_language,
            translations,
        }
    }

    pub fn t<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&T) -> R,
    {
        if let Some(translation) = self.translations.get(&self.language) {
            f(translation)
        } else {
            panic!("Translation not found")
        }
    }

    pub fn language(&self) -> L {
        self.language
    }

    pub fn set_language(&self, _language: L) {
        // This is a stub implementation
    }

    pub fn clone(&self) -> Self {
        Self {
            language: self.language,
            translations: self.translations.clone(),
        }
    }
}

// Define a use_i18n function that returns our I18n type
pub fn use_i18n<L: Copy + Eq + std::hash::Hash + 'static, T: 'static>() -> I18n<L, T> {
    // This is a stub implementation
    use crate::i18n::language::Language;
    use crate::i18n::translations::get_translations;

    let translations = get_translations();
    let default_language = Language::EN;

    I18n::<Language, TranslationKey>::new(translations, default_language)
}

/// Helper function to translate text in a non-component context
pub fn translate<F>(selector: F) -> String
where
    F: Fn(&TranslationKey) -> &String,
{
    // Fallback to English for now
    let fallback = translations::get_translations().get(&Language::EN).unwrap();
    selector(fallback).clone()
}
