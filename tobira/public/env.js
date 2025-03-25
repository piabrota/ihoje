// iHoje Environment Variables for Development
window.ihoje_env = {
  IHOJE_ENVIRONMENT: "development",
  IHOJE_API_URL: "http://localhost:8080/api",
  IHOJE_USE_MOCK_DATA: "true",
  IHOJE_SUPABASE_URL: "https://your-supabase-url.supabase.co",
  IHOJE_SUPABASE_ANON_KEY: "your-supabase-anon-key"
};

window.get_env_var = function(name) {
  return (window.ihoje_env && window.ihoje_env[name]) || "";
};