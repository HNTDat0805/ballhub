import { describe, it } from 'node:test';
import assert from 'node:assert';
import request from 'supertest';
import { app } from '../src/app';

describe('Google Places Proxy API Test Suite', () => {
  it('GET /api/v1/places/autocomplete should return empty predictions when input is empty', async () => {
    const res = await request(app).get('/api/v1/places/autocomplete?input=');
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.success, true);
    assert.deepStrictEqual(res.body.data.predictions, []);
  });

  it('GET /api/v1/places/autocomplete should return NO_API_KEY status when GOOGLE_MAPS_API_KEY is unset on server', async () => {
    const res = await request(app).get('/api/v1/places/autocomplete?input=Hanoi');
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.success, true);
    assert.strictEqual(res.body.data.status, 'NO_API_KEY');
    assert.deepStrictEqual(res.body.data.predictions, []);
  });

  it('GET /api/v1/places/details should return 400 when place_id parameter is missing', async () => {
    const res = await request(app).get('/api/v1/places/details');
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.body.success, false);
    assert.strictEqual(res.body.error.code, 'MISSING_PARAM');
  });

  it('GET /api/v1/places/details should return NO_API_KEY status when GOOGLE_MAPS_API_KEY is unset on server', async () => {
    const res = await request(app).get('/api/v1/places/details?place_id=ChIJ123');
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.success, true);
    assert.strictEqual(res.body.data.status, 'NO_API_KEY');
    assert.strictEqual(res.body.data.result, null);
  });
});
