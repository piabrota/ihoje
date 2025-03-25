use yew::prelude::*;
use crate::i18n::{use_i18n, Language, TranslationKey};

/// Properties for displaying an event card view
#[derive(Properties, PartialEq)]
pub struct EventCardViewProps {
    /// Event title
    pub title: String,
    
    /// Event date (formatted)
    pub date: String,
    
    /// Event location
    pub location: String,
    
    /// Event price display string
    pub price: String,
    
    /// Event image URL
    pub image_url: String,
    
    /// Whether this is a free event
    pub is_free: bool,
    
    /// Click callback
    pub on_click: Callback<MouseEvent>,
    
    /// Optional additional classes
    #[prop_or_default]
    pub class: Classes,
}

/// Pure presentational component for an event card
#[function_component(EventCardView)]
pub fn event_card_view(props: &EventCardViewProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    
    // Determine price class based on whether it's free
    let price_class = if props.is_free { "price-free" } else { "price-paid" };
    
    // Combine classes
    let card_classes = classes!(
        "event-card",
        props.class.clone()
    );
    
    html! {
        <div class={card_classes} onclick={props.on_click.clone()}>
            <div class="event-image">
                <img src={props.image_url.clone()} alt={props.title.clone()} />
            </div>
            <div class="event-content">
                <h3 class="event-title">{&props.title}</h3>
                <div class="event-details">
                    <div class="event-date">
                        <span class="label">{i18n.t(|t| &t.event_date)}{":"}</span>
                        <span class="value">{&props.date}</span>
                    </div>
                    <div class="event-location">
                        <span class="label">{i18n.t(|t| &t.event_location)}{":"}</span>
                        <span class="value">{&props.location}</span>
                    </div>
                    <div class={classes!("event-price", price_class)}>
                        <span class="label">{i18n.t(|t| &t.event_price)}{":"}</span>
                        <span class="value">{&props.price}</span>
                    </div>
                </div>
            </div>
        </div>
    }
}