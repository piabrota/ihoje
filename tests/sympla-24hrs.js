const puppeteer = require('puppeteer');
const logger = require('../src/utils/logger');

async function testPuppeteer() {
    logger.info('Starting Puppeteer test');

    const browser = await puppeteer.launch({
        headless: false,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    try {
        const page = await browser.newPage();

        // Set viewport
        await page.setViewport({ width: 1920, height: 1080 });

        // Navigate to a test site
        logger.info('Navigating to example.com');
        await page.goto('https://www.sympla.com.br/', { waitUntil: 'networkidle2' });

        // Take a screenshot with timestamp
        const timestamp = new Date().toISOString().replace(/:/g, '-');
        const fs = require('fs');
        const debugDir = 'tests/debug';
        if (!fs.existsSync(debugDir)) {
            fs.mkdirSync(debugDir, { recursive: true });
        }
        await page.screenshot({ path: `${debugDir}/screenshot-${timestamp}.png` });

        // Get page title
        const title = await page.title();
        logger.info(`Page title: ${title}`);

        // Get some content
        const content = await page.$eval('h1', el => el.textContent);
        logger.info(`Page content: ${content}`);

        // Wait 10 seconds
        logger.info('Waiting 10 seconds before dumping HTML...');
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        // Dump HTML to debug file with timestamp
        const htmlTimestamp = new Date().toISOString().replace(/:/g, '-');
        const html = await page.content();
        const fs = require('fs');
        const debugDir = 'tests/debug';
        if (!fs.existsSync(debugDir)) {
            fs.mkdirSync(debugDir, { recursive: true });
        }
        fs.writeFileSync(`${debugDir}/debug-${htmlTimestamp}.html`, html);
        logger.info(`HTML dumped to ${debugDir}/debug-${htmlTimestamp}.html`);
        
        // Take another screenshot in debug folder
        await page.screenshot({ path: `${debugDir}/screenshot-${htmlTimestamp}.png` });
        logger.info(`Screenshot saved to ${debugDir}/screenshot-${htmlTimestamp}.png`);

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
            // Add infinite delay to keep the process running
            console.log('Test complete. Hanging execution indefinitely...');
            setInterval(() => { }, 1000); // Empty interval that never finishes
        })
        .catch(error => {
            console.error('Error running test:', error);
            // Add infinite delay even after error
            console.log('Test failed. Hanging execution indefinitely...');
            setInterval(() => { }, 1000);
        });
}

module.exports = testPuppeteer;