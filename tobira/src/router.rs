use yew::prelude::*;
use yew_router::prelude::*;
use wasm_bindgen::prelude::*;
use web_sys::window;

use crate::pages::{HomePage, EventDetailPage, AdminDashboard, AdminEvents, AdminNewEvent, AdminEditEvent, LoginPage, MaintenancePage, ErrorPage};
use crate::components::{RequireAdmin};

#[derive(Clone, Routable, PartialEq)]
pub enum Route {
    #[at("/")]
    Home,
    #[at("/event/:id")]
    EventDetail { id: String },
    
    // Auth routes
    #[at("/login")]
    Login,
    #[at("/auth/callback")]
    AuthCallback,
    
    // Admin routes
    #[at("/admin")]
    Admin,
    #[at("/admin/events")]
    AdminEvents,
    #[at("/admin/event/new")]
    AdminNewEvent,
    #[at("/admin/event/:id/edit")]
    AdminEditEvent { id: String },
    
    // System pages
    #[at("/maintenance")]
    Maintenance,
    #[at("/error")]
    ServerError,
    
    #[not_found]
    #[at("/404")]
    NotFound,
}

pub fn switch(routes: Route) -> Html {
    match routes {
        // Public routes
        Route::Home => {
            html! { <HomePage /> }
        }
        Route::EventDetail { id } => {
            html! { <EventDetailPage id={id} /> }
        }
        Route::Login => {
            html! { <LoginPage /> }
        }
        Route::AuthCallback => {
            // Handle OAuth callback
            handle_auth_callback();
            
            // Show loading spinner during redirection
            html! {
                <div class="auth-callback-container">
                    <div class="loading-spinner"></div>
                    <p>{"Completing authentication..."}</p>
                </div>
            }
        }
        
        // Admin routes - protected by RequireAdmin
        Route::Admin => {
            html! { 
                <RequireAdmin>
                    <AdminDashboard />
                </RequireAdmin>
            }
        }
        Route::AdminEvents => {
            html! { 
                <RequireAdmin>
                    <AdminEvents />
                </RequireAdmin>
            }
        }
        Route::AdminNewEvent => {
            html! { 
                <RequireAdmin>
                    <AdminNewEvent />
                </RequireAdmin>
            }
        }
        Route::AdminEditEvent { id: _ } => {
            html! { 
                <RequireAdmin>
                    <AdminEditEvent />
                </RequireAdmin>
            }
        }
        
        // System pages
        Route::Maintenance => {
            html! { <MaintenancePage /> }
        }
        Route::ServerError => {
            html! { <ErrorPage /> }
        }
        
        // Not found route
        Route::NotFound => {
            // Redirect to home page automatically
            redirect_to_home();
            
            // Show a temporary loading state while redirecting
            html! {
                <div class="redirect-loading">
                    <div class="loading-spinner"></div>
                    <p>{"Redirecting to home page..."}</p>
                </div>
            }
        }
    }
}

/// Redirects the user to the home page
#[wasm_bindgen]
pub fn redirect_to_home() {
    // Simple approach that works reliably
    if let Some(window) = window() {
        // Just set the href directly - most foolproof method
        let _ = window.location().set_href("/");
    }
}

/// Handle OAuth callback after authentication
#[wasm_bindgen]
pub fn handle_auth_callback() {
    use web_sys::Storage;
    use gloo_storage::{LocalStorage, Storage as GlooStorage};
    use gloo_timers::callback::Timeout;
    
    // Give the browser a moment to complete the authentication process
    let timeout = Timeout::new(1000, move || {
        // Check for a redirect path in local storage
        let redirect_path = match LocalStorage::get::<String>("ihoje_auth_redirect") {
            Ok(path) => path,
            Err(_) => "/".to_string() // Default to home
        };
        
        // Clear the redirect path from storage
        LocalStorage::delete("ihoje_auth_redirect");
        
        // Redirect to the original requested page
        if let Some(window) = window() {
            log::info!("Auth callback: redirecting to {}", redirect_path);
            let _ = window.location().set_href(&redirect_path);
        }
    });
    
    // Prevent the timeout from being dropped
    timeout.forget();
}