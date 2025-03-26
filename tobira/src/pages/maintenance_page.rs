use yew::prelude::*;
use yew_router::prelude::*;

use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::router::Route;

/// Component to display when the site is under maintenance
#[function_component(MaintenancePage)]
pub fn maintenance_page() -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();

    // Scheduled maintenance time (could come from backend/config)
    let estimated_completion = "16:00 UTC";

    html! {
        <div class="system-page maintenance-page">
            <div class="system-page-content">
                <div class="system-icon maintenance-icon">
                    <i class="fas fa-tools"></i>
                </div>

                <h1 class="system-title">
                    {i18n.t(|t| &t.maintenance_title)}
                </h1>

                <p class="system-description">
                    {i18n.t(|t| &t.maintenance_message)}
                </p>

                <div class="maintenance-details">
                    <div class="maintenance-info">
                        <span class="label">{i18n.t(|t| &t.estimated_completion)}</span>
                        <span class="value">{estimated_completion}</span>
                    </div>
                </div>

                <div class="system-actions">
                    <a href="javascript:window.location.reload()" class="system-button refresh">
                        <i class="fas fa-sync-alt"></i>
                        {i18n.t(|t| &t.refresh_page)}
                    </a>

                    <Link<Route> to={Route::Home} classes="system-button secondary">
                        <i class="fas fa-home"></i>
                        {i18n.t(|t| &t.try_homepage)}
                    </Link<Route>>
                </div>

                <div class="system-footer">
                    <p>{i18n.t(|t| &t.maintenance_footer)}</p>
                </div>
            </div>
        </div>
    }
}
