use yew::prelude::*;
use yew_router::prelude::*;
use crate::router::Route;
use crate::i18n::{use_i18n, Language, TranslationKey};

/// Admin dashboard component
#[function_component(AdminDashboard)]
pub fn admin_dashboard() -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    
    html! {
        <div class="admin-dashboard">
            <h1 class="admin-title">{"iHoje Admin Dashboard"}</h1>
            
            <div class="admin-panels">
                <div class="admin-panel">
                    <h2 class="panel-title">{"Event Management"}</h2>
                    <p>{"Manage events, add new events, or edit existing ones."}</p>
                    <div class="panel-actions">
                        <Link<Route> to={Route::AdminEvents} classes="admin-button">
                            {"View All Events"}
                        </Link<Route>>
                        <Link<Route> to={Route::AdminNewEvent} classes="admin-button primary">
                            {"Add New Event"}
                        </Link<Route>>
                    </div>
                </div>
                
                <div class="admin-panel">
                    <h2 class="panel-title">{"Statistics"}</h2>
                    <div class="stat-grid">
                        <div class="stat-item">
                            <span class="stat-value">{"42"}</span>
                            <span class="stat-label">{"Total Events"}</span>
                        </div>
                        <div class="stat-item">
                            <span class="stat-value">{"3"}</span>
                            <span class="stat-label">{"Cities"}</span>
                        </div>
                        <div class="stat-item">
                            <span class="stat-value">{"12"}</span>
                            <span class="stat-label">{"Free Events"}</span>
                        </div>
                        <div class="stat-item">
                            <span class="stat-value">{"1,254"}</span>
                            <span class="stat-label">{"Page Views"}</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="admin-actions">
                <Link<Route> to={Route::Home} classes="admin-button secondary">
                    {"Back to Site"}
                </Link<Route>>
            </div>
        </div>
    }
}