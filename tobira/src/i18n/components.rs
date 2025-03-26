use crate::i18n::I18n;
use yew::prelude::*;

use super::language::Language;
use super::translations::{get_translations, TranslationKey};

/// Properties for the TranslatedText component
#[derive(Properties, PartialEq)]
pub struct TranslatedTextProps {
    /// Function to select the translation key
    #[prop_or_default]
    pub selector: Callback<&'static TranslationKey, String>,

    /// Optional class name
    #[prop_or_default]
    pub class: Classes,

    /// Optional title attribute
    #[prop_or_default]
    pub title: Option<String>,
}

/// A component that renders translated text based on a selector function
#[function_component(TranslatedText)]
pub fn translated_text(props: &TranslatedTextProps) -> Html {
    let i18n = crate::i18n::use_i18n::<Language, TranslationKey>();

    let text = {
        let i18n = i18n.clone();
        let selector = props.selector.clone();

        i18n.t(move |t| &selector.emit(t))
    };

    if let Some(title) = &props.title {
        html! {
            <span class={props.class.clone()} title={title.clone()}>{text}</span>
        }
    } else {
        html! {
            <span class={props.class.clone()}>{text}</span>
        }
    }
}

/// The LanguageProvider component to wrap around the app
#[function_component(I18nProvider)]
pub fn i18n_provider(props: &ChildrenProps) -> Html {
    // Get translations for all languages
    let translations = get_translations();

    // Try to detect the browser language
    let default_language = Language::detect_from_browser();

    // Create i18n instance with detected language
    let i18n = use_memo(move |_| I18n::new(translations, default_language), ());

    html! {
        <>{for props.children.iter()}</>
    }
}

/// Language toggle component with improved UI
#[function_component(LanguageToggle)]
pub fn language_toggle() -> Html {
    let i18n = crate::i18n::use_i18n::<Language, TranslationKey>();

    let on_change = {
        let i18n = i18n.clone();
        Callback::from(move |e: Event| {
            if let Some(select) = e.target_dyn_into::<web_sys::HtmlSelectElement>() {
                let language_code = select.value();
                match language_code.as_str() {
                    "en" => i18n.set_language(Language::EN),
                    "pt-BR" => i18n.set_language(Language::PT_BR),
                    _ => {}
                }
            }
        })
    };

    html! {
        <div class="language-toggle">
            <select
                value={i18n.language().code().to_string()}
                onchange={on_change}
                title="Change language"
            >
                {
                    Language::all().into_iter().map(|lang| {
                        html! {
                            <option value={lang.code().to_string()}>
                                {format!("{} {}", lang.flag(), lang)}
                            </option>
                        }
                    }).collect::<Html>()
                }
            </select>
        </div>
    }
}
