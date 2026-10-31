import { Router, Request, Response } from 'express';
import { TeamService } from '../services/team.service';
import { requireAuth } from '../middleware/auth.middleware';
import {
  createTeamSchema,
  updateTeamSchema,
  createJoinRequestSchema,
  updateJoinRequestStatusSchema,
  validateBody,
} from '../middleware/validate.middleware';

export const teamRouter = Router();
const service = new TeamService();

// GET /api/v1/teams/mine - Lấy các đội bóng của tôi
teamRouter.get('/mine', requireAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const list = await service.getMyTeams(req.user!);
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
});

// GET /api/v1/teams - Tìm kiếm và danh sách đội bóng
teamRouter.get('/', async (req: Request, res: Response): Promise<void> => {
  try {
    const { keyword, area } = req.query;
    const list = await service.list({
      keyword: keyword as string | undefined,
      area: area as string | undefined,
    });
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
});

// POST /api/v1/teams - Tạo đội bóng mới
teamRouter.post(
  '/',
  requireAuth,
  validateBody(createTeamSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const team = await service.create(req.body, req.user!);
      res.status(201).json({
        success: true,
        data: team,
        message: 'Tạo đội bóng thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'CREATE_TEAM_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/teams/:id - Chi tiết đội bóng
teamRouter.get('/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const team = await service.getById(req.params.id as string);
    res.json({
      success: true,
      data: team,
    });
  } catch (error: any) {
    res.status(404).json({
      success: false,
      error: { code: 'NOT_FOUND', message: error.message },
    });
  }
});

// PATCH /api/v1/teams/:id - Cập nhật thông tin đội bóng
teamRouter.patch(
  '/:id',
  requireAuth,
  validateBody(updateTeamSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.update(req.params.id as string, req.body, req.user!);
      res.json({
        success: true,
        data: updated,
        message: 'Cập nhật thông tin đội bóng thành công.',
      });
    } catch (error: any) {
      const isForbidden = error.message.includes('không có quyền');
      res.status(isForbidden ? 403 : 400).json({
        success: false,
        error: { code: isForbidden ? 'FORBIDDEN' : 'UPDATE_TEAM_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/teams/:id/members - Danh sách thành viên
teamRouter.get('/:id/members', async (req: Request, res: Response): Promise<void> => {
  try {
    const members = await service.getMembers(req.params.id as string);
    res.json({
      success: true,
      data: members,
      count: members.length,
    });
  } catch (error: any) {
    res.status(404).json({
      success: false,
      error: { code: 'NOT_FOUND', message: error.message },
    });
  }
});

// DELETE /api/v1/teams/:id/members/:userId - Xóa thành viên hoặc tự rời đội
teamRouter.delete(
  '/:id/members/:userId',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      await service.removeMember(
        req.params.id as string,
        req.params.userId as string,
        req.user!
      );
      res.json({
        success: true,
        message: 'Đã xóa thành viên / rời đội bóng thành công.',
      });
    } catch (error: any) {
      const isForbidden = error.message.includes('không có quyền');
      res.status(isForbidden ? 403 : 400).json({
        success: false,
        error: { code: isForbidden ? 'FORBIDDEN' : 'REMOVE_MEMBER_FAILED', message: error.message },
      });
    }
  }
);

// POST /api/v1/teams/:id/join-requests - Gửi yêu cầu gia nhập
teamRouter.post(
  '/:id/join-requests',
  requireAuth,
  validateBody(createJoinRequestSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const request = await service.sendJoinRequest(
        req.params.id as string,
        req.body.message,
        req.user!
      );
      res.status(201).json({
        success: true,
        data: request,
        message: 'Gửi yêu cầu tham gia đội bóng thành công.',
      });
    } catch (error: any) {
      res.status(400).json({
        success: false,
        error: { code: 'JOIN_REQUEST_FAILED', message: error.message },
      });
    }
  }
);

// GET /api/v1/teams/:id/join-requests - Danh sách yêu cầu gia nhập
teamRouter.get(
  '/:id/join-requests',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const list = await service.listJoinRequests(req.params.id as string, req.user!);
      res.json({
        success: true,
        data: list,
        count: list.length,
      });
    } catch (error: any) {
      const isForbidden = error.message.includes('Chỉ đội trưởng');
      res.status(isForbidden ? 403 : 400).json({
        success: false,
        error: { code: isForbidden ? 'FORBIDDEN' : 'GET_REQUESTS_FAILED', message: error.message },
      });
    }
  }
);

// PATCH /api/v1/teams/:id/join-requests/:requestId - Duyệt hoặc từ chối yêu cầu
teamRouter.patch(
  '/:id/join-requests/:requestId',
  requireAuth,
  validateBody(updateJoinRequestStatusSchema),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const updated = await service.updateJoinRequestStatus(
        req.params.id as string,
        req.params.requestId as string,
        req.body.status,
        req.user!
      );
      res.json({
        success: true,
        data: updated,
        message: req.body.status === 'Approved' ? 'Đã duyệt thành viên vào đội.' : 'Đã từ chối yêu cầu gia nhập.',
      });
    } catch (error: any) {
      const isForbidden = error.message.includes('Chỉ đội trưởng');
      res.status(isForbidden ? 403 : 400).json({
        success: false,
        error: { code: isForbidden ? 'FORBIDDEN' : 'REVIEW_REQUEST_FAILED', message: error.message },
      });
    }
  }
);
