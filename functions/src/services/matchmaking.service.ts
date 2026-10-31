import { TeamRepository } from '../repositories/team.repository';
import { AuthUser, UserRole } from '../types/auth.types';
import { FriendlyInvitationEntity, TeamEntity } from '../types/team.types';

export class MatchmakingService {
  constructor(private teamRepo: TeamRepository = new TeamRepository()) {}

  /**
   * Đề xuất các đội bóng đối thủ tiềm năng dựa trên khu vực và loại trừ các đội mà user đang tham gia.
   */
  async findOpponents(
    user: AuthUser,
    options?: { area?: string; myTeamId?: string }
  ): Promise<{ team: TeamEntity; matchScore: number; reason: string }[]> {
    const allTeams = await this.teamRepo.list();
    const myTeams = await this.teamRepo.listUserTeams(user.uid);
    const myTeamIds = new Set(myTeams.map((t) => t.teamId));

    if (options?.myTeamId) {
      myTeamIds.add(options.myTeamId);
    }

    const targetArea = (
      options?.area ||
      (options?.myTeamId
        ? myTeams.find((t) => t.teamId === options.myTeamId)?.area
        : '') ||
      ''
    )
      .trim()
      .toLowerCase();

    const candidates = allTeams.filter((t) => !myTeamIds.has(t.teamId));

    const scored = candidates.map((team) => {
      let score = 50; // Điểm cơ bản
      let reason = 'Đội bóng đang hoạt động';

      const teamArea = team.area.toLowerCase();
      if (targetArea && teamArea && (teamArea.includes(targetArea) || targetArea.includes(teamArea))) {
        score += 40;
        reason = `Cùng khu vực (${team.area})`;
      } else if (team.area) {
        score += 10;
        reason = `Khu vực lân cận (${team.area})`;
      }

      if (team.memberCount >= 7) {
        score += 10;
      }

      return {
        team,
        matchScore: Math.min(100, score),
        reason,
      };
    });

    // Sắp xếp theo độ phù hợp cao nhất giảm dần
    scored.sort((a, b) => b.matchScore - a.matchScore);
    return scored;
  }

  /**
   * Gửi lời mời giao hữu / cáp kèo tới một đội bóng khác.
   */
  async sendInvitation(
    data: {
      fromTeamId?: string;
      toTeamId: string;
      message: string;
      proposedDate?: string;
      venue?: string;
    },
    user: AuthUser
  ): Promise<FriendlyInvitationEntity> {
    const toTeam = await this.teamRepo.findById(data.toTeamId);
    if (!toTeam) {
      throw new Error(`Không tìm thấy đội bóng đối thủ (ID: ${data.toTeamId}).`);
    }

    // Xác định đội bóng gửi lời mời của user
    let fromTeam: TeamEntity | null = null;
    if (data.fromTeamId) {
      fromTeam = await this.teamRepo.findById(data.fromTeamId);
    } else {
      const myTeams = await this.teamRepo.listUserTeams(user.uid);
      fromTeam = myTeams.find((t) => t.captainId === user.uid) || myTeams[0] || null;
    }

    if (!fromTeam) {
      throw new Error('Bạn cần phải tham gia hoặc sở hữu ít nhất một đội bóng để gửi lời mời giao hữu.');
    }

    if (fromTeam.teamId === toTeam.teamId) {
      throw new Error('Không thể gửi lời mời giao hữu cho chính đội của bạn.');
    }

    const isCaptain = fromTeam.captainId === user.uid;
    const isAdmin = user.role === UserRole.admin;
    if (!isCaptain && !isAdmin) {
      throw new Error('Chỉ đội trưởng mới có quyền đại diện gửi lời mời giao hữu.');
    }

    const invitationId = `inv_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const now = new Date().toISOString();

    const invitation: FriendlyInvitationEntity = {
      id: invitationId,
      fromTeamId: fromTeam.teamId,
      fromTeamName: fromTeam.teamName,
      fromCaptainId: fromTeam.captainId,
      fromCaptainName: fromTeam.captainName,
      toTeamId: toTeam.teamId,
      toTeamName: toTeam.teamName,
      toCaptainId: toTeam.captainId,
      toCaptainName: toTeam.captainName,
      message: data.message.trim(),
      proposedDate: data.proposedDate || null,
      venue: data.venue || null,
      status: 'Pending',
      createdAt: now,
      updatedAt: now,
    };

    await this.teamRepo.saveInvitation(invitation);
    return invitation;
  }

  /**
   * Lấy danh sách lời mời giao hữu (cả gửi đi và nhận về) của đội bóng.
   */
  async listInvitations(teamId: string, user: AuthUser): Promise<FriendlyInvitationEntity[]> {
    const team = await this.teamRepo.findById(teamId);
    if (!team) {
      throw new Error('Không tìm thấy đội bóng.');
    }

    const isMember = await this.teamRepo.findMember(teamId, user.uid);
    const isAdmin = user.role === UserRole.admin;
    if (!isMember && !isAdmin) {
      throw new Error('Bạn không có quyền xem lời mời của đội bóng này.');
    }

    return this.teamRepo.listInvitations(teamId);
  }

  /**
   * Phản hồi lời mời giao hữu (Chấp nhận, Từ chối hoặc Hủy).
   */
  async updateInvitationStatus(
    invitationId: string,
    status: 'Accepted' | 'Declined' | 'Cancelled',
    user: AuthUser
  ): Promise<FriendlyInvitationEntity> {
    const inv = await this.teamRepo.findInvitation(invitationId);
    if (!inv) {
      throw new Error('Không tìm thấy lời mời giao hữu này.');
    }

    if (inv.status !== 'Pending') {
      throw new Error(`Lời mời này đã được xử lý trước đó (${inv.status}).`);
    }

    const isAdmin = user.role === UserRole.admin;

    if (status === 'Accepted' || status === 'Declined') {
      const isTargetCaptain = inv.toCaptainId === user.uid;
      if (!isTargetCaptain && !isAdmin) {
        throw new Error('Chỉ đội trưởng đội nhận lời mời mới có quyền chấp nhận hoặc từ chối.');
      }
    } else if (status === 'Cancelled') {
      const isSenderCaptain = inv.fromCaptainId === user.uid;
      if (!isSenderCaptain && !isAdmin) {
        throw new Error('Chỉ đội trưởng đội gửi lời mời mới có quyền hủy lời mời.');
      }
    }

    const updates: Partial<FriendlyInvitationEntity> = {
      status,
      updatedAt: new Date().toISOString(),
    };

    await this.teamRepo.updateInvitation(invitationId, updates);
    return { ...inv, ...updates };
  }
}
