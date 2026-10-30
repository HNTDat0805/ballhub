import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { FieldSlotEntity } from '../types/booking.types';
export class SlotRepository {
  private memory(fieldId:string) { if (!MemoryStore.slots.has(fieldId)) MemoryStore.slots.set(fieldId,new Map()); return MemoryStore.slots.get(fieldId)!; }
  async list(fieldId:string, filters:{dateKey?:string;status?:string}={}) { if (MemoryStore.isMemoryMode()) return [...this.memory(fieldId).values()].filter(s=>(!filters.dateKey||s.dateKey===filters.dateKey)&&(!filters.status||s.status===filters.status)).sort((a,b)=>a.startsAt.localeCompare(b.startsAt)); let q:FirebaseFirestore.Query=db.collection('fields').doc(fieldId).collection('slots'); if(filters.dateKey)q=q.where('dateKey','==',filters.dateKey); if(filters.status)q=q.where('status','==',filters.status); const snap=await q.get(); return snap.docs.map(d=>d.data() as FieldSlotEntity).sort((a,b)=>a.startsAt.localeCompare(b.startsAt)); }
  async save(slot:FieldSlotEntity) { if(MemoryStore.isMemoryMode()){this.memory(slot.fieldId).set(slot.id,slot);return;} await db.collection('fields').doc(slot.fieldId).collection('slots').doc(slot.id).set(slot); }
  async find(fieldId:string,id:string){if(MemoryStore.isMemoryMode())return this.memory(fieldId).get(id)??null;const s=await db.collection('fields').doc(fieldId).collection('slots').doc(id).get();return s.exists?s.data() as FieldSlotEntity:null;}
}
