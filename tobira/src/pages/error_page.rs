use yew::prelude::*;
use yew_router::prelude::*;

use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::router::Route;

/// Component to display when a server error occurs
#[function_component(ErrorPage)]
pub fn error_page() -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();

    // Error code (could be passed as prop)
    let error_code = "500";

    html! {
        <div class="system-page error-page">
            <div class="system-page-content">
                <div class="system-icon error-icon">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>

                <h1 class="system-title">
                    {format!("{}: {}", error_code, i18n.t(|t| &t.server_error_title))}
                </h1>

                <p class="system-description">
                    {i18n.t(|t| &t.server_error_message)}
                </p>

                <div class="error-details">
                    <p>{i18n.t(|t| &t.server_error_details)}</p>
                </div>

                <div class="system-actions">
                    <a href="javascript:window.location.reload()" class="system-button refresh">
                        <i class="fas fa-sync-alt"></i>
                        {i18n.t(|t| &t.refresh_page)}
                    </a>

                    <Link<Route> to={Route::Home} classes="system-button secondary">
                        <i class="fas fa-home"></i>
                        {i18n.t(|t| &t.back_home)}
                    </Link<Route>>
                </div>

                <div class="system-footer">
                    <p>{i18n.t(|t| &t.report_error)}</p>
                </div>
            </div>
        </div>
    }
}
