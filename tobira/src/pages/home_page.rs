use std::rc::Rc;
use yew::prelude::*;
use yew_router::prelude::*;
use gloo::console::log;

use crate::api::{ApiClient, ApiError};
use crate::components::{EventList, FilterBar, LoadingIndicator, ErrorDisplay};
use crate::models::{Event, EventQuery};
use crate::router::Route;
use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::utils::{use_api_query, use_api_mutation};

/// Home page displaying event listings with filtering
#[function_component(HomePage)]
pub fn home_page() -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let filter = use_state(|| EventQuery::default());
    let navigator = use_navigator().unwrap();
    let client = use_memo(|_| ApiClient::new(), ());
    
    // Fetch events with our custom hook
    let fetch_events = {
        let client = client.clone();
        let filter = filter.clone();
        
        move || {
            let client = client.clone();
            let query = (*filter).clone();
            
            async move {
                client.fetch_events(query).await
            }
        }
    };
    
    let (events, events_loading, events_error) = {
        let fetch_fn = fetch_events();
        use_api_query(move || fetch_fn)
    };
    
    // Fetch cities with our custom hook
    let (cities, cities_loading, cities_error) = {
        let client = client.clone();
        
        use_api_query(move || async move {
            client.fetch_cities().await
        })
    };
    
    // Filter change handler
    let on_filter_change = {
        let filter = filter.clone();
        Callback::from(move |new_filter: EventQuery| {
            filter.set(new_filter);
        })
    };
    
    // Event selection handler
    let on_select_event = {
        let navigator = navigator.clone();
        Callback::from(move |id: String| {
            navigator.push(&Route::EventDetail { id });
        })
    };
    
    // Retry handler for events loading
    let on_retry_events = {
        let filter = filter.clone();
        Callback::from(move |_| {
            // Simply trigger a re-render with the same filter to retry
            filter.set((*filter).clone());
        })
    };
    
    // Determine if we're loading anything
    let is_loading = events_loading || cities_loading;
    
    // Combined cities with error fallback
    let available_cities = match cities {
        Some(cities_data) => cities_data.to_vec(),
        None => Vec::new(),
    };
    
    // Render the UI
    html! {
        <div class="home-page">
            <section class="welcome-section">
                <h1 class="page-title">{i18n.t(|t| &t.welcome_title)}</h1>
                <p class="welcome-message">{i18n.t(|t| &t.welcome_message)}</p>
            </section>
            
            <section class="events-section">
                <h2 class="section-title">{i18n.t(|t| &t.events_title)}</h2>
                
                <FilterBar 
                    filter={(*filter).clone()} 
                    on_filter_change={on_filter_change}
                    available_cities={available_cities}
                />
                
                {
                    if let Some(error) = events_error {
                        html! {
                            <ErrorDisplay 
                                error={error} 
                                on_retry={Some(on_retry_events)}
                                class="events-error"
                            />
                        }
                    } else {
                        html! {
                            <EventList 
                                events={events.map(|e| e.to_vec()).unwrap_or_default()}
                                filter={(*filter).clone()}
                                on_select_event={on_select_event}
                                is_loading={is_loading}
                            />
                        }
                    }
                }
            </section>
        </div>
    }
}