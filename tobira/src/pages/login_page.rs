use yew::prelude::*;
use yew_router::prelude::*;
use log;

use crate::components::use_auth;
use crate::router::Route;

/// Login page component
#[function_component(LoginPage)]
pub fn login_page() -> Html {
    let auth = use_auth();
    let navigator = use_navigator().unwrap();
    
    // If already logged in, redirect to home
    let already_authed = auth.is_authenticated();
    let navigator_clone = navigator.clone();
    
    use_effect_with_deps(
        move |_| {
            if already_authed {
                log::info!("User already authenticated, redirecting to home");
                navigator_clone.push(&Route::Home);
            }
            || ()
        },
        already_authed,
    );
    
    // Handle login click
    let handle_login = {
        let login = auth.login.clone();
        let navigator = navigator.clone();
        
        Callback::from(move |_| {
            login.emit(());
            
            // Navigation will happen after login completes in the auth context
            // We don't redirect here because the Google OAuth flow will handle redirects
        })
    };
    
    html! {
        <div class="login-page">
            <div class="login-container">
                <h1>{"Login to iHoje"}</h1>
                <p>{"Sign in to access your account and manage events"}</p>
                
                <div class="login-buttons">
                    <button 
                        onclick={handle_login}
                        class="login-button google-login">
                        <i class="fab fa-google"></i>
                        {" Sign in with Google"}
                    </button>
                </div>
                
                {
                    if let Some(error) = &auth.state.error {
                        html! {
                            <div class="login-error">
                                <p>{format!("Error: {}", error)}</p>
                            </div>
                        }
                    } else {
                        html! {}
                    }
                }
                
                <div class="login-footer">
                    <p>{"By signing in, you agree to our Terms of Service and Privacy Policy"}</p>
                </div>
            </div>
        </div>
    }
}