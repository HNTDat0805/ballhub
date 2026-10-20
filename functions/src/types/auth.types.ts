export enum UserRole {
  admin = 'admin',
  organizer = 'organizer',
  teamCaptain = 'teamCaptain',
  player = 'player',
  viewer = 'viewer',
}

export interface AuthUser {
  uid: string;
  email?: string;
  name?: string;
  role: UserRole;
  teamId?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}
