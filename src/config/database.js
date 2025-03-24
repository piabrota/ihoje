const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const isDev = process.env.NODE_ENV === 'development' || process.env.NODE_ENV !== 'production';

let supabase;

if (!supabaseUrl || !supabaseKey) {
  if (isDev) {
    console.warn('WARNING: Missing Supabase credentials. Running in development mode with mock database.');
    // Create a mock client for development
    supabase = {
      from: () => ({
        select: () => ({ data: [], error: null }),
        insert: () => ({ data: {}, error: null }),
        update: () => ({ data: {}, error: null }),
        delete: () => ({ data: null, error: null }),
        eq: () => ({ data: {}, error: null }),
        single: () => ({ data: {}, error: null }),
        filter: () => ({ data: [], error: null }),
        order: () => ({ data: [], error: null }),
        range: () => ({ data: [], error: null }),
        limit: () => ({ data: [], error: null }),
        ilike: () => ({ data: [], error: null }),
        or: () => ({ data: [], error: null }),
        gte: () => ({ data: [], error: null }),
        lte: () => ({ data: [], error: null })
      }),
      storage: {
        from: () => ({
          upload: () => ({ data: {}, error: null }),
          getPublicUrl: () => ({ data: { publicUrl: 'https://example.com/mock-image.jpg' }, error: null })
        })
      }
    };
  } else {
    throw new Error('Missing Supabase credentials. Please check your .env file.');
  }
} else {
  // Initialize Supabase client
  supabase = createClient(supabaseUrl, supabaseKey);
}

// Test the connection
async function testConnection() {
  try {
    // In development mode with mock client, return true
    if (isDev && (!supabaseUrl || !supabaseKey)) {
      console.log('Development mode: Skipping Supabase connection test');
      return true;
    }
    
    const { data, error } = await supabase.from('events').select('count').limit(1);
    
    if (error) throw error;
    
    console.log('Successfully connected to Supabase');
    return true;
  } catch (error) {
    console.error('Failed to connect to Supabase:', error.message);
    if (isDev) {
      console.warn('Development mode: Continuing despite Supabase connection failure');
      return true;
    }
    return false;
  }
}

module.exports = {
  supabase,
  testConnection
};
