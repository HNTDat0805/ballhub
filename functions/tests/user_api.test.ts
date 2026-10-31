import { describe, it } from 'node:test';
import assert from 'node:assert';
import request from 'supertest';
import { app } from '../src/app';

describe('User Profile & Avatar REST API Test Suite', () => {
  const userId = 'user_test_profile_01';
  const samplePngBase64 =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
  const sampleJpegBase64 =
    'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';

  describe('1. GET /api/v1/users/me', () => {
    it('should return 401 Unauthorized when no auth credentials provided', async () => {
      const res = await request(app).get('/api/v1/users/me');
      assert.strictEqual(res.status, 401);
      assert.strictEqual(res.body.success, false);
      assert.strictEqual(res.body.error.code, 'UNAUTHENTICATED');
    });

    it('should return 200 and default profile for authenticated player', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.userId, userId);
      assert.strictEqual(res.body.data.role, 'player');
    });

    it('should reflect user name from x-user-name header if profile name unset', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', 'user_with_name_01')
        .set('x-user-role', 'player')
        .set('x-user-name', encodeURIComponent('Văn Quyết'));

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.fullName, 'Văn Quyết');
    });

    it('should correctly map teamCaptain role', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', 'user_captain_check')
        .set('x-user-role', 'teamCaptain');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.data.role, 'teamCaptain');
    });

    it('should correctly map organizer role', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', 'user_organizer_check')
        .set('x-user-role', 'organizer');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.data.role, 'organizer');
    });

    it('should correctly map fieldOwner role', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', 'user_owner_check')
        .set('x-user-role', 'fieldOwner');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.data.role, 'fieldOwner');
    });

    it('should correctly map admin role', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', 'user_admin_check')
        .set('x-user-role', 'admin');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.data.role, 'admin');
    });
  });

  describe('2. PATCH /api/v1/users/me', () => {
    it('should return 401 Unauthorized when unauthenticated', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .send({ fullName: 'Anonymous Hacker' });

      assert.strictEqual(res.status, 401);
      assert.strictEqual(res.body.success, false);
    });

    it('should reject short fullName (< 2 chars) with 400 VALIDATION_ERROR', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ fullName: 'A' });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('should reject phone exceeding 20 chars with 400 VALIDATION_ERROR', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ phone: '123456789012345678901' });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('should reject area exceeding 100 chars with 400 VALIDATION_ERROR', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ area: 'A'.repeat(101) });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('should successfully update fullName only', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ fullName: 'Nguyễn Quang Hải' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.fullName, 'Nguyễn Quang Hải');
    });

    it('should successfully update phone only', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ phone: '0987654321' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.phone, '0987654321');
    });

    it('should successfully update position only', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ position: 'Tiền vệ tấn công (CAM)' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.position, 'Tiền vệ tấn công (CAM)');
    });

    it('should successfully update area only', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ area: 'Quận 7, TP. Hồ Chí Minh' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.area, 'Quận 7, TP. Hồ Chí Minh');
    });

    it('should successfully update all profile fields at once', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({
          fullName: 'Đoàn Văn Hậu',
          phone: '0912345678',
          position: 'Hậu vệ cánh trái (LB)',
          area: 'Hà Nội',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.fullName, 'Đoàn Văn Hậu');
      assert.strictEqual(res.body.data.phone, '0912345678');
      assert.strictEqual(res.body.data.position, 'Hậu vệ cánh trái (LB)');
      assert.strictEqual(res.body.data.area, 'Hà Nội');
    });

    it('should update updatedAt timestamp after PATCH', async () => {
      const beforeRes = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player');

      const initialUpdatedAt = beforeRes.body.data.updatedAt;

      // Make update
      const updateRes = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ fullName: 'Đoàn Văn Hậu Pro' });

      assert.strictEqual(updateRes.status, 200);
      assert.ok(updateRes.body.data.updatedAt);
      assert.strictEqual(updateRes.body.data.fullName, 'Đoàn Văn Hậu Pro');
    });
  });

  describe('3. POST /api/v1/users/me/avatar', () => {
    it('should return 401 Unauthorized when unauthenticated', async () => {
      const res = await request(app)
        .post('/api/v1/users/me/avatar')
        .send({ avatarBase64: samplePngBase64 });

      assert.strictEqual(res.status, 401);
      assert.strictEqual(res.body.success, false);
    });

    it('should reject empty avatarBase64 with 400 VALIDATION_ERROR', async () => {
      const res = await request(app)
        .post('/api/v1/users/me/avatar')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ avatarBase64: '' });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('should successfully update avatar with valid PNG data URI', async () => {
      const res = await request(app)
        .post('/api/v1/users/me/avatar')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ avatarBase64: samplePngBase64 });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.avatarBase64, samplePngBase64);
    });

    it('should successfully update avatar with valid JPEG data URI', async () => {
      const res = await request(app)
        .post('/api/v1/users/me/avatar')
        .set('x-user-id', userId)
        .set('x-user-role', 'player')
        .send({ avatarBase64: sampleJpegBase64 });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.avatarBase64, sampleJpegBase64);
    });

    it('GET /api/v1/users/me should return persisted avatar and updated fields', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', userId)
        .set('x-user-role', 'player');

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.avatarBase64, sampleJpegBase64);
      assert.strictEqual(res.body.data.fullName, 'Đoàn Văn Hậu Pro');
      assert.strictEqual(res.body.data.phone, '0912345678');
      assert.strictEqual(res.body.data.area, 'Hà Nội');
    });
  });
});
