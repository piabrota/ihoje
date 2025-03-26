use gloo::console::log;
use yew::prelude::*;
use yew_router::prelude::*;

use crate::api::ApiClient;
use crate::components::{ErrorDisplay, LoadingIndicator};
use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::models::Event;
use crate::router::Route;
use crate::utils::use_api_query;

/// Admin events page
#[function_component(AdminEvents)]
pub fn admin_events() -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let navigator = use_navigator().unwrap();
    let client = use_memo(|_| ApiClient::new(), ());

    // Fetch all events
    let (events, is_loading, error) = {
        let client = client.clone();

        use_api_query(move || async move { client.fetch_events_admin().await })
    };

    // Handle add new event
    let on_add_new = {
        let navigator = navigator.clone();
        Callback::from(move |_| {
            navigator.push(&Route::AdminNewEvent);
        })
    };

    // Handle edit event
    let on_edit = {
        let navigator = navigator.clone();
        Callback::from(move |id: String| {
            navigator.push(&Route::AdminEditEvent { id });
        })
    };

    // Handle delete event
    let on_delete = {
        let client = client.clone();
        Callback::from(move |id: String| {
            if !window()
                .confirm_with_message(&format!("Are you sure you want to delete event: {}?", id))
                .unwrap_or(false)
            {
                return;
            }

            let client = client.clone();
            wasm_bindgen_futures::spawn_local(async move {
                match client.delete_event(&id).await {
                    Ok(_) => {
                        log!("Event deleted successfully");
                        // Reload the page to refresh the events list
                        window().location().reload().ok();
                    }
                    Err(e) => {
                        log!("Error deleting event:", e.to_string());
                        window()
                            .alert_with_message(&format!("Error deleting event: {}", e))
                            .ok();
                    }
                }
            });
        })
    };

    html! {
        <div class="admin-events">
            <div class="admin-header">
                <h1 class="admin-title">{"Event Management"}</h1>
                <div class="admin-actions">
                    <button class="admin-button primary" onclick={on_add_new}>
                        <i class="fas fa-plus"></i>{" Add New Event"}
                    </button>
                    <Link<Route> to={Route::Admin} classes="admin-button secondary">
                        {"Back to Dashboard"}
                    </Link<Route>>
                </div>
            </div>

            if is_loading {
                <LoadingIndicator />
            } else if let Some(err) = error {
                <ErrorDisplay error={err} />
            } else if let Some(event_list) = events.clone() {
                <div class="admin-events-list">
                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>{"ID"}</th>
                                <th>{"Title"}</th>
                                <th>{"Date"}</th>
                                <th>{"City"}</th>
                                <th>{"Price"}</th>
                                <th>{"Actions"}</th>
                            </tr>
                        </thead>
                        <tbody>
                            {
                                event_list.iter().map(|event| {
                                    let id = event.id.clone();
                                    let on_edit = {
                                        let id = id.clone();
                                        let on_edit = on_edit.clone();
                                        Callback::from(move |_| {
                                            on_edit.emit(id.clone());
                                        })
                                    };

                                    let on_delete = {
                                        let id = id.clone();
                                        let on_delete = on_delete.clone();
                                        Callback::from(move |_| {
                                            on_delete.emit(id.clone());
                                        })
                                    };

                                    html! {
                                        <tr>
                                            <td>{&event.id}</td>
                                            <td>{&event.title}</td>
                                            <td>{&event.date}</td>
                                            <td>{&event.city}</td>
                                            <td>{&event.price}</td>
                                            <td class="action-cell">
                                                <button class="action-btn edit" onclick={on_edit}>
                                                    <i class="fas fa-edit"></i>
                                                </button>
                                                <button class="action-btn delete" onclick={on_delete}>
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </td>
                                        </tr>
                                    }
                                }).collect::<Html>()
                            }
                        </tbody>
                    </table>
                </div>
            } else {
                <div class="empty-state">
                    <p>{"No events found. Add some events to get started."}</p>
                    <button class="admin-button primary" onclick={on_add_new}>
                        {"Add New Event"}
                    </button>
                </div>
            }
        </div>
    }
}

// Helper function to get window
fn window() -> web_sys::Window {
    web_sys::window().expect("No window object available")
}
