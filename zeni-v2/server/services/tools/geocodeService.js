import { createLogger } from '../../utils/logger.js';

const logger = createLogger('geocode');

// OpenStreetMap Nominatim — free, keyless, no account needed. Same
// keyless-first approach as most of God's Eye View's own layers.
export async function geocodeLocation(query) {
  try {
    const res = await fetch(
      `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=1`,
      { headers: { 'User-Agent': 'Zeni/2.0' } }
    );
    if (!res.ok) return { ok: false, status: 'LOOKUP_FAILED' };
    const results = await res.json();
    if (!results.length) return { ok: false, status: 'NOT_FOUND' };
    const { lat, lon, display_name } = results[0];
    return { ok: true, lat: parseFloat(lat), lng: parseFloat(lon), displayName: display_name };
  } catch (err) {
    logger.error('geocode request failed', { message: err.message });
    return { ok: false, status: 'SERVICE_UNREACHABLE' };
  }
}
