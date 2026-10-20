import { Request, Response, NextFunction } from 'express';
import { z, ZodError } from 'zod';
import { TournamentFormat, TournamentStatus, RegistrationStatus, MatchStatus } from '../types/tournament.types';

export function validateBody(schema: z.ZodSchema) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Dữ liệu yêu cầu không hợp lệ.',
            details: error.errors.map(e => ({
              field: e.path.join('.'),
              message: e.message,
            })),
          },
        });
        return;
      }
      next(error);
    }
  };
}

// Schemas
export const createTournamentSchema = z.object({
  name: z.string().min(3, 'Tên giải đấu phải có ít nhất 3 ký tự').max(100),
  description: z.string().optional().default(''),
  bannerUrl: z.string().optional().default(''),
  location: z.string().min(2, 'Địa điểm phải có ít nhất 2 ký tự'),
  startDate: z.string().refine((val) => !isNaN(Date.parse(val)), 'Ngày bắt đầu không hợp lệ (ISO 8601)'),
  endDate: z.string().refine((val) => !isNaN(Date.parse(val)), 'Ngày kết thúc không hợp lệ (ISO 8601)'),
  registrationDeadline: z.string().refine((val) => !isNaN(Date.parse(val)), 'Hạn chót đăng ký không hợp lệ (ISO 8601)'),
  maxTeams: z.number().int().min(2, 'Số đội tối đa phải từ 2 trở lên').max(64),
  format: z.nativeEnum(TournamentFormat).default(TournamentFormat.roundRobinSingle),
  status: z.nativeEnum(TournamentStatus).default(TournamentStatus.preparing),
});

export const updateTournamentSchema = z.object({
  name: z.string().min(3).max(100).optional(),
  description: z.string().optional(),
  bannerUrl: z.string().optional(),
  location: z.string().min(2).optional(),
  startDate: z.string().refine((val) => !isNaN(Date.parse(val)), 'Ngày bắt đầu không hợp lệ').optional(),
  endDate: z.string().refine((val) => !isNaN(Date.parse(val)), 'Ngày kết thúc không hợp lệ').optional(),
  registrationDeadline: z.string().refine((val) => !isNaN(Date.parse(val)), 'Hạn chót đăng ký không hợp lệ').optional(),
  maxTeams: z.number().int().min(2).max(64).optional(),
  format: z.nativeEnum(TournamentFormat).optional(),
  status: z.nativeEnum(TournamentStatus).optional(),
});

export const registerTeamSchema = z.object({
  teamId: z.string().min(1, 'teamId là bắt buộc'),
  teamName: z.string().min(2, 'Tên đội phải từ 2 ký tự trở lên'),
  logoUrl: z.string().optional().default(''),
  captainId: z.string().optional(),
  captainName: z.string().min(2, 'Tên đội trưởng không được để trống'),
  captainPhone: z.string().min(8, 'Số điện thoại không hợp lệ'),
  captainEmail: z.string().email('Email không đúng định dạng'),
  membersCount: z.number().int().min(5, 'Số thành viên tối thiểu là 5').max(30).default(11),
});

export const updateRegistrationStatusSchema = z.object({
  status: z.nativeEnum(RegistrationStatus),
  reviewNote: z.string().optional(),
});

export const generateScheduleSchema = z.object({
  venue: z.string().optional().default('Sân vận động chính'),
});

export const updateMatchDetailsSchema = z.object({
  scheduledTime: z.string().refine((val) => !isNaN(Date.parse(val)), 'Thời gian thi đấu không hợp lệ').optional(),
  venue: z.string().min(1).optional(),
  notes: z.string().optional(),
  status: z.nativeEnum(MatchStatus).optional(),
});

export const updateMatchResultSchema = z.object({
  homeScore: z.number().int().min(0, 'Tỷ số đội nhà không được là số âm'),
  awayScore: z.number().int().min(0, 'Tỷ số đội khách không được là số âm'),
  status: z.nativeEnum(MatchStatus).default(MatchStatus.finished),
  isConfirmed: z.boolean().default(true),
  notes: z.string().optional(),
  reason: z.string().optional(),
});
