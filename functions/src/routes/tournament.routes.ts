import { Router, Request, Response } from 'express';
import { TournamentService } from '../services/tournament.service';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import { createTournamentSchema, updateTournamentSchema, validateBody } from '../middleware/validate.middleware';
import { UserRole } from '../types/auth.types';

export const tournamentRouter = Router();
const service = new TournamentService();

// POST /api/v1/tournaments
tournamentRouter.post(
  '/',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  validateBody(createTournamentSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const tournament = await service.create(req.body, req.user!);
      res.status(201).json({
        success: true,
        data: tournament,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: error.message },
      });
    }
  }
);

// GET /api/v1/tournaments
tournamentRouter.get('/', async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, search } = req.query;
    const tournaments = await service.list({
      status: status as string | undefined,
      search: search as string | undefined,
    });
    res.json({
      success: true,
      data: tournaments,
      count: tournaments.length,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: error.message },
    });
  }
});

// GET /api/v1/tournaments/:id
tournamentRouter.get('/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const tournament = await service.getById(req.params.id as string);
    res.json({
      success: true,
      data: tournament,
    });
  } catch (error: any) {
    res.status(404).json({
      success: false,
      error: { code: 'NOT_FOUND', message: error.message },
    });
  }
});

// PATCH /api/v1/tournaments/:id
tournamentRouter.patch(
  '/:id',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  validateBody(updateTournamentSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.update(req.params.id as string, req.body, req.user!);
      res.json({
        success: true,
        data: updated,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: error.message },
      });
    }
  }
);

// DELETE /api/v1/tournaments/:id
tournamentRouter.delete(
  '/:id',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  async (req: Request, res: Response): Promise<void> => {
    try {
      await service.delete(req.params.id as string, req.user!);
      res.json({
        success: true,
        message: 'Đã xóa giải đấu thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: error.message },
      });
    }
  }
);
