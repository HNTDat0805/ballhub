import { Router, Request, Response } from 'express';
import { MatchmakingService } from '../services/matchmaking.service';
import { requireAuth } from '../middleware/auth.middleware';
import {
  createFriendlyInvitationSchema,
  updateInvitationStatusSchema,
  validateBody,
} from '../middleware/validate.middleware';

export const matchmakingRouter = Router();
const service = new MatchmakingService();

// GET /api/v1/matchmaking/opponents - Tìm đối thủ phù hợp theo khu vực/trình độ
matchmakingRouter.get('/opponents', requireAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { area, myTeamId } = req.query;
    const candidates = await service.findOpponents(req.user!, {
      area: area as string | undefined,
      myTeamId: myTeamId as string | undefined,
    });
    res.json({
      success: true,
      data: candidates,
      count: candidates.length,
      message: 'Đã tìm thấy các đối thủ phù hợp cho đội của bạn.',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: { code: 'MATCHMAKING_FAILED', message: error.message },
    });
  }
});

export const invitationRouter = Router();

// POST /api/v1/invitations - Gửi lời mời giao hữu
invitationRouter.post(
  '/',
  requireAuth,
  validateBody(createFriendlyInvitationSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const invitation = await service.sendInvitation(req.body, req.user!);
      res.status(201).json({
        success: true,
        data: invitation,
        message: 'Đã gửi lời mời giao hữu thành công tới đội đối thủ.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'SEND_INVITATION_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/invitations - Danh sách lời mời giao hữu của đội bóng
invitationRouter.get('/', requireAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { teamId } = req.query;
    if (!teamId || typeof teamId !== 'string') {
      res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Tham số query teamId là bắt buộc.' },
      });
      return;
    }
    const list = await service.listInvitations(teamId, req.user!);
    res.json({
      success: true,
      data: list,
      count: list.length,
    });
  } catch (error: any) {
    const isForbidden = error.message.includes('không có quyền');
    res.status(isForbidden ? 403 : 400).json({
      success: false,
      error: { code: isForbidden ? 'FORBIDDEN' : 'GET_INVITATIONS_FAILED', message: error.message },
    });
  }
});

// PATCH /api/v1/invitations/:id - Chấp nhận, từ chối hoặc hủy lời mời giao hữu
invitationRouter.patch(
  '/:id',
  requireAuth,
  validateBody(updateInvitationStatusSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.updateInvitationStatus(
        req.params.id as string,
        req.body.status,
        req.user!
      );
      res.json({
        success: true,
        data: updated,
        message: 'Cập nhật trạng thái lời mời giao hữu thành công.',
      });
    } catch (error: any) {
      const isForbidden = error.message.includes('Chỉ đội trưởng');
      res.status(isForbidden ? 403 : 400).json({
        success: false,
        error: { code: isForbidden ? 'FORBIDDEN' : 'UPDATE_INVITATION_FAILED', message: error.message },
      });
    }
  }
);
