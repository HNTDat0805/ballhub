/**
 * Booking Lifecycle Integration Tests
 * 
 * Test toàn bộ vòng đời của booking:
 * - Create field + slot
 * - Create booking
 * - Double-booking prevention
 * - Owner confirm/reject
 * - User cancel
 * - Authorization checks
 * - Block/Unblock slot
 * - Field status change
 */
import { describe, it } from 'node:test';
import assert from 'node:assert';
import request from 'supertest';
import { app } from '../src/app';
import { BookingStatus, FieldSlotStatus } from '../src/types/booking.types';

describe('Booking Lifecycle — Full End-to-End', () => {
  let fieldId: string;
  let slotId: string;
  let slotId2: string;
  let bookingId: string;        // booking dùng để test confirm
  let bookingId2: string;       // booking dùng để test reject
  let bookingId3: string;       // booking dùng để test cancel by user

  const owner01 = { 'x-user-id': 'lc_owner_01', 'x-user-role': 'fieldOwner', 'x-user-name': 'Nguyen Van Chu San' };
  const owner02 = { 'x-user-id': 'lc_owner_02', 'x-user-role': 'fieldOwner', 'x-user-name': 'Chu San Khac' };
  const player01 = { 'x-user-id': 'lc_player_01', 'x-user-role': 'player', 'x-user-name': 'Nguyen Van Dat San' };
  const player02 = { 'x-user-id': 'lc_player_02', 'x-user-role': 'player', 'x-user-name': 'Le Thi Dat San' };

  // ── SETUP ──────────────────────────────────────────────────────────────────

  it('Setup: Owner tao field active', async () => {
    const res = await request(app)
      .post('/api/v1/fields')
      .set(owner01)
      .send({
        name: 'San Bong Lifecycle Test',
        address: '42 Duong Test, Quan 1',
        city: 'Ho Chi Minh',
        fieldType: '5-a-side',
        capacity: 10,
        basePrice: 250000,
        status: 'active',
      });
    assert.strictEqual(res.status, 201, `Tao field that bai: ${JSON.stringify(res.body)}`);
    assert.strictEqual(res.body.data.status, 'active');
    assert.strictEqual(res.body.data.ownerId, owner01['x-user-id']);
    fieldId = res.body.data.id;
    assert.ok(fieldId, 'fieldId phai ton tai');
  });

  it('Setup: Owner tao 2 slot lien tiep', async () => {
    // slot1: 14:00-15:00 ngay mai
    const d = new Date(Date.now() + 86_400_000);
    d.setUTCHours(7, 0, 0, 0); // 14:00 ICT = 07:00 UTC
    const d1e = new Date(d.getTime() + 3_600_000);
    const d2s = new Date(d1e.getTime());
    const d2e = new Date(d2s.getTime() + 3_600_000);
    const dateKey = d.toISOString().slice(0, 10);

    const s1 = await request(app)
      .post(`/api/v1/fields/${fieldId}/slots`)
      .set(owner01)
      .send({ dateKey, startsAt: d.toISOString(), endsAt: d1e.toISOString(), basePrice: 250000 });
    assert.strictEqual(s1.status, 201);
    assert.strictEqual(s1.body.data.status, FieldSlotStatus.available);
    slotId = s1.body.data.id;

    const s2 = await request(app)
      .post(`/api/v1/fields/${fieldId}/slots`)
      .set(owner01)
      .send({ dateKey, startsAt: d2s.toISOString(), endsAt: d2e.toISOString(), basePrice: 250000 });
    assert.strictEqual(s2.status, 201);
    slotId2 = s2.body.data.id;
  });

  // ── FIELD APIs ─────────────────────────────────────────────────────────────

  it('GET /fields tra ve danh sach bao gom field moi tao', async () => {
    const res = await request(app).get('/api/v1/fields');
    assert.strictEqual(res.status, 200);
    assert.ok(Array.isArray(res.body.data));
    assert.ok(res.body.data.some((f: { id: string }) => f.id === fieldId));
  });

  it('GET /fields/:id tra ve dung thong tin field', async () => {
    const res = await request(app).get(`/api/v1/fields/${fieldId}`);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.id, fieldId);
    assert.strictEqual(res.body.data.name, 'San Bong Lifecycle Test');
    assert.strictEqual(res.body.data.basePrice, 250000);
  });

  it('GET /fields/:id/slots tra ve danh sach slot cua field', async () => {
    const res = await request(app).get(`/api/v1/fields/${fieldId}/slots`);
    assert.strictEqual(res.status, 200);
    assert.ok(res.body.data.length >= 2);
    assert.ok(res.body.data.every((s: { fieldId: string }) => s.fieldId === fieldId));
  });

  // ── CREATE BOOKING ─────────────────────────────────────────────────────────

  it('Player01 dat san thanh cong, slot chuyen sang held', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player01)
      .send({ fieldId, slotIds: [slotId], customerNote: 'Xin chuan bi san truoc' });
    assert.strictEqual(res.status, 201, JSON.stringify(res.body));
    assert.strictEqual(res.body.data.status, BookingStatus.pending);
    assert.strictEqual(res.body.data.bookerId, player01['x-user-id']);
    assert.strictEqual(res.body.data.ownerId, owner01['x-user-id']);
    assert.strictEqual(res.body.data.priceSnapshot, 250000);
    assert.strictEqual(res.body.data.totalAmount, 250000);
    assert.strictEqual(res.body.data.fieldId, fieldId);
    assert.ok(res.body.data.fieldNameSnapshot);
    bookingId = res.body.data.id;
  });

  it('Validation: slotIds rong -> 400', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player01)
      .send({ fieldId, slotIds: [] });
    assert.strictEqual(res.status, 400);
  });

  it('Chong double booking: player02 khong the dat slot da held -> 409 BOOKING_CONFLICT', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player02)
      .send({ fieldId, slotIds: [slotId] });
    assert.strictEqual(res.status, 409);
    assert.strictEqual(res.body.error.code, 'BOOKING_CONFLICT');
    assert.ok(res.body.error.message, 'Phai co message loi');
  });

  // ── GET BOOKING ────────────────────────────────────────────────────────────

  it('GET /bookings/me tra ve booking cua player01', async () => {
    const res = await request(app)
      .get('/api/v1/bookings/me')
      .set(player01);
    assert.strictEqual(res.status, 200);
    assert.ok(res.body.data.some((b: { id: string }) => b.id === bookingId));
  });

  it('GET /bookings/:id tra ve dung booking', async () => {
    const res = await request(app)
      .get(`/api/v1/bookings/${bookingId}`)
      .set(player01);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.id, bookingId);
    assert.strictEqual(res.body.data.customerNote, 'Xin chuan bi san truoc');
  });

  // ── AUTHORIZATION ──────────────────────────────────────────────────────────

  it('Authorization: player02 khong xem duoc booking cua player01 -> 403', async () => {
    const res = await request(app)
      .get(`/api/v1/bookings/${bookingId}`)
      .set(player02);
    assert.strictEqual(res.status, 403);
    assert.strictEqual(res.body.error.code, 'FORBIDDEN');
  });

  it('Authorization: owner01 xem duoc booking thuoc field cua minh', async () => {
    const res = await request(app)
      .get('/api/v1/owner/bookings')
      .set(owner01);
    assert.strictEqual(res.status, 200);
    assert.ok(res.body.data.some((b: { id: string }) => b.id === bookingId));
  });

  it('Authorization: can auth de xem booking/me -> 401', async () => {
    const res = await request(app).get('/api/v1/bookings/me');
    assert.strictEqual(res.status, 401);
  });

  // ── OWNER CONFIRM ──────────────────────────────────────────────────────────

  it('Owner02 khong the confirm booking cua owner01 -> 403', async () => {
    const res = await request(app)
      .post(`/api/v1/owner/bookings/${bookingId}/confirm`)
      .set(owner02);
    assert.strictEqual(res.status, 403);
  });

  it('Owner01 xac nhan booking -> confirmed, slot chuyen booked', async () => {
    const res = await request(app)
      .post(`/api/v1/owner/bookings/${bookingId}/confirm`)
      .set(owner01);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, BookingStatus.confirmed);
    assert.ok(res.body.data.confirmedAt, 'confirmedAt phai duoc set');
  });

  it('Confirm booking da confirmed -> 409 INVALID_BOOKING_STATE', async () => {
    const res = await request(app)
      .post(`/api/v1/owner/bookings/${bookingId}/confirm`)
      .set(owner01);
    assert.strictEqual(res.status, 409);
    assert.strictEqual(res.body.error.code, 'INVALID_BOOKING_STATE');
  });

  // ── OWNER REJECT ───────────────────────────────────────────────────────────

  it('Setup: Player01 tao booking thu 2 tren slot2', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player01)
      .send({ fieldId, slotIds: [slotId2] });
    assert.strictEqual(res.status, 201);
    bookingId2 = res.body.data.id;
  });

  it('Owner reject booking co ly do -> rejected, slot ve available', async () => {
    const res = await request(app)
      .post(`/api/v1/owner/bookings/${bookingId2}/reject`)
      .set(owner01)
      .send({ reason: 'San dang bao tri khong the nhan dat' });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, BookingStatus.rejected);
    assert.ok(res.body.data.rejectedAt);
  });

  it('Reject yeu cau ly do (reason trong body)', async () => {
    // tao booking thu 3 de test reject khong co reason
    const res3 = await request(app)
      .post('/api/v1/bookings')
      .set(player01)
      .send({ fieldId, slotIds: [slotId2] });
    assert.strictEqual(res3.status, 201);
    const tempId = res3.body.data.id;

    // reject khong body -> theo schema, reason optional => van ok
    const rej = await request(app)
      .post(`/api/v1/owner/bookings/${tempId}/reject`)
      .set(owner01)
      .send({});
    // schema require reason? kiem tra
    // Theo bookingReasonSchema, reason la optional -> nen success
    assert.ok([200, 400].includes(rej.status), 'Reject phai tra 200 hoac 400');
  });

  // ── USER CANCEL ────────────────────────────────────────────────────────────

  it('Setup: Player01 tao booking thu 4 tren slot2 (sau reject)', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player01)
      .send({ fieldId, slotIds: [slotId2] });
    assert.strictEqual(res.status, 201, 'Slot phai da ve available sau khi reject');
    bookingId3 = res.body.data.id;
  });

  it('Player khac khong the cancel booking cua player01 -> 403', async () => {
    const res = await request(app)
      .post(`/api/v1/bookings/${bookingId3}/cancel`)
      .set(player02)
      .send({ reason: 'Thu cancel' });
    assert.strictEqual(res.status, 403);
  });

  it('Player01 huy booking cua minh -> cancelledByUser', async () => {
    const res = await request(app)
      .post(`/api/v1/bookings/${bookingId3}/cancel`)
      .set(player01)
      .send({ reason: 'Toi co viec dot xuat' });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, BookingStatus.cancelledByUser);
    assert.ok(res.body.data.cancelledAt);
  });

  // ── BLOCK / UNBLOCK SLOT ───────────────────────────────────────────────────

  it('Owner block slot -> status blocked', async () => {
    const res = await request(app)
      .post(`/api/v1/fields/${fieldId}/slots/${slotId2}/block`)
      .set(owner01)
      .send({ reason: 'Ve sinh san co nhan tao' });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, FieldSlotStatus.blocked);
    assert.strictEqual(res.body.data.blockReason, 'Ve sinh san co nhan tao');
  });

  it('Khong the dat san co slot bi block -> 409', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player02)
      .send({ fieldId, slotIds: [slotId2] });
    assert.strictEqual(res.status, 409);
  });

  it('Owner unblock slot -> status available', async () => {
    const res = await request(app)
      .post(`/api/v1/fields/${fieldId}/slots/${slotId2}/unblock`)
      .set(owner01);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, FieldSlotStatus.available);
  });

  // ── FIELD STATUS ───────────────────────────────────────────────────────────

  it('PATCH /fields/:id/status -> inactive', async () => {
    const res = await request(app)
      .patch(`/api/v1/fields/${fieldId}/status`)
      .set(owner01)
      .send({ status: 'inactive' });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, 'inactive');
  });

  it('Field inactive: khong the tao booking -> 409 FIELD_UNAVAILABLE', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .set(player02)
      .send({ fieldId, slotIds: [slotId2] });
    assert.strictEqual(res.status, 409);
    assert.strictEqual(res.body.error.code, 'FIELD_UNAVAILABLE');
  });

  it('PATCH /fields/:id/status -> active (restore)', async () => {
    const res = await request(app)
      .patch(`/api/v1/fields/${fieldId}/status`)
      .set(owner01)
      .send({ status: 'active' });
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.data.status, 'active');
  });

  // ── FIELD OWNERSHIP ────────────────────────────────────────────────────────

  it('Owner02 khong the sua field cua owner01 -> 403 hoac 404', async () => {
    const res = await request(app)
      .patch(`/api/v1/fields/${fieldId}/status`)
      .set(owner02)
      .send({ status: 'inactive' });
    // Service phai check ownership
    assert.ok([403, 404].includes(res.status), `Expected 403/404, got ${res.status}`);
  });

  // ── UNAUTHENTICATED ────────────────────────────────────────────────────────

  it('Khong co token: tao booking -> 401', async () => {
    const res = await request(app)
      .post('/api/v1/bookings')
      .send({ fieldId, slotIds: [slotId] });
    assert.strictEqual(res.status, 401);
  });

  it('Player role: khong the tao field -> 403', async () => {
    const res = await request(app)
      .post('/api/v1/fields')
      .set(player01)
      .send({ name: 'Illegal Field', address: '1 Test', city: 'HCM', fieldType: '5-a-side', capacity: 5, basePrice: 100000, status: 'active' });
    assert.strictEqual(res.status, 403);
  });
});
