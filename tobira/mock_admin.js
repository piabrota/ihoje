// Admin mock data for testing purposes
window.mockAdminUser = {
  id: "test-admin-id-123",
  email: "admin@test.com",
  name: "Test Admin",
  role: "admin",
  avatar_url: "https://ui-avatars.com/api/?name=Test+Admin&background=0D8ABC&color=fff",
  access_token: "mock-token-123"
};

// Automatically set admin in localStorage for testing purposes
localStorage.setItem("ihoje_auth", JSON.stringify(window.mockAdminUser));
console.log("Admin user mock data loaded:", window.mockAdminUser);
