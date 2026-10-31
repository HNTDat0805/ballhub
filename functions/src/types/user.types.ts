export interface UserProfileEntity {
  userId: string;
  fullName: string;
  email: string;
  phone?: string | null;
  position?: string | null;
  area?: string | null;
  avatarBase64?: string | null;
  avatarUrl?: string | null;
  role: string;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface UpdateUserProfileDto {
  fullName?: string;
  phone?: string;
  position?: string;
  area?: string;
}
