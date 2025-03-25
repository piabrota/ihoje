/**
 * Script to inject environment variables into the build
 * This runs during the GitHub Actions deployment process
 */
const fs = require('fs');
const path = require('path');

// Get environment from arguments or default to production
const environment = process.env.IHOJE_ENVIRONMENT || 'production';
const apiUrl = process.env.IHOJE_API_URL || 'https://api.ihoje.app/api';
const useMockData = process.env.IHOJE_USE_MOCK_DATA === 'true';

// Create the environment script
const environmentScript = `window.ihoje_env = {
  IHOJE_ENVIRONMENT: "${environment}",
  IHOJE_API_URL: "${apiUrl}",
  IHOJE_USE_MOCK_DATA: "${useMockData ? 'true' : 'false'}"
};

window.get_env_var = function(name) {
  return (window.ihoje_env && window.ihoje_env[name]) || "";
};`;

// Define the path to the built index.html
const distFolder = path.join(__dirname, '..', 'dist');
const envScriptPath = path.join(distFolder, 'env.js');
const indexPath = path.join(distFolder, 'index.html');

// Write the environment script
fs.writeFileSync(envScriptPath, environmentScript);
console.log(`Created environment script at ${envScriptPath}`);

// Add script reference to index.html
if (fs.existsSync(indexPath)) {
  let indexHtml = fs.readFileSync(indexPath, 'utf8');
  
  // Inject the script before the closing head tag
  indexHtml = indexHtml.replace(
    '</head>',
    `  <script src="/env.js"></script>\n</head>`
  );
  
  // Add CSP headers
  indexHtml = indexHtml.replace(
    '<head>',
    `<head>\n  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self'; style-src 'self' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' https: data:; connect-src 'self' ${apiUrl};">`
  );
  
  // Add security headers
  indexHtml = indexHtml.replace(
    '<head>',
    `<head>\n  <meta http-equiv="X-Content-Type-Options" content="nosniff">\n  <meta http-equiv="X-Frame-Options" content="DENY">\n  <meta http-equiv="Strict-Transport-Security" content="max-age=31536000; includeSubDomains">`
  );
  
  // Write the updated index.html
  fs.writeFileSync(indexPath, indexHtml);
  console.log(`Updated index.html with environment script and security headers`);
} else {
  console.error(`Could not find index.html at ${indexPath}`);
  process.exit(1);
}