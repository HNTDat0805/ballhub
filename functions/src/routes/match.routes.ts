import { Router, Request, Response } from 'express';
import { MatchService } from '../services/match.service';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import {
  generateScheduleSchema,
  updateMatchDetailsSchema,
  updateMatchResultSchema,
  validateBody,
} from '../middleware/validate.middleware';
import { UserRole } from '../types/auth.types';
import { MatchStatus } from '../types/tournament.types';

export const matchRouter = Router();
const service = new MatchService();

// POST /api/v1/tournaments/:id/schedule
matchRouter.post(
  '/tournaments/:id/schedule',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  validateBody(generateScheduleSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const matches = await service.generateSchedule(
        req.params.id as string,
        req.body.venue || 'Sân vận động chính',
        req.user!
      );
      res.status(201).json({
        success: true,
        data: matches,
        count: matches.length,
        message: 'Lịch thi đấu đã được tạo tự động thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'SCHEDULE_GENERATION_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/tournaments/:id/matches
matchRouter.get(
  '/tournaments/:id/matches',
  async (req: Request, res: Response): Promise<void> => {
    try {
      const { round, status, teamId } = req.query;
      const matches = await service.listMatches(req.params.id as string, {
        round: round ? parseInt(round as string, 10) : undefined,
        status: status as MatchStatus | undefined,
        teamId: teamId as string | undefined,
      });
      res.json({
        success: true,
        data: matches,
        count: matches.length,
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        error: { code: 'INTERNAL_ERROR', message: error.message },
      });
    }
  }
);

// GET /api/v1/matches/:matchId
matchRouter.get('/matches/:matchId', async (req: Request, res: Response): Promise<void> => {
  try {
    const result = await service.getGlobalMatch(req.params.matchId as string);
    res.json({
      success: true,
      data: result.match,
      tournamentId: result.tournamentId,
    });
  } catch (error: any) {
    res.status(404).json({
      success: false,
      error: { code: 'NOT_FOUND', message: error.message },
    });
  }
});

// PATCH /api/v1/matches/:matchId
matchRouter.patch(
  '/matches/:matchId',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  validateBody(updateMatchDetailsSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const { tournamentId } = await service.getGlobalMatch(req.params.matchId as string);
      const updated = await service.updateMatchDetails(
        tournamentId,
        req.params.matchId as string,
        req.body,
        req.user!
      );
      res.json({
        success: true,
        data: updated,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'UPDATE_MATCH_FAILED', message: error.message },
      });
    }
  }
);

// PUT /api/v1/matches/:matchId/result
matchRouter.put(
  '/matches/:matchId/result',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  validateBody(updateMatchResultSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const { tournamentId } = await service.getGlobalMatch(req.params.matchId as string);
      const result = await service.updateMatchResult(
        tournamentId,
        req.params.matchId as string,
        req.body,
        req.user!
      );
      res.json({
        success: true,
        data: result.match,
        standings: result.standings,
        message: 'Cập nhật tỷ số trận đấu và tự động tính lại bảng xếp hạng thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'UPDATE_RESULT_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/tournaments/:id/audits
matchRouter.get(
  '/tournaments/:id/audits',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const audits = await service.getAudits(req.params.id as string);
      res.json({
        success: true,
        data: audits,
        count: audits.length,
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        error: { code: 'INTERNAL_ERROR', message: error.message },
      });
    }
  }
);
