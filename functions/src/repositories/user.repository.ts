import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { UserProfileEntity } from '../types/user.types';

export class UserRepository {
  private get usersRef() {
    return db.collection('users');
  }

  async findById(userId: string): Promise<UserProfileEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return MemoryStore.users.get(userId) || null;
    }
    const snap = await this.usersRef.doc(userId).get();
    if (!snap.exists) return null;
    return snap.data() as UserProfileEntity;
  }

  async save(user: UserProfileEntity): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.users.set(user.userId, user);
      return;
    }
    await this.usersRef.doc(user.userId).set(user);
  }

  async update(userId: string, data: Partial<UserProfileEntity>): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const existing = MemoryStore.users.get(userId);
      if (existing) {
        MemoryStore.users.set(userId, { ...existing, ...data });
      }
      return;
    }
    await this.usersRef.doc(userId).update(data);
  }
}
