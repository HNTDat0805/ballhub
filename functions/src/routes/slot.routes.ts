import { Request, Response, Router } from 'express';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import { createSlotSchema, updateSlotSchema, validateBody } from '../middleware/validate.middleware';
import { SlotService } from '../services/slot.service';
import { UserRole } from '../types/auth.types';

export const slotRouter = Router();
const service = new SlotService();
const param = (req: Request, name: string): string => {
  const value = req.params[name];
  return Array.isArray(value) ? value[0] : value;
};
const fail = (res: Response, error: unknown, code: string) =>
  res.status(400).json({
    success: false,
    error: { code, message: error instanceof Error ? error.message : 'Không thể xử lý khung giờ.' },
  });

slotRouter.get('/fields/:fieldId/slots', async (req, res) => {
  try {
    const data = await service.list(
      param(req, 'fieldId'),
      typeof req.query.dateKey === 'string' ? req.query.dateKey : undefined,
    );
    res.json({ success: true, data });
  } catch (error) {
    fail(res, error, 'SLOT_LIST_FAILED');
  }
});

slotRouter.post(
  '/fields/:fieldId/slots',
  requireAuth,
  requireRoles(UserRole.fieldOwner, UserRole.admin),
  validateBody(createSlotSchema),
  async (req, res) => {
    try {
      res.status(201).json({ success: true, data: await service.create(param(req, 'fieldId'), req.body, req.user!) });
    } catch (error) {
      fail(res, error, 'SLOT_CREATE_FAILED');
    }
  },
);

slotRouter.patch(
  '/fields/:fieldId/slots/:slotId',
  requireAuth,
  requireRoles(UserRole.fieldOwner, UserRole.admin),
  validateBody(updateSlotSchema),
  async (req, res) => {
    try {
      res.json({
        success: true,
        data: await service.update(param(req, 'fieldId'), param(req, 'slotId'), req.body, req.user!),
      });
    } catch (error) {
      fail(res, error, 'SLOT_UPDATE_FAILED');
    }
  },
);

slotRouter.post(
  '/fields/:fieldId/slots/:slotId/block',
  requireAuth,
  requireRoles(UserRole.fieldOwner, UserRole.admin),
  async (req, res) => {
    try {
      const reason =
        typeof req.body?.reason === 'string' ? req.body.reason : 'Chủ sân khóa khung giờ.';
      res.json({
        success: true,
        data: await service.block(param(req, 'fieldId'), param(req, 'slotId'), reason, req.user!),
      });
    } catch (error) {
      fail(res, error, 'SLOT_BLOCK_FAILED');
    }
  },
);

slotRouter.post(
  '/fields/:fieldId/slots/:slotId/unblock',
  requireAuth,
  requireRoles(UserRole.fieldOwner, UserRole.admin),
  async (req, res) => {
    try {
      res.json({
        success: true,
        data: await service.unblock(param(req, 'fieldId'), param(req, 'slotId'), req.user!),
      });
    } catch (error) {
      fail(res, error, 'SLOT_UNBLOCK_FAILED');
    }
  },
);
