import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import {
  TeamEntity,
  TeamMemberEntity,
  JoinRequestEntity,
  FriendlyInvitationEntity,
} from '../types/team.types';

export class TeamRepository {
  private get teamsRef() {
    return db.collection('teams');
  }

  private get membersRef() {
    return db.collection('teamMembers');
  }

  private get requestsRef() {
    return db.collection('joinRequests');
  }

  private get invitesRef() {
    return db.collection('friendlyInvitations');
  }

  // ================= TEAMS =================

  async findById(teamId: string): Promise<TeamEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return MemoryStore.teams.get(teamId) || null;
    }
    const snap = await this.teamsRef.doc(teamId).get();
    if (!snap.exists) return null;
    return snap.data() as TeamEntity;
  }

  async findByName(name: string, exceptId?: string): Promise<TeamEntity | null> {
    const lower = name.trim().toLowerCase();
    if (MemoryStore.isMemoryMode()) {
      for (const t of MemoryStore.teams.values()) {
        if (t.teamNameLower === lower && t.teamId !== exceptId) return t;
      }
      return null;
    }
    const snap = await this.teamsRef.where('teamNameLower', '==', lower).get();
    for (const doc of snap.docs) {
      if (doc.id !== exceptId) return doc.data() as TeamEntity;
    }
    return null;
  }

  async list(filters?: { keyword?: string; area?: string }): Promise<TeamEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      let list = Array.from(MemoryStore.teams.values());
      const kw = filters?.keyword?.trim().toLowerCase();
      const ar = filters?.area?.trim().toLowerCase();
      if (kw) {
        list = list.filter((t) => t.teamNameLower.includes(kw));
      }
      if (ar) {
        list = list.filter((t) => t.area.toLowerCase().includes(ar));
      }
      list.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
      return list;
    }

    let query: FirebaseFirestore.Query = this.teamsRef;
    const snap = await query.orderBy('createdAt', 'desc').get();
    let list: TeamEntity[] = [];
    snap.forEach((d) => list.push(d.data() as TeamEntity));

    const kw = filters?.keyword?.trim().toLowerCase();
    const ar = filters?.area?.trim().toLowerCase();
    if (kw) {
      list = list.filter((t) => t.teamNameLower.includes(kw));
    }
    if (ar) {
      list = list.filter((t) => t.area.toLowerCase().includes(ar));
    }
    return list;
  }

  async save(team: TeamEntity): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.teams.set(team.teamId, team);
      return;
    }
    await this.teamsRef.doc(team.teamId).set(team);
  }

  async update(teamId: string, data: Partial<TeamEntity>): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const existing = MemoryStore.teams.get(teamId);
      if (existing) {
        MemoryStore.teams.set(teamId, { ...existing, ...data });
      }
      return;
    }
    await this.teamsRef.doc(teamId).update(data);
  }

  async deleteTeam(teamId: string): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.teams.delete(teamId);
      for (const [key, m] of MemoryStore.teamMembers.entries()) {
        if (m.teamId === teamId) MemoryStore.teamMembers.delete(key);
      }
      for (const [key, r] of MemoryStore.joinRequests.entries()) {
        if (r.teamId === teamId) MemoryStore.joinRequests.delete(key);
      }
      for (const [key, inv] of MemoryStore.friendlyInvitations.entries()) {
        if (inv.fromTeamId === teamId || inv.toTeamId === teamId) {
          MemoryStore.friendlyInvitations.delete(key);
        }
      }
      return;
    }
    await this.teamsRef.doc(teamId).delete();
    const membersSnap = await this.membersRef.where('teamId', '==', teamId).get();
    const batch = db.batch();
    membersSnap.forEach((doc) => batch.delete(doc.ref));
    const requestsSnap = await this.requestsRef.where('teamId', '==', teamId).get();
    requestsSnap.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  // ================= MEMBERS =================

  async findMember(teamId: string, userId: string): Promise<TeamMemberEntity | null> {
    const linkId = `${teamId}_${userId}`;
    if (MemoryStore.isMemoryMode()) {
      return MemoryStore.teamMembers.get(linkId) || null;
    }
    const snap = await this.membersRef.doc(linkId).get();
    if (!snap.exists) return null;
    return snap.data() as TeamMemberEntity;
  }

  async listMembers(teamId: string): Promise<TeamMemberEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      const list = Array.from(MemoryStore.teamMembers.values()).filter((m) => m.teamId === teamId);
      list.sort((a, b) => (a.role === 'Captain' ? -1 : b.role === 'Captain' ? 1 : 0));
      return list;
    }
    const snap = await this.membersRef.where('teamId', '==', teamId).get();
    const list: TeamMemberEntity[] = [];
    snap.forEach((d) => list.push(d.data() as TeamMemberEntity));
    list.sort((a, b) => (a.role === 'Captain' ? -1 : b.role === 'Captain' ? 1 : 0));
    return list;
  }

  async listUserTeams(userId: string): Promise<TeamEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      const teamIds = Array.from(MemoryStore.teamMembers.values())
        .filter((m) => m.userId === userId)
        .map((m) => m.teamId);
      return teamIds.map((id) => MemoryStore.teams.get(id)).filter(Boolean) as TeamEntity[];
    }
    const snap = await this.membersRef.where('userId', '==', userId).get();
    const teamIds = snap.docs.map((d) => d.data().teamId as string);
    if (teamIds.length === 0) return [];

    const teams: TeamEntity[] = [];
    for (const id of teamIds) {
      const t = await this.findById(id);
      if (t) teams.push(t);
    }
    return teams;
  }

  async addMember(member: TeamMemberEntity): Promise<void> {
    const linkId = `${member.teamId}_${member.userId}`;
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.teamMembers.set(linkId, member);
      return;
    }
    await this.membersRef.doc(linkId).set(member);
  }

  async removeMember(teamId: string, userId: string): Promise<void> {
    const linkId = `${teamId}_${userId}`;
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.teamMembers.delete(linkId);
      return;
    }
    await this.membersRef.doc(linkId).delete();
  }

  // ================= JOIN REQUESTS =================

  async findJoinRequest(requestId: string): Promise<JoinRequestEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return MemoryStore.joinRequests.get(requestId) || null;
    }
    const snap = await this.requestsRef.doc(requestId).get();
    if (!snap.exists) return null;
    return snap.data() as JoinRequestEntity;
  }

  async findUserPendingRequest(teamId: string, userId: string): Promise<JoinRequestEntity | null> {
    const id = `${teamId}_${userId}`;
    if (MemoryStore.isMemoryMode()) {
      const req = MemoryStore.joinRequests.get(id);
      return req && req.status === 'Pending' ? req : null;
    }
    const snap = await this.requestsRef.doc(id).get();
    if (snap.exists && snap.data()?.status === 'Pending') {
      return snap.data() as JoinRequestEntity;
    }
    return null;
  }

  async listPendingRequests(teamId: string): Promise<JoinRequestEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      return Array.from(MemoryStore.joinRequests.values()).filter(
        (r) => r.teamId === teamId && r.status === 'Pending'
      );
    }
    const snap = await this.requestsRef
      .where('teamId', '==', teamId)
      .where('status', '==', 'Pending')
      .get();
    const list: JoinRequestEntity[] = [];
    snap.forEach((d) => list.push(d.data() as JoinRequestEntity));
    return list;
  }

  async saveJoinRequest(request: JoinRequestEntity): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.joinRequests.set(request.requestId, request);
      return;
    }
    await this.requestsRef.doc(request.requestId).set(request);
  }

  async updateJoinRequest(requestId: string, data: Partial<JoinRequestEntity>): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const existing = MemoryStore.joinRequests.get(requestId);
      if (existing) {
        MemoryStore.joinRequests.set(requestId, { ...existing, ...data });
      }
      return;
    }
    await this.requestsRef.doc(requestId).update(data);
  }

  // ================= FRIENDLY INVITATIONS =================

  async findInvitation(id: string): Promise<FriendlyInvitationEntity | null> {
    if (MemoryStore.isMemoryMode()) {
      return MemoryStore.friendlyInvitations.get(id) || null;
    }
    const snap = await this.invitesRef.doc(id).get();
    if (!snap.exists) return null;
    return snap.data() as FriendlyInvitationEntity;
  }

  async saveInvitation(invitation: FriendlyInvitationEntity): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      MemoryStore.friendlyInvitations.set(invitation.id, invitation);
      return;
    }
    await this.invitesRef.doc(invitation.id).set(invitation);
  }

  async updateInvitation(id: string, data: Partial<FriendlyInvitationEntity>): Promise<void> {
    if (MemoryStore.isMemoryMode()) {
      const existing = MemoryStore.friendlyInvitations.get(id);
      if (existing) {
        MemoryStore.friendlyInvitations.set(id, { ...existing, ...data });
      }
      return;
    }
    await this.invitesRef.doc(id).update(data);
  }

  async listInvitations(teamId: string): Promise<FriendlyInvitationEntity[]> {
    if (MemoryStore.isMemoryMode()) {
      return Array.from(MemoryStore.friendlyInvitations.values()).filter(
        (i) => i.fromTeamId === teamId || i.toTeamId === teamId
      );
    }
    const sentSnap = await this.invitesRef.where('fromTeamId', '==', teamId).get();
    const recvSnap = await this.invitesRef.where('toTeamId', '==', teamId).get();

    const map = new Map<string, FriendlyInvitationEntity>();
    sentSnap.forEach((d) => map.set(d.id, d.data() as FriendlyInvitationEntity));
    recvSnap.forEach((d) => map.set(d.id, d.data() as FriendlyInvitationEntity));
    return Array.from(map.values()).sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }
}
