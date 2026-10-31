import { describe, it } from 'node:test';
import assert from 'node:assert';
import request from 'supertest';
import { app } from '../src/app';

describe('Team & Matchmaking REST API Test Suite', () => {
  let createdTeamId: string;
  let opponentTeamId: string;
  let joinRequestId: string;
  let invitationId: string;

  const captain1 = {
    id: 'user_captain_01',
    role: 'teamCaptain',
    name: 'Nguyễn Văn Đội Trưởng',
  };

  const captain2 = {
    id: 'user_captain_02',
    role: 'teamCaptain',
    name: 'Trần Văn Đội Phó',
  };

  const player1 = {
    id: 'user_player_01',
    role: 'player',
    name: 'Lê Văn Cầu Thủ',
  };

  describe('1. Team Management & CRUD', () => {
    it('POST /api/v1/teams should create team by Captain', async () => {
      const res = await request(app)
        .post('/api/v1/teams')
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role)
        .set('x-user-name', encodeURIComponent(captain1.name))
        .send({
          name: 'CLB Sao Vàng FC',
          area: 'Bình Thạnh, TP. Hồ Chí Minh',
          description: 'Đội bóng phong trào nhiệt huyết',
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.teamName, 'CLB Sao Vàng FC');
      assert.strictEqual(res.body.data.captainId, captain1.id);
      assert.strictEqual(res.body.data.memberCount, 1);
      createdTeamId = res.body.data.teamId;
    });

    it('POST /api/v1/teams should prevent duplicate team name', async () => {
      const res = await request(app)
        .post('/api/v1/teams')
        .set('x-user-id', captain2.id)
        .set('x-user-role', captain2.role)
        .send({
          name: 'CLB Sao Vàng FC',
          area: 'Quận 1',
        });

      assert.strictEqual(res.status, 400);
      assert.strictEqual(res.body.success, false);
      assert.strictEqual(res.body.error.code, 'CREATE_TEAM_FAILED');
    });

    it('POST /api/v1/teams should create second team for matchmaking test', async () => {
      const res = await request(app)
        .post('/api/v1/teams')
        .set('x-user-id', captain2.id)
        .set('x-user-role', captain2.role)
        .set('x-user-name', encodeURIComponent(captain2.name))
        .send({
          name: 'CLB Rồng Bay FC',
          area: 'Bình Thạnh, TP. Hồ Chí Minh',
          description: 'Đội bóng giao lưu vui khỏe',
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      opponentTeamId = res.body.data.teamId;
    });

    it('GET /api/v1/teams should list teams and filter by keyword/area', async () => {
      const res = await request(app)
        .get('/api/v1/teams')
        .query({ keyword: 'Sao Vàng', area: 'Bình Thạnh' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.length >= 1);
      assert.strictEqual(res.body.data[0].teamName, 'CLB Sao Vàng FC');
    });

    it('GET /api/v1/teams/mine should return current user teams', async () => {
      const res = await request(app)
        .get('/api/v1/teams/mine')
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role);

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.some((t: any) => t.teamId === createdTeamId));
    });

    it('PATCH /api/v1/teams/:id should update team details by Captain', async () => {
      const res = await request(app)
        .patch(`/api/v1/teams/${createdTeamId}`)
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role)
        .send({
          description: 'Cập nhật bio đội bóng mới',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.description, 'Cập nhật bio đội bóng mới');
    });
  });

  describe('2. Team Members & Join Requests', () => {
    it('GET /api/v1/teams/:id/members should return team captain as first member', async () => {
      const res = await request(app).get(`/api/v1/teams/${createdTeamId}/members`);
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.length, 1);
      assert.strictEqual(res.body.data[0].role, 'Captain');
    });

    it('POST /api/v1/teams/:id/join-requests should allow Player to request joining team', async () => {
      const res = await request(app)
        .post(`/api/v1/teams/${createdTeamId}/join-requests`)
        .set('x-user-id', player1.id)
        .set('x-user-role', player1.role)
        .set('x-user-name', encodeURIComponent(player1.name))
        .send({
          message: 'Tôi đá tiền đạo, xin gia nhập đội!',
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.status, 'Pending');
      joinRequestId = res.body.data.requestId;
    });

    it('GET /api/v1/teams/:id/join-requests should allow Captain to see requests', async () => {
      const res = await request(app)
        .get(`/api/v1/teams/${createdTeamId}/join-requests`)
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role);

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.length, 1);
    });

    it('PATCH /api/v1/teams/:id/join-requests/:reqId should approve member', async () => {
      const res = await request(app)
        .patch(`/api/v1/teams/${createdTeamId}/join-requests/${joinRequestId}`)
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role)
        .send({
          status: 'Approved',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.status, 'Approved');

      // Kiểm tra lại danh sách thành viên phải tăng lên 2
      const membersRes = await request(app).get(`/api/v1/teams/${createdTeamId}/members`);
      assert.strictEqual(membersRes.body.data.length, 2);
    });
  });

  describe('3. Matchmaking & Friendly Invitations', () => {
    it('GET /api/v1/matchmaking/opponents should suggest matching teams in same area', async () => {
      const res = await request(app)
        .get('/api/v1/matchmaking/opponents')
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role)
        .query({ myTeamId: createdTeamId, area: 'Bình Thạnh' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.length >= 1);
      assert.strictEqual(res.body.data[0].team.teamId, opponentTeamId);
      assert.ok(res.body.data[0].matchScore >= 90);
    });

    it('POST /api/v1/invitations should send friendly match invitation', async () => {
      const res = await request(app)
        .post('/api/v1/invitations')
        .set('x-user-id', captain1.id)
        .set('x-user-role', captain1.role)
        .send({
          fromTeamId: createdTeamId,
          toTeamId: opponentTeamId,
          message: 'Tối Chủ Nhật đá giao hữu sân 7 người, cưa đôi tiền sân nhé!',
          venue: 'Sân bóng Thống Nhất',
        });

      assert.strictEqual(res.status, 201);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.status, 'Pending');
      assert.strictEqual(res.body.data.toTeamId, opponentTeamId);
      invitationId = res.body.data.id;
    });

    it('GET /api/v1/invitations should return invitations for the opponent team', async () => {
      const res = await request(app)
        .get('/api/v1/invitations')
        .set('x-user-id', captain2.id)
        .set('x-user-role', captain2.role)
        .query({ teamId: opponentTeamId });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.length, 1);
      assert.strictEqual(res.body.data[0].id, invitationId);
    });

    it('PATCH /api/v1/invitations/:id should allow target captain to accept invitation', async () => {
      const res = await request(app)
        .patch(`/api/v1/invitations/${invitationId}`)
        .set('x-user-id', captain2.id)
        .set('x-user-role', captain2.role)
        .send({ status: 'Accepted' });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.status, 'Accepted');
    });
  });

  describe('4. User Profile & Avatar Management', () => {
    it('GET /api/v1/users/me should return user profile', async () => {
      const res = await request(app)
        .get('/api/v1/users/me')
        .set('x-user-id', player1.id)
        .set('x-user-role', player1.role)
        .set('x-user-name', encodeURIComponent(player1.name));

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.userId, player1.id);
    });

    it('PATCH /api/v1/users/me should update profile info', async () => {
      const res = await request(app)
        .patch('/api/v1/users/me')
        .set('x-user-id', player1.id)
        .set('x-user-role', player1.role)
        .send({
          fullName: 'Lê Văn Cầu Thủ Pro',
          phone: '0901234567',
          position: 'Tiền đạo cánh',
          area: 'Bình Thạnh, TP. Hồ Chí Minh',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.strictEqual(res.body.data.fullName, 'Lê Văn Cầu Thủ Pro');
      assert.strictEqual(res.body.data.position, 'Tiền đạo cánh');
    });

    it('POST /api/v1/users/me/avatar should update avatar base64', async () => {
      const res = await request(app)
        .post('/api/v1/users/me/avatar')
        .set('x-user-id', player1.id)
        .set('x-user-role', player1.role)
        .send({
          avatarBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.body.success, true);
      assert.ok(res.body.data.avatarBase64);
    });
  });
});
