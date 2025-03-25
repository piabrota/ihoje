use yew::prelude::*;
use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::api::ApiError;

/// Properties for the ErrorDisplay component
#[derive(Properties, PartialEq)]
pub struct ErrorDisplayProps {
    /// The error to display
    pub error: ApiError,
    
    /// Optional class name for styling
    #[prop_or_default]
    pub class: Classes,
    
    /// Optional retry callback
    #[prop_or_default]
    pub on_retry: Option<Callback<()>>,
}

/// A reusable error display component
#[function_component(ErrorDisplay)]
pub fn error_display(props: &ErrorDisplayProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    
    // Get error type-specific classes
    let error_class = match &props.error {
        ApiError::NotFound(_) => "error-not-found",
        ApiError::ClientError { .. } => "error-client",
        ApiError::ServerError { .. } => "error-server",
        _ => "error-generic",
    };
    
    // Combine classes
    let classes = classes!(
        "error-container",
        error_class,
        props.class.clone()
    );
    
    // Create retry handler if callback provided
    let on_retry = props.on_retry.clone().map(|callback| {
        Callback::from(move |_| {
            callback.emit(());
        })
    });
    
    html! {
        <div class={classes}>
            <div class="error-icon">
                {
                    match &props.error {
                        ApiError::NotFound(_) => "🔍",
                        ApiError::ServerError { .. } => "🚨",
                        ApiError::ClientError { .. } => "⚠️",
                        _ => "❌",
                    }
                }
            </div>
            <h3 class="error-title">
                {
                    match &props.error {
                        ApiError::NotFound(_) => i18n.t(|t| &t.not_found),
                        ApiError::ServerError { .. } => "Server Error",
                        ApiError::ClientError { .. } => "Request Error",
                        _ => i18n.t(|t| &t.error),
                    }
                }
            </h3>
            <p class="error-message">{props.error.message()}</p>
            
            if let Some(callback) = on_retry {
                <button class="retry-button" onclick={callback}>
                    {"Try Again"}
                </button>
            }
        </div>
    }
}