const { supabase } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Save a new venue to the database
 * @param {Object} venueData - Venue data
 * @returns {Promise<Object>} - Saved venue object
 */
async function saveVenue(venueData) {
  try {
    // Normalize venue data
    const normalizedVenue = {
      name: venueData.name || 'Unknown Venue',
      address: venueData.address || '',
      city: venueData.city || '',
      state: venueData.state || '',
      country: venueData.country || '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // Insert venue into database
    const { data, error } = await supabase
      .from('venues')
      .insert(normalizedVenue)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Saved venue: ${normalizedVenue.name} (${data.id})`);
    return data;
  } catch (error) {
    logger.error(`Error saving venue: ${error.message}`);
    throw error;
  }
}

/**
 * Find venue by name
 * @param {string} name - Venue name
 * @returns {Promise<Object|null>} - Venue object or null if not found
 */
async function findVenueByName(name) {
  try {
    if (!name) return null;
    
    const { data, error } = await supabase
      .from('venues')
      .select('*')
      .ilike('name', name)
      .limit(1)
      .single();
    
    if (error && error.code !== 'PGRST116') {
      throw error;
    }
    
    return data || null;
  } catch (error) {
    logger.error(`Error finding venue by name: ${error.message}`);
    return null;
  }
}

/**
 * Find venue by ID
 * @param {string|number} id - Venue ID
 * @returns {Promise<Object|null>} - Venue object or null if not found
 */
async function findVenueById(id) {
  try {
    if (!id) return null;
    
    const { data, error } = await supabase
      .from('venues')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) {
      throw error;
    }
    
    return data || null;
  } catch (error) {
    logger.error(`Error finding venue by ID: ${error.message}`);
    return null;
  }
}

/**
 * Update an existing venue
 * @param {number} id - Venue ID
 * @param {Object} venueData - Updated venue data
 * @returns {Promise<Object>} - Updated venue object
 */
async function updateVenue(id, venueData) {
  try {
    if (!id) throw new Error('Venue ID is required');
    
    // Add update timestamp
    venueData.updated_at = new Date().toISOString();
    
    const { data, error } = await supabase
      .from('venues')
      .update(venueData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Updated venue: ${venueData.name || 'Unknown'} (${id})`);
    return data;
  } catch (error) {
    logger.error(`Error updating venue: ${error.message}`);
    throw error;
  }
}

/**
 * List all venues with optional filtering
 * @param {Object} options - Query options (limit, offset, filters)
 * @returns {Promise<Array>} - Array of venue objects
 */
async function listVenues(options = {}) {
  try {
    const { limit = 100, offset = 0, city, country } = options;
    
    let query = supabase
      .from('venues')
      .select('*')
      .order('name', { ascending: true })
      .range(offset, offset + limit - 1);
    
    // Apply filters if provided
    if (city) {
      query = query.ilike('city', `%${city}%`);
    }
    
    if (country) {
      query = query.ilike('country', `%${country}%`);
    }
    
    const { data, error } = await query;
    
    if (error) {
      throw error;
    }
    
    return data || [];
  } catch (error) {
    logger.error(`Error listing venues: ${error.message}`);
    return [];
  }
}

module.exports = {
  saveVenue,
  findVenueByName,
  findVenueById,
  updateVenue,
  listVenues
};
