import { Request, Response, Router } from 'express';
import { requireAuth, requireRoles } from '../middleware/auth.middleware';
import { createFieldSchema, updateFieldSchema, validateBody } from '../middleware/validate.middleware';
import { FieldService } from '../services/field.service';
import { UserRole } from '../types/auth.types';

export const fieldRouter = Router();
const service = new FieldService();
const fieldId = (req: Request): string => Array.isArray(req.params.fieldId) ? req.params.fieldId[0] : req.params.fieldId;
const isOwnershipError = (msg: string) => msg.includes('không có quyền') || msg.includes('quyền quản lý');

fieldRouter.get('/', async (req: Request, res: Response) => {
  try {
    const fields = await service.list(req.query as Record<string, string | undefined>, req.user);
    res.json({ success: true, data: fields, count: fields.length });
  } catch (error: any) {
    res.status(500).json({ success: false, error: { code: 'FIELD_LIST_FAILED', message: error.message } });
  }
});

fieldRouter.get('/:fieldId', async (req: Request, res: Response) => {
  try {
    res.json({ success: true, data: await service.get(fieldId(req)) });
  } catch (error: any) {
    res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: error.message } });
  }
});

fieldRouter.post('/', requireAuth, requireRoles(UserRole.fieldOwner, UserRole.admin), validateBody(createFieldSchema), async (req, res) => {
  try {
    res.status(201).json({ success: true, data: await service.create(req.body, req.user!) });
  } catch (error: any) {
    res.status(400).json({ success: false, error: { code: 'FIELD_CREATE_FAILED', message: error.message } });
  }
});

fieldRouter.patch('/:fieldId', requireAuth, requireRoles(UserRole.fieldOwner, UserRole.admin), validateBody(updateFieldSchema), async (req, res) => {
  try {
    res.json({ success: true, data: await service.update(fieldId(req), req.body, req.user!) });
  } catch (error: any) {
    const status = isOwnershipError(error.message) ? 403 : 400;
    res.status(status).json({ success: false, error: { code: status === 403 ? 'FORBIDDEN' : 'FIELD_UPDATE_FAILED', message: error.message } });
  }
});

fieldRouter.patch('/:fieldId/status', requireAuth, requireRoles(UserRole.fieldOwner, UserRole.admin), validateBody(updateFieldSchema.pick({ status: true })), async (req, res) => {
  try {
    res.json({ success: true, data: await service.update(fieldId(req), { status: req.body.status }, req.user!) });
  } catch (error: any) {
    const status = isOwnershipError(error.message) ? 403 : 400;
    res.status(status).json({ success: false, error: { code: status === 403 ? 'FORBIDDEN' : 'FIELD_STATUS_FAILED', message: error.message } });
  }
});
