use yew::prelude::*;
use wasm_bindgen_futures::spawn_local;
use std::rc::Rc;
use log;

use crate::models::{User, AuthState};
use crate::api::{ApiResult, SupabaseAuth};

/// Auth context for managing authentication state
#[derive(Debug, Clone, PartialEq)]
pub struct AuthContext {
    /// Current auth state
    pub state: AuthState,
    
    /// Login function
    pub login: Callback<()>,
    
    /// Logout function
    pub logout: Callback<()>,
}

impl AuthContext {
    /// Create a new auth context with loading state
    pub fn new() -> Self {
        Self {
            state: AuthState::loading(),
            login: Callback::noop(),
            logout: Callback::noop(),
        }
    }
    
    /// Check if the user is authenticated
    pub fn is_authenticated(&self) -> bool {
        self.state.is_authenticated()
    }
    
    /// Check if the user is an admin
    pub fn is_admin(&self) -> bool {
        self.state.is_admin()
    }
    
    /// Get the current user
    pub fn user(&self) -> Option<&User> {
        self.state.user.as_ref()
    }
}

/// Auth context provider properties
#[derive(Properties, PartialEq)]
pub struct AuthProviderProps {
    #[prop_or_default]
    pub children: Children,
}

/// Auth context provider component
#[function_component(AuthProvider)]
pub fn auth_provider(props: &AuthProviderProps) -> Html {
    let auth_state = use_state(|| AuthState::loading());
    
    // Initialize Supabase Auth
    let supabase_auth = use_memo(
        |_| {
            match SupabaseAuth::new() {
                Ok(auth) => Some(auth),
                Err(e) => {
                    log::error!("Failed to initialize Supabase Auth: {:?}", e);
                    None
                }
            }
        },
        (),
    );
    
    // Check if the user is already logged in
    let auth_state_clone = auth_state.clone();
    use_effect_with_deps(
        move |_| {
            if let Some(auth) = supabase_auth.as_ref() {
                let auth_state = auth_state_clone.clone();
                
                spawn_local(async move {
                    match auth.get_current_session().await {
                        Ok(Some(user)) => {
                            log::info!("User already logged in: {}", user.email);
                            auth_state.set(AuthState::authenticated(user));
                        }
                        Ok(None) => {
                            log::info!("No user logged in");
                            auth_state.set(AuthState::new());
                        }
                        Err(e) => {
                            log::error!("Error checking auth state: {:?}", e);
                            auth_state.set(AuthState::error(e.to_string()));
                        }
                    }
                });
            } else {
                auth_state_clone.set(AuthState::error("Failed to initialize Supabase Auth"));
            }
            
            || ()
        },
        supabase_auth.clone(),
    );
    
    // Handle login
    let login = {
        let auth_state = auth_state.clone();
        let supabase_auth = supabase_auth.clone();
        
        Callback::from(move |_| {
            if let Some(auth) = supabase_auth.as_ref() {
                let auth_state = auth_state.clone();
                auth_state.set(AuthState::loading());
                
                spawn_local(async move {
                    match auth.sign_in_with_google().await {
                        Ok(user) => {
                            log::info!("User logged in: {}", user.email);
                            auth_state.set(AuthState::authenticated(user));
                        }
                        Err(e) => {
                            log::error!("Error logging in: {:?}", e);
                            auth_state.set(AuthState::error(e.to_string()));
                        }
                    }
                });
            }
        })
    };
    
    // Handle logout
    let logout = {
        let auth_state = auth_state.clone();
        let supabase_auth = supabase_auth.clone();
        
        Callback::from(move |_| {
            if let Some(auth) = supabase_auth.as_ref() {
                let auth_state = auth_state.clone();
                
                spawn_local(async move {
                    match auth.sign_out().await {
                        Ok(_) => {
                            log::info!("User logged out");
                            auth_state.set(AuthState::new());
                        }
                        Err(e) => {
                            log::error!("Error logging out: {:?}", e);
                            auth_state.set(AuthState::error(e.to_string()));
                        }
                    }
                });
            }
        })
    };
    
    // Create context value
    let context = AuthContext {
        state: (*auth_state).clone(),
        login,
        logout,
    };
    
    html! {
        <ContextProvider<Rc<AuthContext>> context={Rc::new(context)}>
            { for props.children.iter() }
        </ContextProvider<Rc<AuthContext>>>
    }
}

/// Hook to use the auth context
#[hook]
pub fn use_auth() -> Rc<AuthContext> {
    use_context::<Rc<AuthContext>>().expect("Auth context not found. Did you forget to wrap your component in AuthProvider?")
}

/// Component for requiring authentication
#[derive(Properties, PartialEq)]
pub struct RequireAuthProps {
    #[prop_or_default]
    pub children: Children,
    
    /// Component to render when not authenticated
    #[prop_or(html!{ <LoginRedirect /> })]
    pub fallback: Html,
}

/// Component that redirects to login
#[function_component(LoginRedirect)]
pub fn login_redirect() -> Html {
    let auth = use_auth();
    let history = use_history().unwrap();
    
    // Handle login click
    let handle_login = {
        let login = auth.login.clone();
        let current_path = history.location().pathname();
        
        Callback::from(move |_| {
            // Store current path in localStorage for redirect after login
            if current_path != "/" && current_path != "/login" {
                if let Ok(_) = gloo_storage::LocalStorage::set("ihoje_auth_redirect", &current_path) {
                    log::info!("Stored redirect path: {}", current_path);
                }
            }
            
            // Trigger login process
            login.emit(());
        })
    };
    
    html! {
        <div class="login-redirect">
            <h2>{"You need to log in to access this page"}</h2>
            <button onclick={handle_login} class="button-primary">
                {"Login with Google"}
            </button>
            {
                if auth.state.loading {
                    html! {
                        <div class="login-loading">
                            <div class="spinner"></div>
                            <p>{"Initiating login process..."}</p>
                        </div>
                    }
                } else if let Some(error) = &auth.state.error {
                    html! {
                        <div class="login-error">
                            <p>{format!("Error: {}", error)}</p>
                            <p>{"Please try again or contact support if the issue persists."}</p>
                        </div>
                    }
                } else {
                    html! {}
                }
            }
        </div>
    }
}

/// Component for requiring authentication
#[function_component(RequireAuth)]
pub fn require_auth(props: &RequireAuthProps) -> Html {
    let auth = use_auth();
    
    if auth.state.loading {
        return html! {
            <div class="loading-auth">
                <div class="spinner"></div>
                <p>{"Checking authentication..."}</p>
            </div>
        };
    }
    
    if auth.is_authenticated() {
        return html! { for props.children.iter() };
    }
    
    props.fallback.clone()
}

/// Component for requiring admin role
#[derive(Properties, PartialEq)]
pub struct RequireAdminProps {
    #[prop_or_default]
    pub children: Children,
    
    /// Component to render when not admin
    #[prop_or(html!{ <AdminAccessDenied /> })]
    pub fallback: Html,
}

/// Component shown when admin access is denied
#[function_component(AdminAccessDenied)]
pub fn admin_access_denied() -> Html {
    html! {
        <div class="access-denied">
            <h2>{"Access Denied"}</h2>
            <p>{"You don't have permission to access this area."}</p>
            <p>{"Please contact an administrator if you believe this is an error."}</p>
        </div>
    }
}

/// Component for requiring admin role
#[function_component(RequireAdmin)]
pub fn require_admin(props: &RequireAdminProps) -> Html {
    let auth = use_auth();
    
    if auth.state.loading {
        return html! {
            <div class="loading-auth">
                <div class="spinner"></div>
                <p>{"Checking permissions..."}</p>
            </div>
        };
    }
    
    if !auth.is_authenticated() {
        return html! { <LoginRedirect /> };
    }
    
    if auth.is_admin() {
        return html! { for props.children.iter() };
    }
    
    props.fallback.clone()
}