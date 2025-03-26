use gloo_storage::{LocalStorage, Storage};
use log;
use serde_json::{json, Value};
use wasm_bindgen::JsCast;
use web_sys::{window, HtmlInputElement};
use yew::prelude::*;
use yew_router::prelude::*;

use crate::api::SupabaseAuth;
use crate::components::use_auth;
use crate::models::{AuthState, User, UserRole};
use crate::router::Route;
use crate::utils::config::get_config;

/// Login page component
#[function_component(LoginPage)]
pub fn login_page() -> Html {
    let auth = use_auth();
    let navigator = use_navigator().unwrap();
    let email_ref = use_node_ref();
    let password_ref = use_node_ref();
    let error_message = use_state(|| String::new());
    let is_loading = use_state(|| false);

    // Get requested path from URL query params if available
    let location = use_location().unwrap();
    let redirect_to = location.query::<String>().unwrap_or_else(|_| String::new());

    // Store redirect path in local storage if it exists
    use_effect_with_deps(
        move |redirect| {
            if !redirect.is_empty() {
                log::info!("Storing redirect path: {}", redirect);
                let _ = LocalStorage::set("ihoje_auth_redirect", redirect.clone());
            }
            || ()
        },
        redirect_to.clone(),
    );

    // If already logged in, redirect appropriately
    let already_authed = auth.is_authenticated();
    let navigator_clone = navigator.clone();

    use_effect_with_deps(
        move |_| {
            if already_authed {
                // Check if we should redirect to admin
                let redirect_path = match LocalStorage::get::<String>("ihoje_auth_redirect") {
                    Ok(path) => {
                        if path.starts_with("/admin") && auth.is_admin() {
                            LocalStorage::delete("ihoje_auth_redirect");
                            path
                        } else {
                            "/".to_string() // Default to home
                        }
                    }
                    Err(_) => "/".to_string(), // Default to home
                };

                log::info!(
                    "User already authenticated, redirecting to {}",
                    redirect_path
                );

                if redirect_path.starts_with("/admin") {
                    navigator_clone.push(&Route::Admin);
                } else {
                    navigator_clone.push(&Route::Home);
                }
            }
            || ()
        },
        already_authed,
    );

    // Handle Google login
    let handle_google_login = {
        let login = auth.login.clone();
        let is_loading = is_loading.clone();

        Callback::from(move |_| {
            is_loading.set(true);
            login.emit(());
        })
    };

    // Handle manual login form submission (for dev/test purposes)
    let handle_form_submit = {
        let email_ref = email_ref.clone();
        let password_ref = password_ref.clone();
        let error_message = error_message.clone();
        let is_loading = is_loading.clone();
        let navigator = navigator.clone();

        Callback::from(move |e: SubmitEvent| {
            e.prevent_default();
            is_loading.set(true);
            error_message.set(String::new());

            // Check if we're in a debug build
            #[cfg(debug_assertions)]
            let enable_test_credentials = true;
            #[cfg(not(debug_assertions))]
            let enable_test_credentials = false;

            if !enable_test_credentials {
                error_message
                    .set("Direct login is disabled in production. Please use OAuth.".to_string());
                is_loading.set(false);
                return;
            }

            let email = email_ref
                .cast::<HtmlInputElement>()
                .map(|input| input.value())
                .unwrap_or_default();

            let password = password_ref
                .cast::<HtmlInputElement>()
                .map(|input| input.value())
                .unwrap_or_default();

            // For testing purposes - allow test credentials (debug builds only)
            if (email == "admin@test.com" && password == "admin123")
                || (email == "test@example.com" && password == "password123")
            {
                // Create a mock user for development/testing
                let user = User {
                    id: "test-admin-123".to_string(),
                    email: email.clone(),
                    name: Some("Test Admin".to_string()),
                    avatar_url: None,
                    role: UserRole::Admin,
                    access_token: Some("mock-token-123".to_string()),
                    refresh_token: Some("mock-refresh-123".to_string()),
                };

                // Save to local storage
                match serde_json::to_string(&user) {
                    Ok(json) => {
                        let _ = LocalStorage::set("ihoje_auth", json);

                        // Redirect to admin dashboard
                        log::info!("Mock login successful, redirecting to admin");
                        navigator.push(&Route::Admin);
                    }
                    Err(e) => {
                        error_message.set(format!("Error saving auth state: {}", e));
                        is_loading.set(false);
                    }
                }
            } else {
                error_message.set("Invalid email or password".to_string());
                is_loading.set(false);
            }
        })
    };

    html! {
        <div class="login-page">
            <div class="login-container">
                <div class="login-header">
                    <div class="login-logo">{"🎟️"}</div>
                    <h1>{"iHoje Admin Login"}</h1>
                </div>

                // Show error message if there's any error
                if !(*error_message).is_empty() {
                    <div class="login-error">
                        <p>{&*error_message}</p>
                    </div>
                } else if let Some(auth_error) = &auth.state.error {
                    <div class="login-error">
                        <p>{format!("Error: {}", auth_error)}</p>
                    </div>
                }

                <div class="login-methods">
                    // Google OAuth login (primary method)
                    <div class="login-method google">
                        <h3>{"Sign in with OAuth"}</h3>
                        <button
                            onclick={handle_google_login}
                            class="login-button google-login"
                            disabled={*is_loading}>
                            <i class="fab fa-google"></i>
                            {" Sign in with Google"}
                        </button>
                    </div>

                    // Development login form only shown in debug builds
                    #[cfg(debug_assertions)]
                    {
                        html! {
                            <>
                                <div class="login-divider">
                                    <span>{"OR"}</span>
                                </div>

                                // Email/password login (for development/testing)
                                <div class="login-method email">
                                    <h3>{"Development/Test Login"}</h3>
                                    <div class="dev-notice">{"⚠️ For development use only"}</div>
                                    <form onsubmit={handle_form_submit}>
                                        <div class="form-group">
                                            <label for="email">{"Email"}</label>
                                            <input
                                                type="email"
                                                id="email"
                                                ref={email_ref}
                                                required=true
                                                placeholder="Enter your email"
                                                value="admin@test.com"
                                                disabled={*is_loading}
                                            />
                                        </div>

                                        <div class="form-group">
                                            <label for="password">{"Password"}</label>
                                            <input
                                                type="password"
                                                id="password"
                                                ref={password_ref}
                                                required=true
                                                placeholder="Enter your password"
                                                value="admin123"
                                                disabled={*is_loading}
                                            />
                                        </div>

                                        <button
                                            type="submit"
                                            class="login-button"
                                            disabled={*is_loading}>
                                            {"Login"}
                                        </button>
                                    </form>
                                </div>
                            </>
                        }
                    }
                </div>

                // Loading indicator
                if *is_loading || auth.state.loading {
                    <div class="login-loading">
                        <div class="spinner"></div>
                        <p>{"Processing login..."}</p>
                    </div>
                }

                <div class="login-footer">
                    <a href="/">{"Back to Main Site"}</a>
                    <p>{"By signing in, you agree to our Terms of Service and Privacy Policy"}</p>
                </div>
            </div>
        </div>
    }
}
