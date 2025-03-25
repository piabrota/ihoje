use yew::prelude::*;
use yew_router::prelude::*;
use web_sys::window;

use crate::router::{Route, switch};
use crate::i18n::{use_i18n, LanguageToggle, Language, TranslationKey};
use crate::components::{AuthProvider, use_auth};

/// User profile component in header
#[function_component(UserProfileSection)]
fn user_profile_section() -> Html {
    let auth = use_auth();
    let i18n = use_i18n::<Language, TranslationKey>();
    
    if auth.state.loading {
        return html! {
            <div class="user-profile loading">
                <div class="profile-loading-indicator"></div>
            </div>
        };
    }
    
    if let Some(user) = &auth.state.user {
        // User is logged in
        html! {
            <div class="user-profile logged-in">
                <div class="profile-details">
                    <span class="user-name">{user.display_name()}</span>
                    {
                        if let Some(avatar_url) = &user.avatar_url {
                            html! { <img class="user-avatar" src={avatar_url.clone()} alt="Profile" /> }
                        } else {
                            html! { <div class="user-avatar-placeholder">{user.display_name().chars().next().unwrap_or('U')}</div> }
                        }
                    }
                </div>
                <div class="profile-dropdown">
                    {
                        if user.is_admin() {
                            html! {
                                <Link<Route> to={Route::Admin} classes="dropdown-item">
                                    <i class="fas fa-cog"></i>{" Admin Dashboard"}
                                </Link<Route>>
                            }
                        } else {
                            html! {}
                        }
                    }
                    <button 
                        class="dropdown-item logout-button" 
                        onclick={auth.logout.reform(|_| ())}>
                        <i class="fas fa-sign-out-alt"></i>{" Logout"}
                    </button>
                </div>
            </div>
        }
    } else {
        // User is not logged in
        html! {
            <div class="user-profile logged-out">
                <Link<Route> to={Route::Login} classes="login-button">
                    <i class="fas fa-sign-in-alt"></i>{" "}{i18n.t(|t| &t.login)}
                </Link<Route>>
            </div>
        }
    }
}

/// Main layout component
#[function_component(MainLayout)]
pub fn main_layout(props: &ChildrenProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let auth = use_auth();
    
    html! {
        <div class="app-container">
            <header class="app-header">
                <div class="logo">
                    <span class="logo-mark">{"🎟️"}</span>
                    <Link<Route> to={Route::Home}>{i18n.t(|t| &t.app_name)}</Link<Route>>
                </div>
                <nav class="app-nav">
                    <Link<Route> to={Route::Home} classes="nav-link">
                        <i class="fas fa-home"></i>{" "}{i18n.t(|t| &t.home)}
                    </Link<Route>>
                    {
                        // Only show Admin link in nav for admin users
                        if auth.is_admin() {
                            html! {
                                <Link<Route> to={Route::Admin} classes="nav-link">
                                    <i class="fas fa-cog"></i>{" Admin"}
                                </Link<Route>>
                            }
                        } else {
                            html! {}
                        }
                    }
                    <LanguageToggle />
                    <UserProfileSection />
                </nav>
            </header>
            
            <main class="app-content">
                { for props.children.iter() }
            </main>
            
            <footer class="app-footer">
                <div class="footer-content">
                    <div class="footer-section">
                        <h3>{i18n.t(|t| &t.app_name)}</h3>
                        <p>{i18n.t(|t| &t.app_description)}</p>
                    </div>
                    <div class="footer-section">
                        <h3>{i18n.t(|t| &t.footer_links)}</h3>
                        <Link<Route> to={Route::Home}>{i18n.t(|t| &t.home)}</Link<Route>>
                    </div>
                </div>
                <div class="footer-copyright">
                    {i18n.t(|t| &t.copyright)}
                </div>
            </footer>
        </div>
    }
}

/// Main application component
#[function_component(App)]
pub fn app() -> Html {
    // Effect hook to ensure we handle SPA navigation correctly
    use_effect_with_deps(
        |_| {
            let path = window()
                .and_then(|w| w.location().pathname().ok())
                .unwrap_or_else(|| "/".to_string());
                
            // Check if the path needs special handling
            let known_paths = [
                "/", 
                "/login", 
                "/auth/callback", 
                "/admin", 
                "/admin/events", 
                "/admin/event/new",
                "/maintenance",
                "/error"
            ];
            
            let is_event_detail = path.starts_with("/event/");
            let is_admin_edit = path.starts_with("/admin/event/") && path.ends_with("/edit");
            
            // If the path doesn't match known routes, navigate to home
            if !is_event_detail && !is_admin_edit && !known_paths.contains(&path.as_str()) {
                log::info!("Redirecting unknown path to home: {}", path);
                
                // Use history API to navigate to home
                if let Some(window) = window() {
                    // Force a reload of the page
                    let _ = window
                        .document()
                        .and_then(|doc| doc.location())
                        .and_then(|loc| loc.replace("/").ok());
                }
            }
            
            || ()
        },
        (),
    );
    
    // Initialize Supabase Auth
    use_effect_with_deps(
        |_| {
            // Inject the Supabase client script
            if let Err(e) = crate::api::SupabaseAuth::inject_supabase_script() {
                log::error!("Failed to inject Supabase client script: {:?}", e);
            }
            
            || ()
        },
        (),
    );
    
    // Check server status on startup, unless we're already on maintenance or error pages
    use_effect_with_deps(
        |_| {
            // Skip health check if we're already on a system page
            let path = window()
                .and_then(|w| w.location().pathname().ok())
                .unwrap_or_else(|| "/".to_string());
                
            if path != "/maintenance" && path != "/error" {
                // Create API client and check server status
                let api_client = crate::api::ApiClient::new();
                
                wasm_bindgen_futures::spawn_local(async move {
                    // Check server health status
                    let _ = api_client.check_server_status().await;
                    // Navigating to error/maintenance pages is handled inside the method if needed
                });
            }
            
            || ()
        },
        (),
    );

    html! {
        <BrowserRouter>
            <AuthProvider>
                <MainLayout>
                    <Switch<Route> render={switch} />
                </MainLayout>
            </AuthProvider>
        </BrowserRouter>
    }
}