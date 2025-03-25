-- PostgreSQL schema for events database

-- Create events table
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    date TEXT NOT NULL,
    location TEXT NOT NULL,
    url TEXT NOT NULL,
    image_url TEXT,
    city TEXT NOT NULL,
    price TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create failed price fetches table
CREATE TABLE IF NOT EXISTS failed_price_fetches (
    id TEXT NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    error TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, timestamp)
);

-- Create index on date for efficient filtering
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);

-- Create index on city for filtering by city
CREATE INDEX IF NOT EXISTS idx_events_city ON events(city);

-- Create index on failure timestamp
CREATE INDEX IF NOT EXISTS idx_failures_timestamp ON failed_price_fetches(timestamp);

-- Create a view for recent events
CREATE OR REPLACE VIEW recent_events AS
SELECT *
FROM events
WHERE created_at > (CURRENT_DATE - INTERVAL '7 days')
ORDER BY created_at DESC;

-- Create a view for upcoming events based on date format
CREATE OR REPLACE VIEW upcoming_events AS
SELECT *
FROM events
WHERE TO_DATE(date, 'DD/MM/YYYY') >= CURRENT_DATE
ORDER BY TO_DATE(date, 'DD/MM/YYYY') ASC;

-- Create a view for recent failures
CREATE OR REPLACE VIEW recent_failures AS
SELECT *
FROM failed_price_fetches
WHERE created_at > (CURRENT_DATE - INTERVAL '7 days')
ORDER BY created_at DESC;