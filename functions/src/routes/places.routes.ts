import { Router, Request, Response } from 'express';
import https from 'https';

/**
 * Places Router: Cung cấp API Proxy bảo mật cho Google Places API Autocomplete & Details.
 * Giữ bí mật GOOGLE_MAPS_API_KEY trên Cloud Functions server,
 * tự động giới hạn phạm vi quốc gia Việt Nam (country:vn) và ngôn ngữ tiếng Việt (vi).
 */
export const placesRouter = Router();

function fetchHttps(url: string): Promise<any> {
  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let rawData = '';
        res.on('data', (chunk) => {
          rawData += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(rawData);
            resolve(parsed);
          } catch (e) {
            reject(new Error('Phản hồi từ Google Places API không phải định dạng JSON hợp lệ.'));
          }
        });
      })
      .on('error', (err) => {
        reject(err);
      });
  });
}

// GET /api/v1/places/autocomplete
placesRouter.get('/autocomplete', async (req: Request, res: Response) => {
  const input = (req.query.input as string)?.trim();
  const sessionToken = (req.query.sessiontoken as string)?.trim();
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (!input) {
    res.json({
      success: true,
      data: { predictions: [], status: 'ZERO_RESULTS' },
    });
    return;
  }

  if (!apiKey) {
    // Không có API key cấu hình trên server -> trả về trạng thái NO_API_KEY để client fallback nội bộ
    res.json({
      success: true,
      data: { predictions: [], status: 'NO_API_KEY' },
    });
    return;
  }

  try {
    const url = new URL('https://maps.googleapis.com/maps/api/place/autocomplete/json');
    url.searchParams.append('input', input);
    url.searchParams.append('key', apiKey);
    url.searchParams.append('language', 'vi');
    url.searchParams.append('components', 'country:vn');
    if (sessionToken) {
      url.searchParams.append('sessiontoken', sessionToken);
    }

    const data = await fetchHttps(url.toString());
    res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('Google Places Autocomplete Error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'PLACES_API_ERROR',
        message: 'Lỗi khi gọi dịch vụ Google Places Autocomplete.',
        details: error.message,
      },
    });
  }
});

// GET /api/v1/places/details
placesRouter.get('/details', async (req: Request, res: Response) => {
  const placeId = (req.query.place_id as string)?.trim();
  const sessionToken = (req.query.sessiontoken as string)?.trim();
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (!placeId) {
    res.status(400).json({
      success: false,
      error: {
        code: 'MISSING_PARAM',
        message: 'Tham số place_id là bắt buộc.',
      },
    });
    return;
  }

  if (!apiKey) {
    res.json({
      success: true,
      data: { result: null, status: 'NO_API_KEY' },
    });
    return;
  }

  try {
    const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
    url.searchParams.append('place_id', placeId);
    url.searchParams.append('key', apiKey);
    url.searchParams.append('language', 'vi');
    url.searchParams.append(
      'fields',
      'place_id,name,formatted_address,geometry,address_components'
    );
    if (sessionToken) {
      url.searchParams.append('sessiontoken', sessionToken);
    }

    const data = await fetchHttps(url.toString());
    res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('Google Places Details Error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'PLACES_API_ERROR',
        message: 'Lỗi khi gọi dịch vụ Google Places Details.',
        details: error.message,
      },
    });
  }
});
