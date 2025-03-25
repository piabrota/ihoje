use yew::prelude::*;
use crate::i18n::{use_i18n, Language, TranslationKey};

/// Properties for the LoadingIndicator component
#[derive(Properties, PartialEq)]
pub struct LoadingIndicatorProps {
    /// Optional text to display
    #[prop_or_default]
    pub text: Option<String>,
    
    /// Optional class name for styling
    #[prop_or_default]
    pub class: Classes,
    
    /// Show spinner
    #[prop_or(true)]
    pub with_spinner: bool,
}

/// A reusable loading indicator component
#[function_component(LoadingIndicator)]
pub fn loading_indicator(props: &LoadingIndicatorProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    
    // Get the loading text from props or translations
    let loading_text = match &props.text {
        Some(text) => text.clone(),
        None => i18n.t(|t| &t.loading).to_string(),
    };
    
    // Combine default classes with any provided
    let classes = classes!(
        "loading-container",
        props.class.clone()
    );
    
    html! {
        <div class={classes}>
            if props.with_spinner {
                <div class="loading-spinner"></div>
            }
            <p class="loading-text">{loading_text}</p>
        </div>
    }
}