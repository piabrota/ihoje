-- Create venues table
CREATE TABLE IF NOT EXISTS venues (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  date TIMESTAMP WITH TIME ZONE,
  venue_id BIGINT REFERENCES venues(id),
  description TEXT,
  image_url TEXT,
  source TEXT,
  source_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create prices table
CREATE TABLE IF NOT EXISTS prices (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  price_type TEXT,
  price_value DECIMAL(10, 2),
  currency TEXT DEFAULT '$',
  availability TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create price_history table for tracking changes
CREATE TABLE IF NOT EXISTS price_history (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  changes JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS events_venue_id_idx ON events(venue_id);
CREATE INDEX IF NOT EXISTS events_date_idx ON events(date);
CREATE INDEX IF NOT EXISTS events_name_idx ON events(name);
CREATE INDEX IF NOT EXISTS prices_event_id_idx ON prices(event_id);
CREATE INDEX IF NOT EXISTS venues_name_idx ON venues(name);
CREATE INDEX IF NOT EXISTS venues_city_idx ON venues(city);

-- Create a view for event summaries with venue information
CREATE OR REPLACE VIEW event_summaries AS
SELECT 
  e.id,
  e.name,
  e.date,
  v.name AS venue_name,
  v.city,
  v.state,
  v.country,
  e.image_url,
  MIN(p.price_value) AS min_price,
  MAX(p.price_value) AS max_price,
  p.currency,
  CASE 
    WHEN e.date < CURRENT_TIMESTAMP THEN 'past'
    ELSE 'upcoming'
  END AS event_status
FROM events e
LEFT JOIN venues v ON e.venue_id = v.id
LEFT JOIN prices p ON e.id = p.event_id
GROUP BY e.id, v.id, p.currency;

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_events_updated_at
BEFORE UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_venues_updated_at
BEFORE UPDATE ON venues
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prices_updated_at
BEFORE UPDATE ON prices
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a bucket for event images in storage
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-images', 'Event Images', true)
ON CONFLICT (id) DO NOTHING;

-- Set up policies for the storage bucket to allow public access to images
CREATE POLICY "Public Access for Event Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-images');

-- RLS policies for application
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users to manage events
CREATE POLICY "Authenticated users can manage events"
ON events FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy for authenticated users to manage venues
CREATE POLICY "Authenticated users can manage venues"
ON venues FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy for authenticated users to manage prices
CREATE POLICY "Authenticated users can manage prices"
ON prices FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy for authenticated users to manage price history
CREATE POLICY "Authenticated users can manage price history"
ON price_history FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow anonymous users to read events and related data
CREATE POLICY "Anonymous users can read events"
ON events FOR SELECT
TO anon
USING (true);

CREATE POLICY "Anonymous users can read venues"
ON venues FOR SELECT
TO anon
USING (true);

CREATE POLICY "Anonymous users can read prices"
ON prices FOR SELECT
TO anon
USING (true);
