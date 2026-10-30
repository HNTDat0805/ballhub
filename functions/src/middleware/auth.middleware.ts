import { Request, Response, NextFunction } from 'express';
import { auth } from '../config/firebase';
import { UserRole } from '../types/auth.types';

/**
 * Middleware xác thực danh tính người dùng (Authentication Middleware).
 *
 * Kiểm tra theo thứ tự ưu tiên:
 * 1. Headers phát triển/kiểm thử (x-user-id, x-user-role, x-user-name).
 * 2. Token kiểm thử cục bộ ("Bearer mock-token-...").
 * 3. Firebase ID Token thực tế qua Firebase Admin Auth (auth.verifyIdToken).
 */
export async function authenticate(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const isDevOrTest = process.env.NODE_ENV !== 'production';

    // 1. Dev / Test header support (CHỈ cho phép trong môi trường Development & Test cục bộ)
    const devUserId = req.headers['x-user-id'] as string | undefined;
    const devUserRole = req.headers['x-user-role'] as string | undefined;
    if (isDevOrTest && devUserId) {
      const role = (devUserRole && Object.values(UserRole).includes(devUserRole as UserRole))
        ? (devUserRole as UserRole)
        : UserRole.viewer;

      req.user = {
        uid: devUserId,
        email: (req.headers['x-user-email'] as string) || `${devUserId}@ballhub.vn`,
        name: (req.headers['x-user-name'] as string) || devUserId,
        role: role,
        teamId: req.headers['x-user-team'] as string | undefined,
      };
      return next();
    }

    // 2. Standard Authorization Bearer token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = undefined;
      return next();
    }

    const token = authHeader.split('Bearer ')[1].trim();
    if (!token) {
      req.user = undefined;
      return next();
    }

    // Check mock dev token format (CHỈ cho phép trong môi trường Development & Test cục bộ)
    if (isDevOrTest && token.startsWith('mock-token-')) {
      const parts = token.replace('mock-token-', '').split('-');
      const uid = parts[0] || 'dev_user';
      const roleStr = parts[1] || 'viewer';
      const role = Object.values(UserRole).includes(roleStr as UserRole)
        ? (roleStr as UserRole)
        : UserRole.viewer;

      req.user = {
        uid,
        email: `${uid}@ballhub.vn`,
        name: `User ${uid}`,
        role,
        teamId: parts[2] || undefined,
      };
      return next();
    }

    // Verify real Firebase ID Token
    const decoded = await auth.verifyIdToken(token);
    const roleClaim = decoded.role as string | undefined;
    const role = (roleClaim && Object.values(UserRole).includes(roleClaim as UserRole))
      ? (roleClaim as UserRole)
      : UserRole.viewer;

    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      name: decoded.name,
      role: role,
      teamId: decoded.teamId as string | undefined,
    };
    return next();
  } catch (error) {
    // If token is invalid or expired
    req.user = undefined;
    return next();
  }
}

/**
 * Bắt buộc request phải được xác thực danh tính (đã đăng nhập).
 */
export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  if (!req.user) {
    res.status(401).json({
      success: false,
      error: {
        code: 'UNAUTHENTICATED',
        message: 'Yêu cầu xác thực tài khoản. Vui lòng đăng nhập hoặc cung cấp Authorization header hợp lệ.',
      },
    });
    return;
  }
  next();
}

/**
 * Kiểm tra quyền hạn RBAC của người dùng.
 * Cho phép các vai trò được chỉ định hoặc Admin hệ thống (Superuser).
 */
export function requireRoles(...allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: {
          code: 'UNAUTHENTICATED',
          message: 'Yêu cầu đăng nhập trước khi thực hiện thao tác.',
        },
      });
      return;
    }

    // Admin has superuser privileges across all actions
    if (req.user.role === UserRole.admin) {
      return next();
    }

    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        error: {
          code: 'PERMISSION_DENIED',
          message: `Bạn không có quyền thực hiện thao tác này. Quyền yêu cầu: [${allowedRoles.join(', ')}]. Vai trò hiện tại của bạn: ${req.user.role}.`,
        },
      });
      return;
    }

    next();
  };
}
