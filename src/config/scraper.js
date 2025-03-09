require('dotenv').config();

// Default scraper configuration
const scraperConfig = {
  userAgent: process.env.SCRAPER_USER_AGENT || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  concurrency: parseInt(process.env.SCRAPER_CONCURRENCY || '2'),
  delayMin: parseInt(process.env.SCRAPER_DELAY_MIN || '2000'),
  delayMax: parseInt(process.env.SCRAPER_DELAY_MAX || '5000'),
  useProxies: process.env.USE_PROXIES === 'true',
  proxyList: (process.env.PROXY_LIST || '').split(',').filter(p => p)
};

module.exports = scraperConfig;
