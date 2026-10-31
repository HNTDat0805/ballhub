import { TeamRepository } from '../repositories/team.repository';
import { UserRepository } from '../repositories/user.repository';
import { AuthUser, UserRole } from '../types/auth.types';
import {
  TeamEntity,
  TeamMemberEntity,
  JoinRequestEntity,
} from '../types/team.types';

export class TeamService {
  constructor(
    private teamRepo: TeamRepository = new TeamRepository(),
    private userRepo: UserRepository = new UserRepository()
  ) {}

  async create(
    data: { name: string; area?: string; description?: string },
    user: AuthUser
  ): Promise<TeamEntity> {
    const existing = await this.teamRepo.findByName(data.name);
    if (existing) {
      throw new Error('Tên đội bóng đã tồn tại trên hệ thống.');
    }

    const teamId = `team_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const now = new Date().toISOString();

    const userProfile = await this.userRepo.findById(user.uid);
    const captainName = user.name || userProfile?.fullName || 'Đội trưởng';

    const team: TeamEntity = {
      teamId,
      teamName: data.name.trim(),
      teamNameLower: data.name.trim().toLowerCase(),
      area: data.area?.trim() || '',
      description: data.description?.trim() || '',
      captainId: user.uid,
      captainName,
      memberCount: 1,
      createdAt: now,
      updatedAt: now,
    };

    await this.teamRepo.save(team);

    const captainMember: TeamMemberEntity = {
      id: `${teamId}_${user.uid}`,
      teamId,
      userId: user.uid,
      role: 'Captain',
      fullName: captainName,
      avatarBase64: userProfile?.avatarBase64 || null,
      position: userProfile?.position || 'Đội trưởng',
      joinedAt: now,
    };

    await this.teamRepo.addMember(captainMember);
    return team;
  }

  async list(filters?: { keyword?: string; area?: string }): Promise<TeamEntity[]> {
    return this.teamRepo.list(filters);
  }

  async getMyTeams(user: AuthUser): Promise<TeamEntity[]> {
    return this.teamRepo.listUserTeams(user.uid);
  }

  async getById(teamId: string): Promise<TeamEntity> {
    const team = await this.teamRepo.findById(teamId);
    if (!team) {
      throw new Error(`Không tìm thấy đội bóng với ID: ${teamId}`);
    }
    return team;
  }

  async update(
    teamId: string,
    data: { name?: string; area?: string; description?: string },
    user: AuthUser
  ): Promise<TeamEntity> {
    const team = await this.getById(teamId);

    const isCaptain = team.captainId === user.uid;
    const isAdmin = user.role === UserRole.admin;
    if (!isCaptain && !isAdmin) {
      throw new Error('Bạn không có quyền chỉnh sửa thông tin đội bóng này.');
    }

    if (data.name && data.name.trim().toLowerCase() !== team.teamNameLower) {
      const existing = await this.teamRepo.findByName(data.name, teamId);
      if (existing) {
        throw new Error('Tên đội bóng đã tồn tại trên hệ thống.');
      }
    }

    const updates: Partial<TeamEntity> = {
      updatedAt: new Date().toISOString(),
    };
    if (data.name) {
      updates.teamName = data.name.trim();
      updates.teamNameLower = data.name.trim().toLowerCase();
    }
    if (data.area !== undefined) updates.area = data.area.trim();
    if (data.description !== undefined) updates.description = data.description.trim();

    await this.teamRepo.update(teamId, updates);
    return { ...team, ...updates };
  }

  async deleteTeam(teamId: string, user: AuthUser): Promise<void> {
    const team = await this.teamRepo.findById(teamId);
    if (!team) return;
    const isCaptain = team.captainId === user.uid;
    const isAdmin = user.role === UserRole.admin;
    if (!isCaptain && !isAdmin) {
      throw new Error('Chỉ đội trưởng hoặc quản trị viên mới có quyền rã đội bóng này.');
    }
    await this.teamRepo.deleteTeam(teamId);
  }

  // ================= MEMBERS =================

  async getMembers(teamId: string): Promise<TeamMemberEntity[]> {
    const team = await this.teamRepo.findById(teamId);
    if (!team) return [];
    return this.teamRepo.listMembers(teamId);
  }

  async removeMember(teamId: string, targetUserId: string, user: AuthUser): Promise<void> {
    const team = await this.teamRepo.findById(teamId);
    if (!team) return;
    const isCaptain = team.captainId === user.uid;
    const isAdmin = user.role === UserRole.admin;
    const isSelf = user.uid === targetUserId;

    if (!isCaptain && !isAdmin && !isSelf) {
      throw new Error('Bạn không có quyền xóa thành viên này khỏi đội bóng.');
    }

    if (team.captainId === targetUserId && team.memberCount > 1) {
      throw new Error('Đội trưởng không thể rời đội khi chưa chuyển giao vai trò.');
    }

    const member = await this.teamRepo.findMember(teamId, targetUserId);
    if (!member) {
      if (isSelf) return;
      throw new Error('Thành viên không tồn tại trong đội bóng.');
    }

    await this.teamRepo.removeMember(teamId, targetUserId);
    await this.teamRepo.update(teamId, {
      memberCount: Math.max(0, team.memberCount - 1),
      updatedAt: new Date().toISOString(),
    });
  }

  // ================= JOIN REQUESTS =================

  async sendJoinRequest(
    teamId: string,
    message: string,
    user: AuthUser
  ): Promise<JoinRequestEntity> {
    await this.getById(teamId);

    const isMember = await this.teamRepo.findMember(teamId, user.uid);
    if (isMember) {
      throw new Error('Bạn đã là thành viên của đội bóng này.');
    }

    const existingPending = await this.teamRepo.findUserPendingRequest(teamId, user.uid);
    if (existingPending) {
      throw new Error('Bạn đã có yêu cầu gia nhập đang chờ xét duyệt.');
    }

    const userProfile = await this.userRepo.findById(user.uid);
    const fullName = user.name || userProfile?.fullName || 'Cầu thủ';
    const requestId = `${teamId}_${user.uid}`;
    const now = new Date().toISOString();

    const request: JoinRequestEntity = {
      requestId,
      teamId,
      userId: user.uid,
      message: message.trim() || 'Tôi muốn tham gia đội bóng!',
      status: 'Pending',
      fullName,
      avatarBase64: userProfile?.avatarBase64 || null,
      position: userProfile?.position || 'Cầu thủ',
      createdAt: now,
    };

    await this.teamRepo.saveJoinRequest(request);
    return request;
  }

  async listJoinRequests(teamId: string, user: AuthUser): Promise<JoinRequestEntity[]> {
    const team = await this.getById(teamId);
    const isCaptain = team.captainId === user.uid;
    const isAdmin = user.role === UserRole.admin;
    if (!isCaptain && !isAdmin) {
      throw new Error('Chỉ đội trưởng mới có quyền xem danh sách yêu cầu gia nhập.');
    }

    return this.teamRepo.listPendingRequests(teamId);
  }

  async updateJoinRequestStatus(
    teamId: string,
    requestId: string,
    status: 'Approved' | 'Rejected',
    user: AuthUser
  ): Promise<JoinRequestEntity> {
    const team = await this.getById(teamId);
    const isCaptain = team.captainId === user.uid;
    const isAdmin = user.role === UserRole.admin;
    if (!isCaptain && !isAdmin) {
      throw new Error('Chỉ đội trưởng mới có quyền xét duyệt yêu cầu gia nhập.');
    }

    const request = await this.teamRepo.findJoinRequest(requestId);
    if (!request) {
      throw new Error('Không tìm thấy yêu cầu gia nhập này.');
    }

    if (request.status !== 'Pending') {
      throw new Error(`Yêu cầu này đã được xử lý trước đó (${request.status}).`);
    }

    const now = new Date().toISOString();

    if (status === 'Approved') {
      const newMember: TeamMemberEntity = {
        id: `${teamId}_${request.userId}`,
        teamId,
        userId: request.userId,
        role: 'Member',
        fullName: request.fullName,
        avatarBase64: request.avatarBase64 || null,
        position: request.position || 'Cầu thủ',
        joinedAt: now,
      };
      await this.teamRepo.addMember(newMember);
      await this.teamRepo.update(teamId, {
        memberCount: team.memberCount + 1,
        updatedAt: now,
      });
    }

    const updates: Partial<JoinRequestEntity> = {
      status,
      reviewedAt: now,
      reviewedBy: user.uid,
    };

    await this.teamRepo.updateJoinRequest(requestId, updates);
    return { ...request, ...updates };
  }
}
