// Supabase client integration code
// This script creates helper functions for interacting with Supabase from Rust/WASM

(function() {
  // Load Supabase JS client dynamically
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
  script.async = true;
  script.onload = function() {
    console.log('Supabase client loaded successfully');
  };
  document.head.appendChild(script);

  // Create a Supabase client
  window.createSupabaseClient = function(url, key) {
    if (!window.supabase) {
      console.error('Supabase client not loaded yet');
      return null;
    }
    return window.supabase.createClient(url, key);
  };

  // Sign in with Google
  window.supabaseSignInWithGoogle = async function(client) {
    try {
      // Store the requested URL to redirect back after authentication
      const requestedPath = window.location.pathname;
      if (requestedPath && requestedPath !== '/' && requestedPath !== '/login') {
        localStorage.setItem('ihoje_auth_redirect', requestedPath);
      }
      
      // Perform OAuth authentication
      const { data, error } = await client.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin + '/auth/callback'
        }
      });
      
      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error signing in with Google:', error);
      throw error;
    }
  };

  // Sign out
  window.supabaseSignOut = async function(client) {
    try {
      const { error } = await client.auth.signOut();
      if (error) throw error;
      return true;
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    }
  };

  // Get current session
  window.supabaseGetSession = async function(client) {
    try {
      const { data, error } = await client.auth.getSession();
      if (error) throw error;
      return data.session;
    } catch (error) {
      console.error('Error getting session:', error);
      throw error;
    }
  };

  // Get current user
  window.supabaseGetUser = async function(client) {
    try {
      const { data, error } = await client.auth.getUser();
      if (error) throw error;
      return data.user;
    } catch (error) {
      console.error('Error getting user:', error);
      throw error;
    }
  };

  console.log('Supabase client helpers initialized');
})();