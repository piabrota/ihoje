use gloo::console::log;
use web_sys::{window, HtmlInputElement};
use yew::prelude::*;
use yew_router::prelude::*;

use crate::i18n::{use_i18n, Language, TranslationKey};
use crate::router::Route;

/// Donation page component
#[function_component(DonatePage)]
pub fn donate_page() -> Html {
    let i18n = use_i18n::<Language, TranslationKey>();
    let navigator = use_navigator().unwrap();

    // State for copy notification
    let show_copy_notification = use_state(|| false);

    // Function to handle address copying
    let copy_to_clipboard = {
        let show_copy_notification = show_copy_notification.clone();

        Callback::from(move |addr: String| {
            // Copy the address to clipboard
            if let Some(window) = window() {
                if let Some(clipboard) = window.navigator().clipboard() {
                    let _ = clipboard.write_text(&addr);

                    // Show notification
                    show_copy_notification.set(true);

                    // Hide after 2 seconds
                    let show_notification = show_copy_notification.clone();
                    let timeout = gloo::timers::callback::Timeout::new(2000, move || {
                        show_notification.set(false);
                    });
                    timeout.forget();
                }
            }
        })
    };

    // Placeholder crypto addresses
    let btc_address = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh";
    let eth_address = "0x71C7656EC7ab88b098defB751B7401B5f6d8976F";
    let xmr_address = "44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A";
    let pix_address = "example@email.com";

    // QR code placeholder URL (base64 encoded for a simple QR)
    let qr_code_url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIQAAACECAYAAABRRIOnAAAAAXNSR0IArs4c6QAAA39JREFUeF7tnTtu3EAQRId3dv/kGzg9sCwgkLWCPYbPsj6BjhE4dLiBA9/gTtacpDFEQSJnm6OemVo+xEEEktNdVf2qq0smuT5dvRjO+Ht4u+GcJHm6Psjng3xkp9qeefp1J8dPzx+y3ydB5B+vnuT4/e5ntrsfx7HsH/hzdDnbZsf7Xfb7Yz/I/kN3I8dX60Z2u5+OY9l/4Nm8ym6XPY671f4cO9/JMJ7tZ9v5c97rEzWo7i+i8ftdVGGhxSG0OBhKgBAkBAghAkIYCGGAECIghIEQBgghAkIYCGGAECIghIEQBgghAkIYCGGAECIghIEQBgghAkIYCGGAECIghIEQBgghAkIYCGGAECIghAEQQgSEMBDCACFEQAiDzBC/NzfZPj7q/WzxMJJcJQohhC7GWf6E+cq/3t/LtmYpVDTuZ+Xx8XG2TpNC5Gj/cLUqdAHpP5rZCznLpdDC8Fw5gHiO4swJgHAGbE4HCGdg5nSAcAZsTgcIZ2DmdIBwBmZOl0L8+Poh+60pWCn8ufF4vG7jHm5vZ3uUiUK4+cBifBRmAQKLcTOc+AQWILAYNwOKT2ABIj6xtAYWIGIQSztggSI2wbQWPsTwI27ivRWAAJFWQLprgQCIdAXSXQsUAJFWQLprgQJE06Bs7u5CdBylaGdBj+PYtKMHiJAw5RUAEVJoPggoQgKVVwBESKH5IKAICRQ8Wp1vfhTzYXbcRfGpPXe3m82s00G6AAEU58Ku9zGgqNeoMCNQFMJVnAYUilrVZwJFnT6FWYCiEK7iNKCo1Kg+C1DUa1SYCSgK4SpOA4pKjerTAEW9RoWZgKIQruI0oKjUqD4NUNRrpMwEFApKxWmAolKj+jRAUa+RMBNQCCBVpwBFtUzCZEAhYFSdAhRVMomTAYUIUm0aUNTKJE4GFCJItWlAUSuTMRlQGEDVXgIUtTIZkwGFAVTtJUBRK5MxGVAYQP34EqD4URT3e/V3Lj+GBw3G7gUUdjzfZgQKN3ThgkARTtq3ECB8uYVTA0U4ad9CgPDlFk4NFOG0zzV/Nb//8vhZ9h36tKrN4XBsPr7y9Z7xvOhVHffhfaP9rnNwbTUhkYz1QzSJoLnpl/9DAISmjD0XIOwaNTcAhKaMPRcg7Bo1NwCEpow9FyDsGjU3AISmjD0XIOwaNTcAhKaMPRcg7Bo1N/gLP0pFJRV8+HAAAAAASUVORK5CYII=";

    html! {
        <div class="donate-page">
            <h1 class="donate-title">{i18n.t(|t| t.donation_title.clone())}</h1>
            <p class="donate-subtitle">{i18n.t(|t| t.donation_subtitle.clone())}</p>

            <div class="donate-content">
                <div class="donate-left">
                    <div class="donate-qr">
                        <img src={qr_code_url} alt="BTC QR Code" />
                        <p class="donate-qr-caption">{i18n.t(|t| t.donation_scan_qr.clone())}</p>
                    </div>
                </div>

                <div class="donate-right">
                    <p class="donate-thank-you">{i18n.t(|t| t.donation_thank_you.clone())}</p>

                    <div class="donation-methods">
                        <div class="donation-method">
                            <h3>{i18n.t(|t| t.donation_bitcoin.clone())}</h3>
                            <div class="address-box">
                                <input type="text" readonly=true value={btc_address} />
                                <button onclick={let addr = btc_address.to_string(); move |_| copy_to_clipboard.emit(addr.clone())}>
                                    {"📋"}
                                </button>
                            </div>
                        </div>

                        <div class="donation-method">
                            <h3>{i18n.t(|t| t.donation_ethereum.clone())}</h3>
                            <div class="address-box">
                                <input type="text" readonly=true value={eth_address} />
                                <button onclick={let addr = eth_address.to_string(); move |_| copy_to_clipboard.emit(addr.clone())}>
                                    {"📋"}
                                </button>
                            </div>
                        </div>

                        <div class="donation-method">
                            <h3>{i18n.t(|t| t.donation_monero.clone())}</h3>
                            <div class="address-box">
                                <input type="text" readonly=true value={xmr_address} />
                                <button onclick={let addr = xmr_address.to_string(); move |_| copy_to_clipboard.emit(addr.clone())}>
                                    {"📋"}
                                </button>
                            </div>
                        </div>

                        <div class="donation-method">
                            <h3>{i18n.t(|t| t.donation_pix.clone())}</h3>
                            <div class="address-box">
                                <input type="text" readonly=true value={pix_address} />
                                <button onclick={let addr = pix_address.to_string(); move |_| copy_to_clipboard.emit(addr.clone())}>
                                    {"📋"}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="donate-back">
                <button class="back-button" onclick={
                    let navigator = navigator.clone();
                    Callback::from(move |_| navigator.push(&Route::Home))
                }>
                    {"← "}{i18n.t(|t| t.back_home.clone())}
                </button>
            </div>

            // Copy notification
            if *show_copy_notification {
                <div class="copy-notification">
                    {i18n.t(|t| t.donation_address_copied.clone())}
                </div>
            }
        </div>
    }
}
