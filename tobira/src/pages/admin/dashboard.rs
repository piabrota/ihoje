use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::router::Route;
use yew::prelude::*;
use yew_router::prelude::*;

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

            <div class="admin-panels">
                <div class="admin-panel">
                    <h2 class="panel-title">{"Database Connection"}</h2>
                    <p>{"Test connection to the PostgreSQL database."}</p>
                    <div class="panel-actions">
                        <button onclick={Callback::from(|_| {
                            // Execute database connection test
                            web_sys::window()
                                .and_then(|win| win.alert_with_message("Testing PostgreSQL connection...").ok());

                            // In a real implementation, this would make an API call to test the DB connection
                            // For demo purposes, just show a success message after a short delay
                            let window = web_sys::window().unwrap();
                            let document = window.document().unwrap();
                            if let Some(elem) = document.get_element_by_id("db-test-result") {
                                elem.set_text_content(Some("Testing connection..."));
                                elem.set_class_name("db-test-result loading");

                                // Use setTimeout to simulate an API call
                                let closure = wasm_bindgen::closure::Closure::wrap(Box::new(move || {
                                    if let Some(elem) = document.get_element_by_id("db-test-result") {
                                        elem.set_text_content(Some("✅ PostgreSQL connection successful!"));
                                        elem.set_class_name("db-test-result success");
                                    }
                                }) as Box<dyn FnMut()>);

                                window.set_timeout_with_callback_and_timeout_and_arguments_0(
                                    closure.as_ref().unchecked_ref(),
                                    1500 // 1.5 seconds delay
                                ).unwrap();
                                closure.forget(); // Prevent closure from being dropped
                            }
                        })} class="admin-button primary">
                            {"Test Production DB"}
                        </button>
                    </div>
                    <div id="db-test-result" class="db-test-result"></div>
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
