use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::models::EventQuery;
use crate::utils::use_user_location;
use web_sys::HtmlInputElement;
use yew::prelude::*;

#[derive(Properties, PartialEq)]
pub struct FilterBarProps {
    pub filter: EventQuery,
    pub on_filter_change: Callback<EventQuery>,
    pub available_cities: Vec<String>,
}

#[function_component(FilterBar)]
pub fn filter_bar(props: &FilterBarProps) -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let current_filter = use_state(|| props.filter.clone());

    // Get user location for location-based filtering
    let (location, is_location_loading, _) = use_user_location();

    // Set city based on location if no city is selected
    {
        let current_filter = current_filter.clone();
        let on_filter_change = props.on_filter_change.clone();

        use_effect_with_deps(
            move |(location, is_loading)| {
                if !is_loading && current_filter.city.is_none() {
                    if let Some(loc) = location {
                        if let Some(city_code) = &loc.city_code {
                            // Update filter with inferred city
                            let mut new_filter = (*current_filter).clone();
                            new_filter.city = Some(city_code.clone());
                            current_filter.set(new_filter.clone());
                            on_filter_change.emit(new_filter);
                        }
                    }
                }
                || ()
            },
            (location, is_location_loading),
        );
    }

    let on_search_change = {
        let current_filter = current_filter.clone();
        let on_filter_change = props.on_filter_change.clone();

        Callback::from(move |e: Event| {
            let input: HtmlInputElement = e.target_unchecked_into();
            let search_term = input.value();

            let mut new_filter = (*current_filter).clone();
            new_filter.search = if search_term.is_empty() {
                None
            } else {
                Some(search_term)
            };

            current_filter.set(new_filter.clone());
            on_filter_change.emit(new_filter);
        })
    };

    let on_city_change = {
        let current_filter = current_filter.clone();
        let on_filter_change = props.on_filter_change.clone();

        Callback::from(move |e: Event| {
            let select: HtmlInputElement = e.target_unchecked_into();
            let city = select.value();

            let mut new_filter = (*current_filter).clone();
            new_filter.city = if city.is_empty() { None } else { Some(city) };

            current_filter.set(new_filter.clone());
            on_filter_change.emit(new_filter);
        })
    };

    let on_free_only_change = {
        let current_filter = current_filter.clone();
        let on_filter_change = props.on_filter_change.clone();

        Callback::from(move |e: Event| {
            let checkbox: HtmlInputElement = e.target_unchecked_into();
            let checked = checkbox.checked();

            let mut new_filter = (*current_filter).clone();
            new_filter.free_only = Some(checked);

            current_filter.set(new_filter.clone());
            on_filter_change.emit(new_filter);
        })
    };

    let clear_filters = {
        let on_filter_change = props.on_filter_change.clone();

        Callback::from(move |_| {
            let new_filter = EventQuery::default();
            on_filter_change.emit(new_filter);
        })
    };

    html! {
        <div class="filter-bar">
            <div class="filter-section">
                <input
                    type="text"
                    placeholder={i18n.t(|t| &t.search_events)}
                    value={current_filter.search.clone().unwrap_or_default()}
                    onchange={on_search_change}
                />
            </div>

            <div class="filter-section">
                <label for="city-select">{i18n.t(|t| &t.filter_by_city)}{":"}</label>
                <select id="city-select" onchange={on_city_change}>
                    <option value="">{i18n.t(|t| &t.all_cities)}</option>
                    { props.available_cities.iter().map(|city| {
                        let selected = match &current_filter.city {
                            Some(c) => c == city,
                            None => false,
                        };

                        // Check if this is the user's detected city
                        let is_detected = if let Some(loc) = &location {
                            if let Some(user_city) = &loc.city_code {
                                user_city == city
                            } else {
                                false
                            }
                        } else {
                            false
                        };

                        html! {
                            <option value={city.clone()} selected={selected}>
                                {
                                    if is_detected {
                                        format!("{} ({})", city, "📍")
                                    } else {
                                        city.clone()
                                    }
                                }
                            </option>
                        }
                    }).collect::<Html>() }
                </select>
            </div>

            <div class="filter-section checkbox-filter">
                <label>
                    <input
                        type="checkbox"
                        checked={current_filter.free_only.unwrap_or(false)}
                        onchange={on_free_only_change}
                    />
                    {i18n.t(|t| &t.show_free_only)}
                </label>
            </div>

            <div class="filter-section">
                <button class="filter-clear" onclick={clear_filters}>
                    {i18n.t(|t| &t.filter_clear)}
                </button>
            </div>
        </div>
    }
}
