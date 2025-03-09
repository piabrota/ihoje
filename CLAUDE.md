# CLAUDE.md - iHoje Project Guidelines

## Build & Test Commands
- `npm start` - Start the application
- `npm run dev` - Start with nodemon for development
- `npm test` - Run Jest tests
- `npm run test -- -t "test name"` - Run a specific test
- `npm run lint` - Run ESLint
- `npm run scrape` - Run manual scraper script

## Code Style Guidelines
- **Imports**: Group imports by type (node built-ins first, then external packages, then local modules)
- **Naming**: camelCase for variables/functions, PascalCase for classes
- **Functions**: Use async/await for asynchronous code, not Promises with .then()
- **Comments**: JSDoc style comments for functions (include @param and @returns)
- **Error Handling**: Use try/catch blocks with specific error logging
- **Logging**: Use the logger utility (error, warn, info, debug levels)
- **Database**: Use Supabase client from config, handle errors consistently
- **Structure**: Models for database operations, services for business logic
- **Web Scraping**: Use Puppeteer for browser automation, not Playwright

## Project Organization
- `/src/models` - Database models and data access
- `/src/scrapers` - Website-specific scraper implementations
- `/src/services` - Business logic and coordination
- `/src/utils` - Helper functions and utilities
- `/src/config` - Configuration files

This project is an event ticket aggregator service that scrapes ticket information from various websites using Puppeteer.