use yew::prelude::*;
use crate::models::Event;
use crate::i18n::{use_i18n, Language, TranslationKey};

#[derive(Properties, PartialEq)]
pub struct EventCardProps {
    pub event: Event,
    pub on_select: Callback<String>,
}

#[function_component(EventCard)]
pub fn event_card(props: &EventCardProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let event = &props.event;
    
    let on_click = {
        let id = event.id.clone();
        let on_select = props.on_select.clone();
        Callback::from(move |_| {
            on_select.emit(id.clone());
        })
    };
    
    let price_class = if event.is_free() { "price-free" } else { "price-paid" };
    let price_display = if event.is_free() {
        i18n.t(|t| &t.free_event).to_string()
    } else {
        event.price.clone()
    };
    
    html! {
        <div class="event-card" onclick={on_click}>
            <div class="event-image">
                <img src={event.image_url.clone()} alt={event.title.clone()} />
            </div>
            <div class="event-content">
                <h3 class="event-title">{&event.title}</h3>
                <div class="event-details">
                    <div class="event-date">
                        <span class="label">{i18n.t(|t| &t.event_date)}{":"}</span>
                        <span class="value">{&event.formatted_date()}</span>
                    </div>
                    <div class="event-location">
                        <span class="label">{i18n.t(|t| &t.event_location)}{":"}</span>
                        <span class="value">{&event.location}</span>
                    </div>
                    <div class={classes!("event-price", price_class)}>
                        <span class="label">{i18n.t(|t| &t.event_price)}{":"}</span>
                        <span class="value">{price_display}</span>
                    </div>
                </div>
            </div>
        </div>
    }
}