use yew::prelude::*;
use crate::models::Event;
use crate::i18n::{use_i18n, Language, TranslationKey};
use super::view::EventCardView;

/// Properties for the EventCard component
#[derive(Properties, PartialEq)]
pub struct EventCardProps {
    /// The event data to display
    pub event: Event,
    
    /// Callback when the event card is selected (emits event ID)
    pub on_select: Callback<String>,
    
    /// Optional additional classes
    #[prop_or_default]
    pub class: Classes,
}

/// Logic component for an event card that connects to data
#[function_component(EventCard)]
pub fn event_card(props: &EventCardProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let event = &props.event;
    
    // Create click handler
    let on_click = {
        let id = event.id.clone();
        let on_select = props.on_select.clone();
        Callback::from(move |_| {
            on_select.emit(id.clone());
        })
    };
    
    // Determine price display text
    let price_display = if event.is_free() {
        i18n.t(|t| &t.free_event).to_string()
    } else {
        event.price.clone()
    };
    
    html! {
        <EventCardView
            title={event.title.clone()}
            date={event.formatted_date()}
            location={event.location.clone()}
            price={price_display}
            image_url={event.image_url.clone()}
            is_free={event.is_free()}
            on_click={on_click}
            class={props.class.clone()}
        />
    }
}