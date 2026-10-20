import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { RegistrationRepository } from '../repositories/registration.repository';
import { TournamentRepository } from '../repositories/tournament.repository';
import { RegistrationStatus, TournamentRegistrationEntity, TournamentStatus } from '../types/tournament.types';
import { AuthUser, UserRole } from '../types/auth.types';

export class RegistrationService {
  constructor(
    private regRepo: RegistrationRepository = new RegistrationRepository(),
    private tourRepo: TournamentRepository = new TournamentRepository()
  ) {}

  async register(
    tournamentId: string,
    data: {
      teamId: string;
      teamName: string;
      logoUrl?: string;
      captainId?: string;
      captainName: string;
      captainPhone: string;
      captainEmail: string;
      membersCount: number;
    },
    user: AuthUser
  ): Promise<TournamentRegistrationEntity> {
    const tournament = await this.tourRepo.findById(tournamentId);
    if (!tournament) {
      throw new Error(`Không tìm thấy giải đấu với ID: ${tournamentId}`);
    }

    if (tournament.status !== TournamentStatus.registrationOpen) {
      throw new Error(`Giải đấu hiện không mở đăng ký (trạng thái: ${tournament.status}).`);
    }

    const now = new Date();
    if (now.getTime() > new Date(tournament.registrationDeadline).getTime()) {
      throw new Error('Đã hết hạn đăng ký tham gia giải đấu.');
    }

    // Check duplicate registration
    const existing = await this.regRepo.findByTeamId(tournamentId, data.teamId);
    if (existing && existing.status !== RegistrationStatus.cancelled && existing.status !== RegistrationStatus.rejected) {
      throw new Error(`Đội bóng "${data.teamName}" đã đăng ký tham gia giải đấu này rồi.`);
    }

    const isOrganizer = user.role === UserRole.admin || user.uid === tournament.organizerId;
    const initialStatus = isOrganizer ? RegistrationStatus.approved : RegistrationStatus.pending;

    const regId = existing ? existing.id : `reg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const registration: TournamentRegistrationEntity = {
      id: regId,
      tournamentId,
      teamId: data.teamId,
      teamName: data.teamName,
      logoUrl: data.logoUrl || '',
      captainId: data.captainId || user.uid,
      captainName: data.captainName,
      captainPhone: data.captainPhone,
      captainEmail: data.captainEmail,
      membersCount: data.membersCount,
      status: initialStatus,
      registeredAt: now.toISOString(),
      reviewedAt: isOrganizer ? now.toISOString() : null,
      reviewedBy: isOrganizer ? (user.name || user.uid) : null,
    };

    // Use Transaction when connected to Firestore, or atomic memory check when in memory mode
    if (MemoryStore.isMemoryMode()) {
      if (initialStatus === RegistrationStatus.approved) {
        const approvedCount = await this.regRepo.countApproved(tournamentId);
        if (approvedCount >= tournament.maxTeams) {
          throw new Error(`Giải đấu đã đạt giới hạn tối đa ${tournament.maxTeams} đội bóng.`);
        }
      }
      await this.regRepo.save(registration);
    } else {
      await db.runTransaction(async (transaction) => {
        if (initialStatus === RegistrationStatus.approved) {
          const approvedCount = await this.regRepo.countApproved(tournamentId, transaction);
          if (approvedCount >= tournament.maxTeams) {
            throw new Error(`Giải đấu đã đạt giới hạn tối đa ${tournament.maxTeams} đội bóng.`);
          }
        }

        const docRef = db.collection('tournaments').doc(tournamentId).collection('registrations').doc(regId);
        transaction.set(docRef, registration);
      });
    }

    return registration;
  }

  async list(
    tournamentId: string,
    status?: RegistrationStatus
  ): Promise<TournamentRegistrationEntity[]> {
    return this.regRepo.findByTournament(tournamentId, status);
  }

  async updateStatus(
    tournamentId: string,
    registrationId: string,
    newStatus: RegistrationStatus,
    reviewNote?: string,
    user?: AuthUser
  ): Promise<TournamentRegistrationEntity> {
    const tournament = await this.tourRepo.findById(tournamentId);
    if (!tournament) throw new Error('Không tìm thấy giải đấu.');

    if (user && user.role !== UserRole.admin && tournament.organizerId !== user.uid) {
      throw new Error('Chỉ ban tổ chức giải đấu hoặc admin mới có quyền duyệt đội bóng.');
    }

    const registration = await this.regRepo.findById(tournamentId, registrationId);
    if (!registration) throw new Error('Không tìm thấy thông tin đăng ký đội.');

    // Concurrency control: if approving, check that capacity is not exceeded
    if (MemoryStore.isMemoryMode()) {
      if (newStatus === RegistrationStatus.approved && registration.status !== RegistrationStatus.approved) {
        const approvedCount = await this.regRepo.countApproved(tournamentId);
        if (approvedCount >= tournament.maxTeams) {
          throw new Error(`Giải đấu đã đủ số lượng tối đa ${tournament.maxTeams} đội bóng được duyệt.`);
        }
      }

      await this.regRepo.update(tournamentId, registrationId, {
        status: newStatus,
        reviewedAt: new Date().toISOString(),
        reviewedBy: user?.name || user?.uid || 'BTC',
        reviewNote: reviewNote || null,
      });
    } else {
      await db.runTransaction(async (transaction) => {
        if (newStatus === RegistrationStatus.approved && registration.status !== RegistrationStatus.approved) {
          const approvedCount = await this.regRepo.countApproved(tournamentId, transaction);
          if (approvedCount >= tournament.maxTeams) {
            throw new Error(`Giải đấu đã đủ số lượng tối đa ${tournament.maxTeams} đội bóng được duyệt.`);
          }
        }

        const docRef = db.collection('tournaments').doc(tournamentId).collection('registrations').doc(registrationId);
        const updateData: Partial<TournamentRegistrationEntity> = {
          status: newStatus,
          reviewedAt: new Date().toISOString(),
          reviewedBy: user?.name || user?.uid || 'BTC',
          reviewNote: reviewNote || null,
        };
        transaction.update(docRef, updateData);
      });
    }

    return {
      ...registration,
      status: newStatus,
      reviewedAt: new Date().toISOString(),
      reviewedBy: user?.name || user?.uid || 'BTC',
      reviewNote: reviewNote || null,
    };
  }

  async cancel(
    tournamentId: string,
    registrationId: string,
    user: AuthUser
  ): Promise<void> {
    const tournament = await this.tourRepo.findById(tournamentId);
    if (!tournament) throw new Error('Không tìm thấy giải đấu.');

    const registration = await this.regRepo.findById(tournamentId, registrationId);
    if (!registration) throw new Error('Không tìm thấy thông tin đăng ký đội.');

    // Only team captain or organizer/admin can cancel
    const isCaptain = registration.captainId === user.uid;
    const isOrganizer = user.role === UserRole.admin || tournament.organizerId === user.uid;
    if (!isCaptain && !isOrganizer) {
      throw new Error('Bạn không có quyền hủy đăng ký của đội bóng này.');
    }

    if (tournament.status === TournamentStatus.inProgress || tournament.status === TournamentStatus.completed) {
      throw new Error('Không thể hủy đăng ký khi giải đấu đã diễn ra hoặc kết thúc.');
    }

    await this.regRepo.update(tournamentId, registrationId, {
      status: RegistrationStatus.cancelled,
      reviewNote: `Hủy bởi ${user.name || user.uid}`,
    });
  }
}
