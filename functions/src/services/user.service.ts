import { UserRepository } from '../repositories/user.repository';
import { AuthUser } from '../types/auth.types';
import { UpdateUserProfileDto, UserProfileEntity } from '../types/user.types';

export class UserService {
  constructor(private userRepo: UserRepository = new UserRepository()) {}

  async getProfile(user: AuthUser): Promise<UserProfileEntity> {
    let profile = await this.userRepo.findById(user.uid);
    if (!profile) {
      const now = new Date().toISOString();
      profile = {
        userId: user.uid,
        fullName: user.name || 'Cầu thủ Ballhub',
        email: user.email || '',
        phone: null,
        position: 'Cầu thủ',
        area: '',
        avatarBase64: null,
        avatarUrl: null,
        role: user.role,
        createdAt: now,
        updatedAt: now,
      };
      await this.userRepo.save(profile);
    }
    return profile;
  }

  async updateProfile(data: UpdateUserProfileDto, user: AuthUser): Promise<UserProfileEntity> {
    const current = await this.getProfile(user);
    const now = new Date().toISOString();

    const updates: Partial<UserProfileEntity> = {
      updatedAt: now,
    };
    if (data.fullName !== undefined) updates.fullName = data.fullName.trim();
    if (data.phone !== undefined) updates.phone = data.phone?.trim() || null;
    if (data.position !== undefined) updates.position = data.position?.trim() || null;
    if (data.area !== undefined) updates.area = data.area?.trim() || null;

    await this.userRepo.update(user.uid, updates);
    return { ...current, ...updates };
  }

  async updateAvatar(avatarBase64: string, user: AuthUser): Promise<UserProfileEntity> {
    const current = await this.getProfile(user);
    // Kiểm tra dung lượng xấp xỉ của chuỗi Base64 (700KB)
    if (avatarBase64.length > 1024 * 1024) {
      throw new Error('Ảnh đại diện vượt quá kích thước cho phép (tối đa 700KB).');
    }

    const updates: Partial<UserProfileEntity> = {
      avatarBase64,
      updatedAt: new Date().toISOString(),
    };

    await this.userRepo.update(user.uid, updates);
    return { ...current, ...updates };
  }
}
