const { supabase } = require('../config/database');
const logger = require('../utils/logger');

/**
 * Save new price information for an event
 * @param {Object} priceData - Price data
 * @returns {Promise<Object>} - Saved price object
 */
async function savePrices(priceData) {
  try {
    // Normalize price data
    const normalizedPrice = {
      event_id: priceData.event_id,
      price_type: priceData.price_type || 'Standard',
      price_value: priceData.price_value || 0,
      currency: priceData.currency || '$',
      availability: priceData.availability || 'Available',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    // Insert price into database
    const { data, error } = await supabase
      .from('prices')
      .insert(normalizedPrice)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Saved price for event ID ${priceData.event_id}: ${priceData.price_type} - ${priceData.price_value} ${priceData.currency}`);
    return data;
  } catch (error) {
    logger.error(`Error saving price: ${error.message}`);
    throw error;
  }
}

/**
 * Update an existing price
 * @param {number} id - Price ID
 * @param {Object} priceData - Updated price data
 * @returns {Promise<Object>} - Updated price object
 */
async function updatePrice(id, priceData) {
  try {
    if (!id) throw new Error('Price ID is required');
    
    // Add update timestamp
    priceData.updated_at = new Date().toISOString();
    
    const { data, error } = await supabase
      .from('prices')
      .update(priceData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      throw error;
    }
    
    logger.info(`Updated price: ID ${id}`);
    return data;
  } catch (error) {
    logger.error(`Error updating price: ${error.message}`);
    throw error;
  }
}

/**
 * Get all prices for an event
 * @param {number} eventId - Event ID
 * @returns {Promise<Array>} - Array of price objects
 */
async function getPricesForEvent(eventId) {
  try {
    if (!eventId) throw new Error('Event ID is required');
    
    const { data, error } = await supabase
      .from('prices')
      .select('*')
      .eq('event_id', eventId)
      .order('price_value', { ascending: true });
    
    if (error) {
      throw error;
    }
    
    return data || [];
  } catch (error) {
    logger.error(`Error getting prices for event: ${error.message}`);
    return [];
  }
}

/**
 * Delete a price
 * @param {number} id - Price ID
 * @returns {Promise<boolean>} - Success status
 */
async function deletePrice(id) {
  try {
    if (!id) throw new Error('Price ID is required');
    
    const { error } = await supabase
      .from('prices')
      .delete()
      .eq('id', id);
    
    if (error) {
      throw error;
    }
    
    logger.info(`Deleted price with ID: ${id}`);
    return true;
  } catch (error) {
    logger.error(`Error deleting price: ${error.message}`);
    return false;
  }
}

/**
 * Track price changes for an event
 * @param {number} eventId - Event ID
 * @param {Array} newPrices - New price data
 * @returns {Promise<Object>} - Price change summary
 */
async function trackPriceChanges(eventId, newPrices) {
  try {
    if (!eventId) throw new Error('Event ID is required');
    if (!newPrices || !Array.isArray(newPrices)) throw new Error('New prices must be an array');
    
    // Get existing prices
    const existingPrices = await getPricesForEvent(eventId);
    
    const changes = {
      added: [],
      updated: [],
      removed: [],
      unchanged: []
    };
    
    // Process new prices
    for (const newPrice of newPrices) {
      const existingPrice = existingPrices.find(p => 
        p.price_type === newPrice.price_type && 
        p.currency === newPrice.currency
      );
      
      if (!existingPrice) {
        // New price
        const savedPrice = await savePrices({
          event_id: eventId,
          ...newPrice
        });
        changes.added.push(savedPrice);
      } else if (existingPrice.price_value !== newPrice.price_value || 
                existingPrice.availability !== newPrice.availability) {
        // Updated price
        const updatedPrice = await updatePrice(existingPrice.id, {
          price_value: newPrice.price_value,
          availability: newPrice.availability,
          updated_at: new Date().toISOString()
        });
        changes.updated.push({
          before: existingPrice,
          after: updatedPrice
        });
      } else {
        changes.unchanged.push(existingPrice);
      }
    }
    
    // Find removed prices
    const existingPriceTypes = existingPrices.map(p => `${p.price_type}-${p.currency}`);
    const newPriceTypes = newPrices.map(p => `${p.price_type}-${p.currency}`);
    
    const removedPrices = existingPrices.filter(p => 
      !newPriceTypes.includes(`${p.price_type}-${p.currency}`)
    );
    
    // Mark these as unavailable rather than deleting
    for (const removedPrice of removedPrices) {
      const updatedPrice = await updatePrice(removedPrice.id, {
        availability: 'Unavailable',
        updated_at: new Date().toISOString()
      });
      
      changes.removed.push({
        before: removedPrice,
        after: updatedPrice
      });
    }
    
    // Create a log of price changes for analysis
    if (changes.added.length > 0 || changes.updated.length > 0 || changes.removed.length > 0) {
      await supabase
        .from('price_history')
        .insert({
          event_id: eventId,
          changes: JSON.stringify(changes),
          created_at: new Date().toISOString()
        });
      
      logger.info(`Tracked price changes for event ${eventId}: ${changes.added.length} added, ` +
        `${changes.updated.length} updated, ${changes.removed.length} removed`);
    }
    
    return changes;
  } catch (error) {
    logger.error(`Error tracking price changes: ${error.message}`);
    throw error;
  }
}

module.exports = {
  savePrices,
  updatePrice,
  getPricesForEvent,
  deletePrice,
  trackPriceChanges
};
