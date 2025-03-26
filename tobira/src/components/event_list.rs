use super::event_card::EventCard;
use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::models::{Event, EventQuery};
use yew::prelude::*;

#[derive(Properties, PartialEq)]
pub struct EventListProps {
    pub events: Vec<Event>,
    pub filter: EventQuery,
    pub on_select_event: Callback<String>,
    #[prop_or(false)]
    pub is_loading: bool,
}

#[function_component(EventList)]
pub fn event_list(props: &EventListProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();

    let filtered_events = props
        .events
        .iter()
        .filter(|event| {
            // Manual filtering based on EventQuery
            // City filter
            if let Some(city) = &props.filter.city {
                if !city.is_empty() && event.city != *city {
                    return false;
                }
            }

            // Search filter
            if let Some(search) = &props.filter.search {
                if !search.is_empty()
                    && !event.title.to_lowercase().contains(&search.to_lowercase())
                {
                    return false;
                }
            }

            // Free only filter
            if let Some(true) = props.filter.free_only {
                if !event.is_free() {
                    return false;
                }
            }

            true
        })
        .collect::<Vec<_>>();

    let events_count = filtered_events.len();

    if props.is_loading {
        return html! {
            <div class="events-loading">
                <p>{i18n.t(|t| &t.loading)}</p>
            </div>
        };
    }

    if events_count == 0 {
        return html! {
            <div class="events-empty">
                <p>{i18n.t(|t| &t.no_events_found)}</p>
            </div>
        };
    }

    html! {
        <div class="events-container">
            <div class="events-count">
                {
                    if events_count == 1 {
                        format!("1 {}", i18n.t(|t| &t.events_title))
                    } else {
                        format!("{} {}", events_count, i18n.t(|t| &t.events_title))
                    }
                }
            </div>
            <div class="events-grid">
                { filtered_events.iter().map(|event| {
                    html! {
                        <EventCard
                            event={(*event).clone()}
                            on_select={props.on_select_event.clone()}
                        />
                    }
                }).collect::<Html>() }
            </div>
        </div>
    }
}
