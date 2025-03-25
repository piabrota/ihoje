use yew::prelude::*;
use yew_router::prelude::*;
use web_sys::{HtmlInputElement, HtmlSelectElement, HtmlTextAreaElement};
use gloo::console::log;
use wasm_bindgen_futures;
use wasm_bindgen::JsCast;

use crate::api::{ApiClient, ApiError};
use crate::models::Event;
use crate::components::{LoadingIndicator, ErrorDisplay};
use crate::router::Route;
use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::utils::use_api_query;

/// Properties for the event form
#[derive(Properties, PartialEq)]
pub struct EventFormProps {
    /// Event ID for editing (None for new events)
    #[prop_or_default]
    pub event_id: Option<String>,
}

/// Event form state
#[derive(Clone, Debug, Default, PartialEq)]
struct EventFormData {
    title: String,
    date: String,
    location: String,
    url: String,
    image_url: String,
    city: String,
    price: String,
}

impl From<Event> for EventFormData {
    fn from(event: Event) -> Self {
        Self {
            title: event.title,
            date: event.date,
            location: event.location,
            url: event.url,
            image_url: event.image_url,
            city: event.city,
            price: event.price,
        }
    }
}

/// Admin component for adding new events
#[function_component(AdminNewEvent)]
pub fn admin_new_event() -> Html {
    html! {
        <EventForm />
    }
}

/// Admin component for editing events
#[function_component(AdminEditEvent)]
pub fn admin_edit_event() -> Html {
    let route = use_route::<Route>().unwrap();
    
    // Extract event ID from route
    let event_id = match route {
        Route::AdminEditEvent { id } => Some(id),
        _ => None,
    };
    
    html! {
        <EventForm event_id={event_id} />
    }
}

/// Shared event form component for creating and editing events
#[function_component(EventForm)]
fn event_form(props: &EventFormProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let navigator = use_navigator().unwrap();
    let client = use_memo(|_| ApiClient::new(), ());
    
    // Form state
    let form_data = use_state(EventFormData::default);
    
    // Validation state
    let validation_errors = use_state(|| Vec::<String>::new());
    
    // Submission state
    let is_submitting = use_state(|| false);
    let submit_error = use_state(|| None::<String>);
    
    // If editing, fetch the event data
    let (event, is_loading, fetch_error) = if let Some(id) = &props.event_id {
        let client = client.clone();
        let id = id.clone();
        
        let (event, is_loading, error) = use_api_query(move || {
            let client = client.clone();
            let id = id.clone();
            async move { client.fetch_event(&id).await }
        });
        
        // When event data is loaded, update form data
        {
            let form_data = form_data.clone();
            let event = event.clone();
            
            use_effect_with_deps(
                move |event| {
                    if let Some(event_data) = event {
                        form_data.set(EventFormData::from((**event_data).clone()));
                    }
                    || ()
                },
                event.clone(),
            );
        }
        
        (event, is_loading, error)
    } else {
        (None, false, None)
    };
    
    // Handle form input changes
    let handle_input_change = {
        let form_data = form_data.clone();
        
        Callback::from(move |e: Event| {
            let target = e.target().unwrap();
            let field_name = target.unchecked_ref::<HtmlInputElement>().name();
            let value = target.unchecked_ref::<HtmlInputElement>().value();
            
            let mut updated_data = (*form_data).clone();
            
            match field_name.as_str() {
                "title" => updated_data.title = value,
                "date" => updated_data.date = value,
                "location" => updated_data.location = value,
                "url" => updated_data.url = value,
                "image_url" => updated_data.image_url = value,
                "price" => updated_data.price = value,
                _ => {}
            }
            
            form_data.set(updated_data);
        })
    };
    
    // Handle select input changes
    let handle_select_change = {
        let form_data = form_data.clone();
        
        Callback::from(move |e: Event| {
            let target = e.target().unwrap();
            let select = target.dyn_into::<HtmlSelectElement>().unwrap();
            let value = select.value();
            
            let mut updated_data = (*form_data).clone();
            updated_data.city = value;
            form_data.set(updated_data);
        })
    };
    
    // Handle form submission
    let handle_submit = {
        let form_data = form_data.clone();
        let validation_errors = validation_errors.clone();
        let is_submitting = is_submitting.clone();
        let submit_error = submit_error.clone();
        let client = client.clone();
        let event_id = props.event_id.clone();
        let navigator = navigator.clone();
        
        Callback::from(move |e: SubmitEvent| {
            e.prevent_default();
            
            // Reset error states
            validation_errors.set(Vec::new());
            submit_error.set(None);
            
            // Validate form
            let mut errors = Vec::new();
            let data = (*form_data).clone();
            
            if data.title.is_empty() {
                errors.push("Title is required".to_string());
            }
            
            if data.date.is_empty() {
                errors.push("Date is required".to_string());
            }
            
            if data.location.is_empty() {
                errors.push("Location is required".to_string());
            }
            
            if data.city.is_empty() {
                errors.push("City is required".to_string());
            }
            
            if !errors.is_empty() {
                validation_errors.set(errors);
                return;
            }
            
            // Set submitting state
            is_submitting.set(true);
            
            // Prepare data for submission
            let mut event = Event {
                id: event_id.clone().unwrap_or_else(|| "".to_string()),
                title: data.title.clone(),
                date: data.date.clone(),
                location: data.location.clone(),
                url: data.url.clone(),
                image_url: data.image_url.clone(),
                city: data.city.clone(),
                price: data.price.clone(),
            };
            
            // Submit data
            let client = client.clone();
            let navigator = navigator.clone();
            let is_submitting = is_submitting.clone();
            let submit_error = submit_error.clone();
            
            wasm_bindgen_futures::spawn_local(async move {
                let result = if let Some(_) = event_id {
                    // Update existing event
                    client.update_event(&event).await
                } else {
                    // Create new event
                    client.create_event(&event).await
                };
                
                // Handle result
                match result {
                    Ok(created_event) => {
                        log!("Event saved successfully");
                        // Navigate back to admin events
                        navigator.push(&Route::AdminEvents);
                    }
                    Err(err) => {
                        log!("Error saving event:", err.to_string());
                        submit_error.set(Some(err.to_string()));
                    }
                }
                
                is_submitting.set(false);
            });
        })
    };
    
    // Handle cancel button
    let handle_cancel = {
        let navigator = navigator.clone();
        Callback::from(move |_| {
            navigator.push(&Route::AdminEvents);
        })
    };
    
    // Display loading state if fetching event data
    if is_loading {
        return html! {
            <div class="admin-event-form-container">
                <h1 class="admin-title">{"Loading Event Data"}</h1>
                <LoadingIndicator />
            </div>
        };
    }
    
    // Display error if fetch failed
    if let Some(error) = fetch_error {
        return html! {
            <div class="admin-event-form-container">
                <h1 class="admin-title">{"Error Loading Event"}</h1>
                <ErrorDisplay error={error} />
                <div class="form-actions">
                    <button type="button" class="admin-button secondary" onclick={handle_cancel}>
                        {"Back to Events"}
                    </button>
                </div>
            </div>
        };
    }
    
    // Determine if we're editing or creating
    let is_editing = props.event_id.is_some();
    let title = if is_editing { "Edit Event" } else { "Add New Event" };
    
    html! {
        <div class="admin-event-form-container">
            <h1 class="admin-title">{title}</h1>
            
            // Display validation errors
            if !(*validation_errors).is_empty() {
                <div class="validation-errors">
                    <h3>{"Please fix the following errors:"}</h3>
                    <ul>
                        { for validation_errors.iter().map(|error| html! { <li>{error}</li> }) }
                    </ul>
                </div>
            }
            
            // Display submission error
            if let Some(error) = (*submit_error).clone() {
                <div class="submit-error">
                    <p>{format!("Error: {}", error)}</p>
                </div>
            }
            
            <form class="admin-form" onsubmit={handle_submit}>
                <div class="form-group">
                    <label for="title">{"Event Title:"}</label>
                    <input 
                        type="text"
                        id="title"
                        name="title"
                        value={form_data.title.clone()}
                        onchange={handle_input_change.clone()}
                        required=true
                    />
                </div>
                
                <div class="form-group">
                    <label for="date">{"Event Date:"}</label>
                    <input 
                        type="date"
                        id="date"
                        name="date"
                        value={form_data.date.clone()}
                        onchange={handle_input_change.clone()}
                        required=true
                    />
                </div>
                
                <div class="form-group">
                    <label for="location">{"Location:"}</label>
                    <input 
                        type="text"
                        id="location"
                        name="location"
                        value={form_data.location.clone()}
                        onchange={handle_input_change.clone()}
                        required=true
                    />
                </div>
                
                <div class="form-group">
                    <label for="city">{"City:"}</label>
                    <select 
                        id="city"
                        name="city"
                        value={form_data.city.clone()}
                        onchange={handle_select_change}
                        required=true
                    >
                        <option value="">{"-- Select City --"}</option>
                        <option value="FL">{"Florianópolis"}</option>
                        <option value="SP">{"São Paulo"}</option>
                        <option value="RJ">{"Rio de Janeiro"}</option>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="price">{"Price:"}</label>
                    <input 
                        type="text"
                        id="price"
                        name="price"
                        value={form_data.price.clone()}
                        onchange={handle_input_change.clone()}
                        placeholder="R$ 0,00 (Gratuito) or R$ XX,XX"
                    />
                </div>
                
                <div class="form-group">
                    <label for="url">{"Event URL:"}</label>
                    <input 
                        type="url"
                        id="url"
                        name="url"
                        value={form_data.url.clone()}
                        onchange={handle_input_change.clone()}
                        placeholder="https://example.com/event"
                    />
                </div>
                
                <div class="form-group">
                    <label for="image_url">{"Image URL:"}</label>
                    <input 
                        type="url"
                        id="image_url"
                        name="image_url"
                        value={form_data.image_url.clone()}
                        onchange={handle_input_change.clone()}
                        placeholder="https://example.com/image.jpg"
                    />
                </div>
                
                <div class="form-actions">
                    <button type="button" class="admin-button secondary" onclick={handle_cancel}>
                        {"Cancel"}
                    </button>
                    <button 
                        type="submit" 
                        class="admin-button primary"
                        disabled={*is_submitting}
                    >
                        if *is_submitting {
                            {"Saving..."}
                        } else if is_editing {
                            {"Update Event"}
                        } else {
                            {"Create Event"}
                        }
                    </button>
                </div>
            </form>
        </div>
    }
}