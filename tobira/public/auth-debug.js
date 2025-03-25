// Authentication Debugging Helper
(function() {
  // Check if we have a redirect path stored
  const storedPath = localStorage.getItem('ihoje_auth_redirect');
  console.log('Stored redirect path:', storedPath || 'None');
  
  // Check URL for auth tokens
  const hashParams = new URLSearchParams(window.location.hash.substring(1));
  const hasToken = hashParams.has('access_token');
  console.log('URL contains auth token:', hasToken);
  
  // Check if we're on the callback page
  const isCallback = window.location.pathname === '/auth/callback';
  console.log('On auth callback page:', isCallback);
  
  // Listen for auth state changes
  window.addEventListener('storage', function(e) {
    if (e.key === 'ihoje_auth_redirect') {
      console.log('Redirect path changed:', e.newValue);
    }
    if (e.key === 'ihoje_auth') {
      console.log('Auth state changed');
    }
  });
  
  // Add to window object for console debugging
  window.debugAuth = {
    getRedirectPath: function() {
      return localStorage.getItem('ihoje_auth_redirect');
    },
    clearRedirectPath: function() {
      localStorage.removeItem('ihoje_auth_redirect');
      console.log('Cleared redirect path');
    },
    setRedirectPath: function(path) {
      localStorage.setItem('ihoje_auth_redirect', path);
      console.log('Set redirect path to:', path);
    },
    getAuthState: function() {
      try {
        const auth = localStorage.getItem('ihoje_auth');
        return auth ? JSON.parse(auth) : null;
      } catch (e) {
        console.error('Error parsing auth state:', e);
        return null;
      }
    }
  };
  
  console.log('Auth debugging helpers initialized');
})();