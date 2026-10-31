import { Router, Request, Response } from 'express';
import { UserService } from '../services/user.service';
import { requireAuth } from '../middleware/auth.middleware';
import {
  updateUserProfileSchema,
  updateUserAvatarSchema,
  validateBody,
} from '../middleware/validate.middleware';

export const userRouter = Router();
const service = new UserService();

// GET /api/v1/users/me - Lấy thông tin hồ sơ của người dùng hiện tại
userRouter.get('/me', requireAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const profile = await service.getProfile(req.user!);
    res.json({
      success: true,
      data: profile,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: error.message },
    });
  }
});

// PATCH /api/v1/users/me - Cập nhật thông tin cá nhân
userRouter.patch(
  '/me',
  requireAuth,
  validateBody(updateUserProfileSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.updateProfile(req.body, req.user!);
      res.json({
        success: true,
        data: updated,
        message: 'Cập nhật hồ sơ thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'UPDATE_PROFILE_FAILED', message: error.message },
      });
    }
  }
);

// POST /api/v1/users/me/avatar - Cập nhật ảnh đại diện Base64
userRouter.post(
  '/me/avatar',
  requireAuth,
  validateBody(updateUserAvatarSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.updateAvatar(req.body.avatarBase64, req.user!);
      res.json({
        success: true,
        data: updated,
        message: 'Cập nhật ảnh đại diện thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'UPDATE_AVATAR_FAILED', message: error.message },
      });
    }
  }
);
