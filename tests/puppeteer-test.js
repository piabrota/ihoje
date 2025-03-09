const puppeteer = require('puppeteer');
const logger = require('../src/utils/logger');

async function testPuppeteer() {
  logger.info('Starting Puppeteer test');
  
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    
    // Set viewport
    await page.setViewport({ width: 1920, height: 1080 });
    
    // Navigate to a test site
    logger.info('Navigating to example.com');
    await page.goto('https://example.com', { waitUntil: 'networkidle2' });
    
    // Take a screenshot
    await page.screenshot({ path: 'tests/screenshot.png' });
    
    // Get page title
    const title = await page.title();
    logger.info(`Page title: ${title}`);
    
    // Get some content
    const content = await page.$eval('h1', el => el.textContent);
    logger.info(`Page content: ${content}`);
    
    logger.info('Puppeteer test completed successfully');
    return { success: true, title, content };
  } catch (error) {
    logger.error(`Puppeteer test failed: ${error.message}`);
    return { success: false, error: error.message };
  } finally {
    await browser.close();
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  testPuppeteer()
    .then(result => {
      console.log('Test result:', result);
      process.exit(result.success ? 0 : 1);
    })
    .catch(error => {
      console.error('Error running test:', error);
      process.exit(1);
    });
}

module.exports = testPuppeteer;