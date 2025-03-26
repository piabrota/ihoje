use std::rc::Rc;
use yew::prelude::*;
use yew::suspense::use_future;

use super::geolocation::{request_user_location, UserLocation};
use crate::api::{ApiError, ApiResult};

/// Hook for fetching data with loading and error states
pub fn use_api_query<T, F, Fut>(fetch_fn: F) -> (Option<Rc<T>>, bool, Option<ApiError>)
where
    T: 'static,
    F: FnOnce() -> Fut + 'static,
    Fut: std::future::Future<Output = ApiResult<T>> + 'static,
{
    // State for data, loading, and error
    let data = use_state(|| None::<Rc<T>>);
    let is_loading = use_state(|| true);
    let error = use_state(|| None::<ApiError>);

    {
        let data = data.clone();
        let is_loading = is_loading.clone();
        let error = error.clone();

        use_effect_with_deps(
            move |_| {
                let future = async move {
                    match fetch_fn().await {
                        Ok(result) => {
                            data.set(Some(Rc::new(result)));
                            error.set(None);
                        }
                        Err(err) => {
                            error.set(Some(err));
                        }
                    }
                    is_loading.set(false);
                };

                wasm_bindgen_futures::spawn_local(future);

                || ()
            },
            (),
        );
    }

    let data_value = (*data).clone();
    let is_loading_value = *is_loading;
    let error_value = (*error).clone();

    (data_value, is_loading_value, error_value)
}

/// Hook for executing mutations with loading and error states
pub fn use_api_mutation<T, P, F, Fut>() -> (
    Callback<P, Fut>,
    UseStateHandle<Option<Rc<T>>>,
    UseStateHandle<bool>,
    UseStateHandle<Option<ApiError>>,
)
where
    T: 'static,
    P: 'static,
    F: Fn(P) -> Fut + 'static,
    Fut: std::future::Future<Output = ApiResult<T>> + 'static,
{
    // State for data, loading, and error
    let data = use_state(|| None::<Rc<T>>);
    let is_loading = use_state(|| false);
    let error = use_state(|| None::<ApiError>);

    // Create the mutation callback
    let mutate = {
        let data = data.clone();
        let is_loading = is_loading.clone();
        let error = error.clone();

        Callback::from(move |params: P| {
            let data = data.clone();
            let is_loading = is_loading.clone();
            let error = error.clone();

            is_loading.set(true);
            error.set(None);

            let future = async move {
                // TODO: Implementation needs fixing, Fut::await is invalid
                // For now, let's create a placeholder implementation
                // that will need to be updated with actual functionality
                let result = Err(ApiError::NetworkError(
                    "Mutation temporarily disabled".to_string(),
                ));

                match result {
                    Ok(value) => {
                        data.set(Some(Rc::new(value)));
                        error.set(None);
                    }
                    Err(err) => {
                        error.set(Some(err));
                    }
                }

                is_loading.set(false);
            };

            wasm_bindgen_futures::spawn_local(future);

            // Return a placeholder future
            async {
                Err(ApiError::NetworkError(
                    "Mutation temporarily disabled".to_string(),
                ))
            }
        })
    };

    (mutate, data, is_loading, error)
}

/// Hook for tracking window resize events
pub fn use_window_size() -> (i32, i32) {
    let width = use_state(|| window_inner_width());
    let height = use_state(|| window_inner_height());

    {
        let width = width.clone();
        let height = height.clone();

        use_effect_with_deps(
            move |_| {
                // Create resize event listener
                let listener = Closure::wrap(Box::new(move || {
                    width.set(window_inner_width());
                    height.set(window_inner_height());
                }) as Box<dyn Fn()>);

                // Add event listener
                web_sys::window()
                    .unwrap()
                    .add_event_listener_with_callback("resize", listener.as_ref().unchecked_ref())
                    .unwrap();

                // Return cleanup function
                move || {
                    web_sys::window()
                        .unwrap()
                        .remove_event_listener_with_callback(
                            "resize",
                            listener.as_ref().unchecked_ref(),
                        )
                        .unwrap();
                }
            },
            (),
        );
    }

    let width_value = *width;
    let height_value = *height;

    (width_value, height_value)
}

// Helper function to get window inner width
fn window_inner_width() -> i32 {
    web_sys::window()
        .map(|window| window.inner_width().ok())
        .flatten()
        .map(|width| width.as_f64())
        .flatten()
        .map(|width| width as i32)
        .unwrap_or(0)
}

// Helper function to get window inner height
fn window_inner_height() -> i32 {
    web_sys::window()
        .map(|window| window.inner_height().ok())
        .flatten()
        .map(|height| height.as_f64())
        .flatten()
        .map(|height| height as i32)
        .unwrap_or(0)
}

/// Hook for getting user's location
pub fn use_user_location() -> (Option<UserLocation>, bool, Option<String>) {
    // State for location, loading, and error
    let location = use_state(|| None::<UserLocation>);
    let is_loading = use_state(|| true);
    let error = use_state(|| None::<String>);

    {
        let location = location.clone();
        let is_loading = is_loading.clone();
        let error = error.clone();

        use_effect_with_deps(
            move |_| {
                wasm_bindgen_futures::spawn_local(async move {
                    match request_user_location().await {
                        Ok(user_location) => {
                            location.set(Some(user_location));
                            error.set(None);
                        }
                        Err(err) => {
                            error.set(Some(err));
                        }
                    }
                    is_loading.set(false);
                });

                || ()
            },
            (),
        );
    }

    let location_value = (*location).clone();
    let is_loading_value = *is_loading;
    let error_value = (*error).clone();

    (location_value, is_loading_value, error_value)
}
