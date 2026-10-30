import { Router, Request, Response } from 'express';
import { MatchService } from '../services/match.service';
import { StandingsRepository } from '../repositories/standings.repository';
import { RegistrationRepository } from '../repositories/registration.repository';
import { MatchRepository } from '../repositories/match.repository';
import { StandingsService } from '../services/standings.service';
import { TournamentRepository } from '../repositories/tournament.repository';
import { RegistrationStatus } from '../types/tournament.types';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import { UserRole } from '../types/auth.types';

export const standingsRouter = Router();
const matchService = new MatchService();
const standingsRepo = new StandingsRepository();
const regRepo = new RegistrationRepository();
const matchRepo = new MatchRepository();
const tourRepo = new TournamentRepository();

// GET /api/v1/tournaments/:id/standings
standingsRouter.get(
  '/tournaments/:id/standings',
  async (req: Request, res: Response): Promise<void> => {
    try {
      const tId = req.params.id as string;
      let standings = await matchService.getStandings(tId);

      // If standings table is empty, compute and return on the fly
      if (standings.length === 0) {
        const approvedTeams = await regRepo.findByTournament(
          tId,
          RegistrationStatus.approved
        );
        const matches = await matchRepo.findByTournament(tId);
        if (approvedTeams.length > 0) {
          standings = StandingsService.compute(approvedTeams, matches);
          await standingsRepo.saveBatch(tId, standings);
        }
      }

      res.json({
        success: true,
        data: standings,
        count: standings.length,
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        error: { code: 'INTERNAL_ERROR', message: error.message },
      });
    }
  }
);

// POST /api/v1/tournaments/:id/standings/recalculate
standingsRouter.post(
  '/tournaments/:id/standings/recalculate',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const tId = req.params.id as string;

      // Anti-IDOR check: verify tournament existence and ownership
      const tournament = await tourRepo.findById(tId);
      if (!tournament) {
        res.status(404).json({
          success: false,
          error: { code: 'NOT_FOUND', message: `Không tìm thấy giải đấu: ${tId}` },
        });
        return;
      }

      if (req.user!.role !== UserRole.admin && tournament.organizerId !== req.user!.uid) {
        res.status(403).json({
          success: false,
          error: { code: 'FORBIDDEN', message: 'Bạn không có quyền tính lại bảng xếp hạng cho giải đấu này.' },
        });
        return;
      }

      const approvedTeams = await regRepo.findByTournament(
        tId,
        RegistrationStatus.approved
      );
      const matches = await matchRepo.findByTournament(tId);
      const standings = StandingsService.compute(approvedTeams, matches);
      await standingsRepo.saveBatch(tId, standings);

      res.json({
        success: true,
        data: standings,
        message: 'Bảng xếp hạng đã được tính toán lại thành công.',
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        error: { code: 'RECALCULATION_FAILED', message: error.message },
      });
    }
  }
);
