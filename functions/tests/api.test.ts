import { describe, it } from 'node:test';
import assert from 'node:assert';
import request from 'supertest';
import { app } from '../src/app';
import { TournamentFormat, TournamentStatus, RegistrationStatus } from '../src/types/tournament.types';
import { FieldSlotStatus } from '../src/types/booking.types';

describe('Ballhub API-First REST API Test Suite', () => {
  let createdTournamentId: string;
  let regTeam1Id: string;
  let regTeam2Id: string;
  let generatedMatchId: string;

  // 1. Health and Documentation
  describe('Health and OpenAPI Docs', () => {
    it('GET /api/v1/health should return ok status', async () => {
      const res = await request(app).get('/api/v1/health');
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.status, 'ok');
      assert.strictEqual(res.body.service, 'Ballhub Tournament REST API');
    });

    it('GET /api/v1/docs should return OpenAPI 3.0 specification', async () => {
      const res = await request(app).get('/api/v1/docs');
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.openapi, '3.0.0');
      assert.ok(res.body.paths['/api/v1/tournaments']);
    });
  });

  // 2. Authentication & Authorization Tests
  describe('Auth & RBAC', () => {
    it('should return 401 Unauthorized when creating tournament without token', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .send({
          name: 'Unauthorized Tournament',
          location: 'Hanoi',
          startDate: new Date().toISOString(),
          endDate: new Date(Date.now() + 86400000).toISOString(),
          registrationDeadline: new Date().toISOString(),
          maxTeams: 4,
        });

      assert.strictEqual(res.status, 401);
      assert.strictEqual(res.body.success, false);
      assert.strictEqual(res.body.error.code, 'UNAUTHENTICATED');
    });

    it('should return 403 Forbidden when Viewer role attempts to create tournament', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_viewer_01')
        .set('x-user-role', 'viewer')
        .send({
          name: 'Viewer Tournament',
          location: 'Hanoi',
          startDate: new Date().toISOString(),
          endDate: new Date(Date.now() + 86400000).toISOString(),
          registrationDeadline: new Date().toISOString(),
          maxTeams: 4,
        });

      assert.strictEqual(res.status, 403);
      assert.strictEqual(res.body.success, false);
      assert.strictEqual(res.body.error.code, 'PERMISSION_DENIED');
    });
  });

  // 3. Tournament CRUD & Validation
  describe('Tournament Management', () => {
    it('should reject invalid tournament with maxTeams < 2 (Validation Error)', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          name: 'Invalid Cup',
          location: 'HCM',
          startDate: new Date().toISOString(),
          endDate: new Date(Date.now() + 86400000).toISOString(),
          registrationDeadline: new Date().toISOString(),
          maxTeams: 1, // Invalid!
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('should create tournament successfully by Organizer', async () => {
      const now = Date.now();
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .set('x-user-name', 'Nguyen Van Quan Ly')
        .send({
          name: 'Ballhub Championship 2026',
          description: 'Giai dau thu nghiem API-First',
          location: 'San van dong Thong Nhat',
          startDate: new Date(now + 86400000 * 3).toISOString(),
          endDate: new Date(now + 86400000 * 10).toISOString(),
          registrationDeadline: new Date(now + 86400000 * 2).toISOString(),
          maxTeams: 4,
          format: TournamentFormat.roundRobinSingle,
          status: TournamentStatus.registrationOpen,
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.id);
      assert.strictEqual(res.body.data.name, 'Ballhub Championship 2026');
      assert.strictEqual(res.body.data.organizerId, 'user_organizer_01');
      createdTournamentId = res.body.data.id;
    });

    it('GET /api/v1/tournaments/:id should return created tournament', async () => {
      const res = await request(app).get(`/api/v1/tournaments/${createdTournamentId}`);
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.id, createdTournamentId);
    });

    it('PATCH /api/v1/tournaments/:id should update tournament info', async () => {
      const res = await request(app)
        .patch(`/api/v1/tournaments/${createdTournamentId}`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          description: 'Mo ta da duoc cap nhat qua API',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.data.description, 'Mo ta da duoc cap nhat qua API');
    });
  });

  // 4. Team Registrations & Concurrency Check
  describe('Team Registrations', () => {
    it('should register Team 1 successfully by Captain', async () => {
      const res = await request(app)
        .post(`/api/v1/tournaments/${createdTournamentId}/registrations`)
        .set('x-user-id', 'user_captain_01')
        .set('x-user-role', 'teamCaptain')
        .set('x-user-name', 'Tran Doi Truong')
        .send({
          teamId: 'team_sao_vang',
          teamName: 'FC Sao Vàng',
          captainName: 'Trần Đội Trưởng',
          captainPhone: '0901234567',
          captainEmail: 'captain1@ballhub.vn',
          membersCount: 12,
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.teamId, 'team_sao_vang');
      assert.strictEqual(res.body.data.status, RegistrationStatus.pending);
      regTeam1Id = res.body.data.id;
    });

    it('should prevent duplicate registration of Team 1', async () => {
      const res = await request(app)
        .post(`/api/v1/tournaments/${createdTournamentId}/registrations`)
        .set('x-user-id', 'user_captain_01')
        .set('x-user-role', 'teamCaptain')
        .send({
          teamId: 'team_sao_vang',
          teamName: 'FC Sao Vàng Duplicate',
          captainName: 'Trần Đội Trưởng',
          captainPhone: '0901234567',
          captainEmail: 'captain1@ballhub.vn',
          membersCount: 12,
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'REGISTRATION_FAILED');
      assert.match(res.body.error.message, /đã đăng ký tham gia/);
    });

    it('should register Team 2 successfully', async () => {
      const res = await request(app)
        .post(`/api/v1/tournaments/${createdTournamentId}/registrations`)
        .set('x-user-id', 'user_captain_02')
        .set('x-user-role', 'teamCaptain')
        .send({
          teamId: 'team_rong_do',
          teamName: 'FC Rồng Đỏ',
          captainName: 'Lê Đội Trưởng',
          captainPhone: '0907654321',
          captainEmail: 'captain2@ballhub.vn',
          membersCount: 11,
        });

      assert.strictEqual(res.status, 201);
      regTeam2Id = res.body.data.id;
    });

    it('Organizer should approve Team 1 and Team 2', async () => {
      const res1 = await request(app)
        .patch(`/api/v1/tournaments/${createdTournamentId}/registrations/${regTeam1Id}`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({ status: RegistrationStatus.approved });
      assert.strictEqual(res1.status, 200);
      assert.strictEqual(res1.body.data.status, RegistrationStatus.approved);

      const res2 = await request(app)
        .patch(`/api/v1/tournaments/${createdTournamentId}/registrations/${regTeam2Id}`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({ status: RegistrationStatus.approved });
      assert.strictEqual(res2.status, 200);
      assert.strictEqual(res2.body.data.status, RegistrationStatus.approved);
    });
  });

  // 5. Schedule Generation
  describe('Schedule Generation', () => {
    it('should generate schedule for approved teams', async () => {
      const res = await request(app)
        .post(`/api/v1/tournaments/${createdTournamentId}/schedule`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({ venue: 'Sân vận động Thống Nhất' });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.length > 0);

      const firstMatch = res.body.data[0];
      generatedMatchId = firstMatch.id;
      assert.strictEqual(firstMatch.tournamentId, createdTournamentId);
      assert.strictEqual(firstMatch.homeTeamId, 'team_sao_vang');
      assert.strictEqual(firstMatch.awayTeamId, 'team_rong_do');
    });

    it('GET /api/v1/tournaments/:id/matches should list generated matches', async () => {
      const res = await request(app).get(`/api/v1/tournaments/${createdTournamentId}/matches`);
      assert.strictEqual(res.status, 200);
      assert.ok(res.body.data.length >= 1);
    });
  });

  // 6. Match Results & Standings Calculation
  describe('Match Results & Standings Auto-Calculation', () => {
    it('PUT /api/v1/matches/:matchId/result should update score and recompute standings', async () => {
      const res = await request(app)
        .put(`/api/v1/matches/${generatedMatchId}/result`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .set('x-user-name', 'Nguyen Van Quan Ly')
        .send({
          homeScore: 3,
          awayScore: 1,
          reason: 'Ket thuc 90 phut thi dau',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.homeScore, 3);
      assert.strictEqual(res.body.data.awayScore, 1);
      assert.strictEqual(res.body.data.isConfirmed, true);

      // Verify standings returned from the update
      const standings = res.body.standings;
      assert.ok(standings.length >= 2);

      const topTeam = standings[0];
      assert.strictEqual(topTeam.teamId, 'team_sao_vang');
      assert.strictEqual(topTeam.points, 3);
      assert.strictEqual(topTeam.played, 1);
      assert.strictEqual(topTeam.won, 1);
      assert.strictEqual(topTeam.goalsFor, 3);
      assert.strictEqual(topTeam.goalsAgainst, 1);
      assert.strictEqual(topTeam.goalDifference, 2);
      assert.strictEqual(topTeam.rank, 1);

      const secondTeam = standings[1];
      assert.strictEqual(secondTeam.teamId, 'team_rong_do');
      assert.strictEqual(secondTeam.points, 0);
      assert.strictEqual(secondTeam.lost, 1);
      assert.strictEqual(secondTeam.goalDifference, -2);
      assert.strictEqual(secondTeam.rank, 2);
    });

    it('GET /api/v1/tournaments/:id/standings should return the updated leaderboard', async () => {
      const res = await request(app).get(`/api/v1/tournaments/${createdTournamentId}/standings`);
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data[0].teamId, 'team_sao_vang');
      assert.strictEqual(res.body.data[0].points, 3);
    });

    it('GET /api/v1/tournaments/:id/audits should contain the score update audit entry', async () => {
      const res = await request(app)
        .get(`/api/v1/tournaments/${createdTournamentId}/audits`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer');

      assert.strictEqual(res.status, 200);
      assert.ok(res.body.data.length >= 1);
      const audit = res.body.data[0];
      assert.strictEqual(audit.matchId, generatedMatchId);
      assert.strictEqual(audit.newHomeScore, 3);
      assert.strictEqual(audit.newAwayScore, 1);
    });
  });

  // 7. Advanced Tournament Filters, Edge Cases & Security Validations
  describe('Tournament Filters, Edge Cases & Security Rules', () => {
    it('GET /api/v1/tournaments/:id should return 404 for unknown tournament', async () => {
      const res = await request(app).get('/api/v1/tournaments/unknown_tour_999');
      assert.strictEqual(res.status, 404);
      assert.strictEqual(res.body.success, false);
    });

    it('GET /api/v1/tournaments should filter by location', async () => {
      const res = await request(app)
        .get('/api/v1/tournaments')
        .query({ location: 'Thong Nhat' });
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.some((t: any) => t.id === createdTournamentId));
    });

    it('GET /api/v1/tournaments should filter by status', async () => {
      const res = await request(app)
        .get('/api/v1/tournaments')
        .query({ status: 'inProgress' });
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.ok(Array.isArray(res.body.data));
    });

    it('POST /api/v1/tournaments should reject tournament with empty name', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          name: '',
          location: 'San My Dinh',
          startDate: new Date(Date.now() + 86400000).toISOString(),
          endDate: new Date(Date.now() + 86400000 * 5).toISOString(),
          registrationDeadline: new Date().toISOString(),
          maxTeams: 8,
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('POST /api/v1/tournaments should reject tournament with endDate before startDate', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          name: 'Invalid Date Tournament',
          location: 'San My Dinh',
          startDate: new Date(Date.now() + 86400000 * 5).toISOString(),
          endDate: new Date(Date.now() + 86400000).toISOString(),
          registrationDeadline: new Date().toISOString(),
          maxTeams: 8,
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'BAD_REQUEST');
    });

    it('POST /api/v1/tournaments should reject tournament with registrationDeadline after startDate', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          name: 'Invalid Deadline Tournament',
          location: 'San My Dinh',
          startDate: new Date(Date.now() + 86400000).toISOString(),
          endDate: new Date(Date.now() + 86400000 * 5).toISOString(),
          registrationDeadline: new Date(Date.now() + 86400000 * 2).toISOString(),
          maxTeams: 8,
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'BAD_REQUEST');
    });

    it('POST /api/v1/tournaments should create knockout tournament successfully', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          name: 'Cúp Knockout Mở Rộng 2026',
          location: 'Hà Nội',
          startDate: new Date(Date.now() + 86400000 * 3).toISOString(),
          endDate: new Date(Date.now() + 86400000 * 10).toISOString(),
          registrationDeadline: new Date(Date.now() + 86400000 * 2).toISOString(),
          maxTeams: 16,
          format: TournamentFormat.knockout,
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.format, TournamentFormat.knockout);
    });

    it('PATCH /api/v1/tournaments/:id should reject update by non-organizer (403)', async () => {
      const res = await request(app)
        .patch(`/api/v1/tournaments/${createdTournamentId}`)
        .set('x-user-id', 'user_player_01')
        .set('x-user-role', 'player')
        .send({ name: 'Hacked Name' });

      assert.strictEqual(res.status, 403);
      assert.strictEqual(res.body.success, false);
      assert.strictEqual(res.body.error.code, 'PERMISSION_DENIED');
    });

    it('PATCH /api/v1/tournaments/:id should return 400 for unknown tournament', async () => {
      const res = await request(app)
        .patch('/api/v1/tournaments/unknown_999')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({ name: 'New Name' });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.success, false);
    });

    it('POST /api/v1/tournaments/:id/registrations should reject empty team name', async () => {
      const res = await request(app)
        .post(`/api/v1/tournaments/${createdTournamentId}/registrations`)
        .set('x-user-id', 'captain_invalid')
        .set('x-user-role', 'teamCaptain')
        .send({
          teamId: 'team_invalid',
          teamName: '',
          captainPhone: '0901234567',
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('POST /api/v1/tournaments/:id/registrations should return 400 for non-existent tournament', async () => {
      const res = await request(app)
        .post('/api/v1/tournaments/unknown_tour_888/registrations')
        .set('x-user-id', 'captain_01')
        .set('x-user-role', 'teamCaptain')
        .send({
          teamId: 'team_01',
          teamName: 'FC Alpha',
          captainPhone: '0901234567',
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.success, false);
    });

    it('PATCH /api/v1/registrations/:id/status should return 404 for unknown registration', async () => {
      const res = await request(app)
        .patch('/api/v1/registrations/reg_unknown_999/status')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({ status: 'approved' });

      assert.strictEqual(res.status, 404);
      assert.strictEqual(res.body.success, false);
    });

    it('PUT /api/v1/matches/:id/result should reject negative score', async () => {
      const res = await request(app)
        .put(`/api/v1/matches/${generatedMatchId}/result`)
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          homeScore: -1,
          awayScore: 2,
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.error.code, 'VALIDATION_ERROR');
    });

    it('PUT /api/v1/matches/:id/result should reject score update by non-organizer (403)', async () => {
      const res = await request(app)
        .put(`/api/v1/matches/${generatedMatchId}/result`)
        .set('x-user-id', 'user_captain_01')
        .set('x-user-role', 'teamCaptain')
        .send({
          homeScore: 2,
          awayScore: 2,
        });

      assert.strictEqual(res.status, 403);
      assert.strictEqual(res.body.error.code, 'PERMISSION_DENIED');
    });

    it('PUT /api/v1/matches/:id/result should return 400 for unknown match', async () => {
      const res = await request(app)
        .put('/api/v1/matches/match_unknown_999/result')
        .set('x-user-id', 'user_organizer_01')
        .set('x-user-role', 'organizer')
        .send({
          homeScore: 1,
          awayScore: 1,
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.success, false);
    });

    it('GET /api/v1/tournaments/:id/audits should return 401 for unauthenticated request', async () => {
      const res = await request(app)
        .get(`/api/v1/tournaments/${createdTournamentId}/audits`);

      assert.strictEqual(res.status, 401);
      assert.strictEqual(res.body.error.code, 'UNAUTHENTICATED');
    });
  });
});

describe('Booking Management', () => {
  let fieldId: string;
  let slotId: string;

  it('creates a field, an available slot, and prevents double booking', async () => {
    const field = await request(app)
      .post('/api/v1/fields')
      .set('x-user-id', 'owner_01')
      .set('x-user-role', 'fieldOwner')
      .send({
        name: 'San 5 nguoi A', address: '1 Nguyen Hue', city: 'Ho Chi Minh',
        fieldType: '5-a-side', capacity: 10, basePrice: 300000,
        status: 'active',
      });
    assert.strictEqual(field.status, 201);
    fieldId = field.body.data.id;

    const start = new Date(Date.now() + 86_400_000);
    start.setUTCHours(12, 0, 0, 0);
    const end = new Date(start.getTime() + 3_600_000);
    const slot = await request(app)
      .post(`/api/v1/fields/${fieldId}/slots`)
      .set('x-user-id', 'owner_01')
      .set('x-user-role', 'fieldOwner')
      .send({
        dateKey: start.toISOString().slice(0, 10), startsAt: start.toISOString(),
        endsAt: end.toISOString(), basePrice: 300000,
      });
    assert.strictEqual(slot.status, 201);
    assert.strictEqual(slot.body.data.status, FieldSlotStatus.available);
    slotId = slot.body.data.id;

    const firstBooking = await request(app)
      .post('/api/v1/bookings')
      .set('x-user-id', 'player_01')
      .set('x-user-role', 'player')
      .send({ fieldId, slotIds: [slotId] });
    assert.strictEqual(firstBooking.status, 201);
    assert.strictEqual(firstBooking.body.data.status, 'pending');
    assert.strictEqual(firstBooking.body.data.priceSnapshot, 300000);

    const duplicateBooking = await request(app)
      .post('/api/v1/bookings')
      .set('x-user-id', 'player_02')
      .set('x-user-role', 'player')
      .send({ fieldId, slotIds: [slotId] });
    assert.strictEqual(duplicateBooking.status, 409);
    assert.strictEqual(duplicateBooking.body.error.code, 'BOOKING_CONFLICT');
  });
});
