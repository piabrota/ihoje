use yew::prelude::*;
use yew_router::prelude::*;

use crate::api::{ApiClient, ApiError};
use crate::components::{LoadingIndicator, ErrorDisplay};
use crate::models::Event;
use crate::router::Route;
use crate::i18n::{use_i18n, Language, TranslationKey, I18n};
use crate::utils::use_api_query;

/// Properties for the event detail page
#[derive(Properties, PartialEq)]
pub struct EventDetailPageProps {
    /// Event ID to display
    pub id: String,
}

/// Page showing detailed information about a single event
#[function_component(EventDetailPage)]
pub fn event_detail_page(props: &EventDetailPageProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let navigator = use_navigator().unwrap();
    let client = use_memo(|_| ApiClient::new(), ());
    
    // Fetch event details
    let (event, is_loading, error) = {
        let client = client.clone();
        let id = props.id.clone();
        
        use_api_query(move || async move {
            client.fetch_event(&id).await
        })
    };
    
    // Navigation handler to go back to the events list
    let on_back = {
        let navigator = navigator.clone();
        Callback::from(move |_| {
            navigator.push(&Route::Home);
        })
    };
    
    // Retry handler for loading failures
    let on_retry = {
        // We simply force a re-render to retry the query
        let navigator = navigator.clone();
        let id = props.id.clone();
        
        Callback::from(move |_| {
            // Force a re-render by navigating to the same page
            navigator.push(&Route::EventDetail { id: id.clone() });
        })
    };
    
    // Render loading state
    if is_loading {
        return html! {
            <div class="event-detail-page">
                <LoadingIndicator />
            </div>
        };
    }
    
    // Render error state
    if let Some(err) = error {
        return html! {
            <div class="event-detail-page">
                <button class="back-button" onclick={on_back.clone()}>
                    {"← "}{i18n.t(|t| t.back_home.clone())}
                </button>
                <ErrorDisplay 
                    error={err} 
                    on_retry={Some(on_retry)}
                />
            </div>
        };
    }
    
    // Render event details if available
    match event {
        Some(event_data) => render_event_details(&*event_data, on_back, i18n),
        None => render_not_found(on_back, i18n),
    }
}

/// Helper function to render event details
fn render_event_details(event: &Event, on_back: Callback<MouseEvent>, i18n: I18n<Language, TranslationKey>) -> Html {
    let price_display = if event.is_free() {
        i18n.t(|t| t.free_event.clone())
    } else {
        event.price.clone()
    };
    
    let price_class = if event.is_free() { "price-free" } else { "price-paid" };
    
    html! {
        <div class="event-detail-page">
            <button class="back-button" onclick={on_back}>
                {"← "}{i18n.t(|t| t.back_home.clone())}
            </button>
            
            <div class="event-header">
                <h1 class="event-title">{&event.title}</h1>
                <div class={classes!("event-price", price_class)}>{price_display}</div>
            </div>
            
            <div class="event-detail-container">
                <div class="event-image-large">
                    <img src={event.image_url.clone()} alt={event.title.clone()} />
                </div>
                
                <div class="event-info">
                    <div class="info-item">
                        <span class="info-label">{i18n.t(|t| t.event_date.clone())}{":"}</span>
                        <span class="info-value">{&event.date}</span>
                    </div>
                    
                    <div class="info-item">
                        <span class="info-label">{i18n.t(|t| t.event_location.clone())}{":"}</span>
                        <span class="info-value">{&event.location}</span>
                    </div>
                    
                    <div class="info-item">
                        <span class="info-label">{i18n.t(|t| t.event_city.clone())}{":"}</span>
                        <span class="info-value">{&event.city}</span>
                    </div>
                    
                    <a href={event.url.clone()} class="event-link" target="_blank" rel="noopener noreferrer">
                        {i18n.t(|t| t.event_url.clone())}
                    </a>
                </div>
            </div>
        </div>
    }
}

/// Helper function to render not found state
fn render_not_found(on_back: Callback<MouseEvent>, i18n: I18n<Language, TranslationKey>) -> Html {
    html! {
        <div class="event-detail-page">
            <button class="back-button" onclick={on_back}>
                {"← "}{i18n.t(|t| t.back_home.clone())}
            </button>
            <div class="not-found">
                <h2>{i18n.t(|t| t.not_found.clone())}</h2>
                <p>{i18n.t(|t| t.no_events_found.clone())}</p>
            </div>
        </div>
    }
}