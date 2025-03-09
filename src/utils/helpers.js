const { format, isValid } = require('date-fns');
const logger = require('./logger');

/**
 * Extracts a date from a text string
 * @param {string} text - Text that might contain a date
 * @returns {string|null} - ISO formatted date string or null if not found
 */
function extractDateFromText(text) {
  if (!text) return null;
  
  // Try various date formats
  const patterns = [
    // 2023-09-15
    {
      regex: /(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})/,
      format: '$1-$2-$3'
    },
    // 15/09/2023, 15-09-2023, 15.09.2023
    {
      regex: /(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})/,
      format: '$3-$2-$1'
    },
    // September 15, 2023, September 15th, 2023
    {
      regex: /([A-Za-z]+)\s+(\d{1,2})(?:st|nd|rd|th)?,\s+(\d{4})/,
      format: '$3-$1-$2'
    },
    // 15 September 2023, 15th September 2023
    {
      regex: /(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\s+(\d{4})/,
      format: '$3-$2-$1'
    }
  ];
  
  // Try each pattern
  for (const pattern of patterns) {
    const match = text.match(pattern.regex);
    if (match) {
      let dateStr = pattern.format;
      
      // Replace capture groups
      for (let i = 1; i < match.length; i++) {
        dateStr = dateStr.replace(`$${i}`, match[i]);
      }
      
      // Parse the date
      try {
        const date = new Date(dateStr);
        if (isValid(date)) {
          return date.toISOString();
        }
      } catch (error) {
        // Continue to next pattern
      }
    }
  }
  
  // Try to find a date using natural language
  try {
    const monthNames = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    
    const monthRegex = new RegExp(`(${monthNames.join('|')})`, 'i');
    const monthMatch = text.match(monthRegex);
    
    if (monthMatch) {
      const monthIndex = monthNames.findIndex(m => 
        m.toLowerCase() === monthMatch[1].toLowerCase()
      );
      
      if (monthIndex !== -1) {
        // Try to find a day near the month
        const dayRegex = new RegExp(`\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+${monthMatch[1]}|${monthMatch[1]}\\s+(\\d{1,2})(?:st|nd|rd|th)?\\b`, 'i');
        const dayMatch = text.match(dayRegex);
        
        if (dayMatch) {
          // Get the day number (could be in group 1 or 2)
          const day = dayMatch[1] || dayMatch[2];
          
          // Try to find a year near the month
          const yearRegex = /\b(20\d{2})\b/;
          const yearMatch = text.match(yearRegex);
          const year = yearMatch ? yearMatch[1] : new Date().getFullYear();
          
          const date = new Date(year, monthIndex, parseInt(day));
          if (isValid(date)) {
            return date.toISOString();
          }
        }
      }
    }
  } catch (error) {
    logger.debug(`Error parsing natural language date: ${error.message}`);
  }
  
  // If we still couldn't parse a date, log and return null
  logger.debug(`Could not extract date from text: ${text}`);
  return null;
}

/**
 * Clean text by removing extra whitespace, HTML tags, etc.
 * @param {string} text - Text to clean
 * @returns {string} - Cleaned text
 */
function cleanText(text) {
  if (!text) return '';
  
  return text
    // Remove HTML tags
    .replace(/<[^>]*>/g, ' ')
    // Replace multiple spaces, tabs, newlines with a single space
    .replace(/\s+/g, ' ')
    // Trim leading/trailing whitespace
    .trim();
}

/**
 * Generate a slug from a string
 * @param {string} text - Text to convert to slug
 * @returns {string} - Slug
 */
function slugify(text) {
  if (!text) return '';
  
  return text
    .toString()
    .toLowerCase()
    .replace(/\s+/g, '-')        // Replace spaces with -
    .replace(/[^\w\-]+/g, '')    // Remove all non-word chars
    .replace(/\-\-+/g, '-')      // Replace multiple - with single -
    .replace(/^-+/, '')          // Trim - from start of text
    .replace(/-+$/, '');         // Trim - from end of text
}

/**
 * Generate a random user agent string
 * @returns {string} - User agent string
 */
function getRandomUserAgent() {
  const userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/127.0.0.0 Safari/537.36'
  ];
  
  return userAgents[Math.floor(Math.random() * userAgents.length)];
}

/**
 * Deep compare two objects for equality
 * @param {Object} obj1 - First object
 * @param {Object} obj2 - Second object
 * @returns {boolean} - True if objects are equal
 */
function deepEqual(obj1, obj2) {
  if (obj1 === obj2) return true;
  
  if (typeof obj1 !== 'object' || obj1 === null ||
      typeof obj2 !== 'object' || obj2 === null) {
    return false;
  }
  
  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);
  
  if (keys1.length !== keys2.length) return false;
  
  for (const key of keys1) {
    if (!keys2.includes(key)) return false;
    
    if (!deepEqual(obj1[key], obj2[key])) return false;
  }
  
  return true;
}

/**
 * Format a date with optional format string
 * @param {Date|string} date - Date to format
 * @param {string} formatStr - Format pattern (date-fns format)
 * @returns {string} - Formatted date string
 */
function formatDate(date, formatStr = 'yyyy-MM-dd') {
  if (!date) return '';
  
  try {
    const parsedDate = typeof date === 'string' ? new Date(date) : date;
    return format(parsedDate, formatStr);
  } catch (error) {
    logger.error(`Error formatting date: ${error.message}`);
    return '';
  }
}

/**
 * Calculate date difference in days
 * @param {Date|string} date1 - First date
 * @param {Date|string} date2 - Second date
 * @returns {number} - Difference in days
 */
function dateDiffInDays(date1, date2) {
  if (!date1 || !date2) return 0;
  
  try {
    const d1 = typeof date1 === 'string' ? new Date(date1) : date1;
    const d2 = typeof date2 === 'string' ? new Date(date2) : date2;
    
    // Convert to UTC to avoid timezone issues
    const utc1 = Date.UTC(d1.getFullYear(), d1.getMonth(), d1.getDate());
    const utc2 = Date.UTC(d2.getFullYear(), d2.getMonth(), d2.getDate());
    
    return Math.floor((utc2 - utc1) / (1000 * 60 * 60 * 24));
  } catch (error) {
    logger.error(`Error calculating date difference: ${error.message}`);
    return 0;
  }
}

module.exports = {
  extractDateFromText,
  cleanText,
  slugify,
  getRandomUserAgent,
  deepEqual,
  formatDate,
  dateDiffInDays
};
