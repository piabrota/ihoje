const { supabase } = require('../config/database');
const logger = require('../utils/logger');
const { v4 } = require('uuid');
const uuidv4 = v4; // For backward compatibility

/**
 * Save a new event to the database
 * @param {Object} eventData - Event data
 * @returns {Promise<Object>} - Saved event object
 */
async function saveEvent(eventData) {
  try {
    // Normalize event data
    const normalizedEvent = {
      name: eventData.name,
      date: eventData.date ? new Date(eventData.date).toISOString() : null,
      date_end: eventData.date_end ? new Date(eventData.date_end).toISOString() : null,
      venue_id: eventData.venue_id,
      description: eventData.description || '',
      image_url: eventData.image_url || null,
      source: eventData.source || 'manual',
      source_url: eventData.source_url || null,
      location_type: eventData.location_type || 'onsite',
      state: eventData.state || null,
      city: eventData.city || null,
      start_price: eventData.start_price,
      price: eventData.price,
      fee: eventData.fee,
      batch: eventData.batch || null,
      has_half: eventData.has_half === true,
      is_soldout: eventData.is_soldout === true,
      producer: eventData.producer || null,
      share_link: eventData.share_link || null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // Insert event into database
    const { data, error } = await supabase
      .from('events')
      .insert(normalizedEvent)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Saved event: ${normalizedEvent.name} (${data.id})`);
    return data;
  } catch (error) {
    logger.error(`Error saving event: ${error.message}`);
    throw error;
  }
}

/**
 * Find an existing event by name, date and venue
 * @param {Object} criteria - Search criteria
 * @returns {Promise<Object|null>} - Event object or null if not found
 */
async function findExistingEvent(criteria) {
  try {
    const { name, date, venue_name } = criteria;
    
    if (!name) return null;
    
    // First query for events with matching name
    let query = supabase
      .from('events')
      .select(`
        *,
        venue:venues(*)
      `)
      .ilike('name', name);
    
    // Add date filter if provided
    if (date) {
      // Consider events on the same day (ignoring time)
      const dateStr = new Date(date).toISOString().split('T')[0];
      query = query.filter('date', 'gte', `${dateStr}T00:00:00Z`);
      query = query.filter('date', 'lte', `${dateStr}T23:59:59Z`);
    }
    
    const { data, error } = await query;
    
    if (error) {
      throw error;
    }
    
    if (!data || data.length === 0) {
      return null;
    }
    
    // If venue name is provided, filter results further
    if (venue_name) {
      const match = data.find(event => 
        event.venue && 
        event.venue.name.toLowerCase() === venue_name.toLowerCase()
      );
      
      return match || null;
    }
    
    // If no venue specified, return the first match
    return data[0];
  } catch (error) {
    logger.error(`Error finding existing event: ${error.message}`);
    return null;
  }
}

/**
 * Find event by ID
 * @param {string|number} id - Event ID
 * @returns {Promise<Object|null>} - Event object or null if not found
 */
async function findEventById(id) {
  try {
    if (!id) return null;
    
    const { data, error } = await supabase
      .from('events')
      .select(`
        *,
        venue:venues(*),
        prices:prices(*)
      `)
      .eq('id', id)
      .single();
    
    if (error) {
      throw error;
    }
    
    return data || null;
  } catch (error) {
    logger.error(`Error finding event by ID: ${error.message}`);
    return null;
  }
}

/**
 * Update an existing event
 * @param {number} id - Event ID
 * @param {Object} eventData - Updated event data
 * @returns {Promise<Object>} - Updated event object
 */
async function updateEvent(id, eventData) {
  try {
    if (!id) throw new Error('Event ID is required');
    
    // Add update timestamp
    eventData.updated_at = new Date().toISOString();
    
    // Handle date formats if provided
    if (eventData.date) {
      eventData.date = new Date(eventData.date).toISOString();
    }
    
    if (eventData.date_end) {
      eventData.date_end = new Date(eventData.date_end).toISOString();
    }
    
    const { data, error } = await supabase
      .from('events')
      .update(eventData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Updated event: ${eventData.name || 'Unknown'} (${id})`);
    return data;
  } catch (error) {
    logger.error(`Error updating event: ${error.message}`);
    throw error;
  }
}

/**
 * List events with various filtering options
 * @param {Object} options - Query options
 * @returns {Promise<Array>} - Array of event objects
 */
async function listEvents(options = {}) {
  try {
    const { 
      limit = 100, 
      offset = 0, 
      venueId,
      fromDate,
      toDate,
      keyword,
      orderBy = 'date',
      orderDirection = 'asc' 
    } = options;
    
    let query = supabase
      .from('events')
      .select(`
        *,
        venue:venues(*),
        prices:prices(*)
      `);
    
    // Apply filters
    if (venueId) {
      query = query.eq('venue_id', venueId);
    }
    
    if (fromDate) {
      // For multi-day events, include those that end after the fromDate
      const fromDateISO = new Date(fromDate).toISOString();
      query = query.or(`date.gte.${fromDateISO},date_end.gte.${fromDateISO}`);
    }
    
    if (toDate) {
      // For multi-day events, include those that start before the toDate
      const toDateISO = new Date(toDate).toISOString();
      query = query.or(`date.lte.${toDateISO},date_end.lte.${toDateISO}`);
    }
    
    if (keyword) {
      query = query.or(`name.ilike.%${keyword}%,description.ilike.%${keyword}%`);
    }
    
    // Apply ordering
    query = query.order(orderBy, { ascending: orderDirection === 'asc' });
    
    // Apply pagination
    query = query.range(offset, offset + limit - 1);
    
    const { data, error } = await query;
    
    if (error) {
      throw error;
    }
    
    return data || [];
  } catch (error) {
    logger.error(`Error listing events: ${error.message}`);
    return [];
  }
}

/**
 * Delete an event and its related data
 * @param {number} id - Event ID
 * @returns {Promise<boolean>} - Success status
 */
async function deleteEvent(id) {
  try {
    if (!id) throw new Error('Event ID is required');
    
    // Delete related prices first
    const { error: pricesError } = await supabase
      .from('prices')
      .delete()
      .eq('event_id', id);
    
    if (pricesError) {
      throw pricesError;
    }
    
    // Delete the event
    const { error } = await supabase
      .from('events')
      .delete()
      .eq('id', id);
    
    if (error) {
      throw error;
    }
    
    logger.info(`Deleted event with ID: ${id}`);
    return true;
  } catch (error) {
    logger.error(`Error deleting event: ${error.message}`);
    return false;
  }
}

module.exports = {
  saveEvent,
  findExistingEvent,
  findEventById,
  updateEvent,
  listEvents,
  deleteEvent
};
