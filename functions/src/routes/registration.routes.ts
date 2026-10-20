import { Router, Request, Response } from 'express';
import { RegistrationService } from '../services/registration.service';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import { registerTeamSchema, updateRegistrationStatusSchema, validateBody } from '../middleware/validate.middleware';
import { UserRole } from '../types/auth.types';
import { RegistrationStatus } from '../types/tournament.types';

export const registrationRouter = Router({ mergeParams: true });
const service = new RegistrationService();

// POST /api/v1/tournaments/:id/registrations
registrationRouter.post(
  '/:id/registrations',
  requireAuth,
  requireRoles(UserRole.teamCaptain, UserRole.organizer, UserRole.admin),
  validateBody(registerTeamSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const reg = await service.register(req.params.id as string, req.body, req.user!);
      res.status(201).json({
        success: true,
        data: reg,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'REGISTRATION_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/tournaments/:id/registrations
registrationRouter.get(
  '/:id/registrations',
  async (req: Request, res: Response): Promise<void> => {
    try {
      const { status } = req.query;
      const list = await service.list(
        req.params.id as string,
        status as RegistrationStatus | undefined
      );
      res.json({
        success: true,
        data: list,
        count: list.length,
      });
    } catch (error: any) {
      res.status(500).json({
        success: false,
        error: { code: 'INTERNAL_ERROR', message: error.message },
      });
    }
  }
);

// PATCH /api/v1/tournaments/:id/registrations/:registrationId
registrationRouter.patch(
  '/:id/registrations/:registrationId',
  requireAuth,
  requireRoles(UserRole.organizer, UserRole.admin),
  validateBody(updateRegistrationStatusSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.updateStatus(
        req.params.id as string,
        req.params.registrationId as string,
        req.body.status,
        req.body.reviewNote,
        req.user!
      );
      res.json({
        success: true,
        data: updated,
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'UPDATE_STATUS_FAILED', message: error.message },
      });
    }
  }
);

// DELETE /api/v1/tournaments/:id/registrations/:registrationId
registrationRouter.delete(
  '/:id/registrations/:registrationId',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      await service.cancel(req.params.id as string, req.params.registrationId as string, req.user!);
      res.json({
        success: true,
        message: 'Đã hủy đăng ký thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'CANCEL_FAILED', message: error.message },
      });
    }
  }
);
