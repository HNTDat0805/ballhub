import { TournamentRepository } from '../repositories/tournament.repository';
import { TournamentEntity, TournamentFormat, TournamentStatus } from '../types/tournament.types';
import { AuthUser, UserRole } from '../types/auth.types';

/**
 * Dịch vụ nghiệp vụ quản lý vòng đời giải đấu (Tournament Service).
 *
 * Đảm bảo:
 * 1. Xác thực khoảng thời gian hợp lệ (ngày kết thúc > ngày bắt đầu, hạn đăng ký <= ngày bắt đầu).
 * 2. Phân quyền: chỉ người tạo giải (Organizer) hoặc Quản trị viên (Admin) mới có quyền sửa/xóa giải.
 * 3. Ngăn chặn chỉnh sửa thông số cốt lõi hoặc xóa giải khi các trận đấu đã diễn ra.
 */
export class TournamentService {
  constructor(private repo: TournamentRepository = new TournamentRepository()) {}

  async create(
    data: {
      name: string;
      description?: string;
      bannerUrl?: string;
      location: string;
      startDate: string;
      endDate: string;
      registrationDeadline: string;
      maxTeams: number;
      format: TournamentFormat;
      status: TournamentStatus;
    },
    user: AuthUser
  ): Promise<TournamentEntity> {
    const now = new Date().toISOString();
    const start = new Date(data.startDate);
    const end = new Date(data.endDate);
    const deadline = new Date(data.registrationDeadline);

    if (end.getTime() < start.getTime()) {
      throw new Error('Thời gian kết thúc giải đấu phải sau thời gian bắt đầu.');
    }

    if (deadline.getTime() > start.getTime()) {
      throw new Error('Hạn chót đăng ký phải trước hoặc bằng ngày bắt đầu giải đấu.');
    }

    const id = `tour_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const tournament: TournamentEntity = {
      id,
      name: data.name,
      description: data.description || '',
      bannerUrl: data.bannerUrl || '',
      location: data.location,
      startDate: data.startDate,
      endDate: data.endDate,
      registrationDeadline: data.registrationDeadline,
      maxTeams: data.maxTeams,
      format: data.format,
      status: data.status,
      organizerId: user.uid,
      organizerName: user.name || 'Ban Tổ Chức',
      createdAt: now,
      updatedAt: now,
    };

    await this.repo.save(tournament);
    return tournament;
  }

  async getById(id: string): Promise<TournamentEntity> {
    const t = await this.repo.findById(id);
    if (!t) {
      throw new Error(`Không tìm thấy giải đấu với ID: ${id}`);
    }
    return t;
  }

  async list(filters?: { status?: string; search?: string }): Promise<TournamentEntity[]> {
    return this.repo.findAll(filters);
  }

  async update(
    id: string,
    data: Partial<TournamentEntity>,
    user: AuthUser
  ): Promise<TournamentEntity> {
    const existing = await this.getById(id);

    // Permission check
    if (user.role !== UserRole.admin && existing.organizerId !== user.uid) {
      throw new Error('Bạn không có quyền chỉnh sửa giải đấu này.');
    }

    // Business rule: if tournament is inProgress or completed, cannot change maxTeams or format
    if (existing.status === TournamentStatus.inProgress || existing.status === TournamentStatus.completed) {
      if (data.maxTeams && data.maxTeams !== existing.maxTeams) {
        throw new Error('Không thể thay đổi số lượng đội tối đa khi giải đấu đã bắt đầu hoặc đã kết thúc.');
      }
      if (data.format && data.format !== existing.format) {
        throw new Error('Không thể thay đổi thể thức thi đấu khi giải đấu đang diễn ra hoặc đã kết thúc.');
      }
    }

    const updatedData = {
      ...data,
      updatedAt: new Date().toISOString(),
    };

    await this.repo.update(id, updatedData);
    return { ...existing, ...updatedData };
  }

  async delete(id: string, user: AuthUser): Promise<void> {
    const existing = await this.getById(id);

    if (user.role !== UserRole.admin && existing.organizerId !== user.uid) {
      throw new Error('Bạn không có quyền xóa giải đấu này.');
    }

    // Cannot delete if tournament is inProgress or completed (should cancel instead)
    if (existing.status === TournamentStatus.inProgress) {
      throw new Error('Không thể xóa giải đấu đang diễn ra. Vui lòng chuyển trạng thái sang "Đã hủy" (cancelled).');
    }

    await this.repo.delete(id);
  }
}
