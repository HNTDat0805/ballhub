import { db } from '../config/firebase';
import { MemoryStore } from '../config/memory.store';
import { BookingEntity, BookingStatus, FieldSlotEntity, FieldSlotStatus } from '../types/booking.types';
export class BookingRepository {
 async find(id:string){if(MemoryStore.isMemoryMode())return MemoryStore.bookings.get(id)??null;const s=await db.collection('bookings').doc(id).get();return s.exists?s.data() as BookingEntity:null;}
 async list(filters:{bookerId?:string;ownerId?:string;fieldId?:string}){if(MemoryStore.isMemoryMode())return [...MemoryStore.bookings.values()].filter(b=>(!filters.bookerId||b.bookerId===filters.bookerId)&&(!filters.ownerId||b.ownerId===filters.ownerId)&&(!filters.fieldId||b.fieldId===filters.fieldId));let q:FirebaseFirestore.Query=db.collection('bookings');for(const [k,v] of Object.entries(filters))if(v)q=q.where(k,'==',v);const s=await q.get();return s.docs.map(d=>d.data() as BookingEntity);}
 async save(booking:BookingEntity){if(MemoryStore.isMemoryMode()){MemoryStore.bookings.set(booking.id,booking);return;}await db.collection('bookings').doc(booking.id).set(booking);}
 async reserve(booking: BookingEntity): Promise<void> {
   if (MemoryStore.isMemoryMode()) {
     const slots = MemoryStore.slots.get(booking.fieldId);
     const selected = booking.slotIds.map((id) => slots?.get(id));
     if (selected.some((slot) => !slot || slot.status !== FieldSlotStatus.available)) throw new BookingConflictError('Một hoặc nhiều khung giờ vừa không còn trống.');
     for (const slot of selected as FieldSlotEntity[]) slots!.set(slot.id, { ...slot, status: FieldSlotStatus.held, bookingId: booking.id, holdExpiresAt: booking.createdAt, updatedAt: booking.updatedAt });
     MemoryStore.bookings.set(booking.id, booking); return;
   }
   await db.runTransaction(async (transaction) => {
     const refs = booking.slotIds.map((id) => db.collection('fields').doc(booking.fieldId).collection('slots').doc(id));
     const snapshots = await Promise.all(refs.map((ref) => transaction.get(ref)));
     const slots = snapshots.map((snap) => snap.exists ? snap.data() as FieldSlotEntity : null);
     if (slots.some((slot) => !slot || slot.status !== FieldSlotStatus.available)) throw new BookingConflictError('Một hoặc nhiều khung giờ vừa không còn trống.');
     transaction.set(db.collection('bookings').doc(booking.id), booking);
     for (let index = 0; index < refs.length; index += 1) transaction.update(refs[index], { status: FieldSlotStatus.held, bookingId: booking.id, holdExpiresAt: booking.createdAt, updatedAt: booking.updatedAt });
   });
 }
 async transition(booking: BookingEntity, status: BookingStatus, reason: string | undefined, releaseSlots: boolean): Promise<BookingEntity> {
   const now = new Date().toISOString();
   const updated: BookingEntity = { ...booking, status, statusReason: reason ?? null, updatedAt: now,
     confirmedAt: status === BookingStatus.confirmed ? now : booking.confirmedAt,
     rejectedAt: status === BookingStatus.rejected ? now : booking.rejectedAt,
     cancelledAt: status === BookingStatus.cancelledByUser || status === BookingStatus.cancelledByOwner ? now : booking.cancelledAt,
     cancellationReason: releaseSlots ? reason ?? null : booking.cancellationReason,
   };
   if (MemoryStore.isMemoryMode()) {
     const current = MemoryStore.bookings.get(booking.id); if (!current || current.status !== BookingStatus.pending) throw new BookingConflictError('Trạng thái booking đã thay đổi.');
     const slots = MemoryStore.slots.get(booking.fieldId);
     for (const id of booking.slotIds) { const slot = slots?.get(id); if (slot && slot.bookingId === booking.id) slots!.set(id, { ...slot, status: releaseSlots ? FieldSlotStatus.available : FieldSlotStatus.booked, bookingId: releaseSlots ? null : booking.id, holdExpiresAt: null, updatedAt: now }); }
     MemoryStore.bookings.set(booking.id, updated); return updated;
   }
   await db.runTransaction(async (transaction) => {
     const bookingRef = db.collection('bookings').doc(booking.id);
     const slotRefs = booking.slotIds.map((id) => db.collection('fields').doc(booking.fieldId).collection('slots').doc(id));
     const [bookingSnapshot, ...slotSnapshots] = await Promise.all([transaction.get(bookingRef), ...slotRefs.map((ref) => transaction.get(ref))]);
     const current = bookingSnapshot.exists ? bookingSnapshot.data() as BookingEntity : null;
     if (!current || current.status !== BookingStatus.pending) throw new BookingConflictError('Trạng thái booking đã thay đổi.');
     transaction.set(bookingRef, updated);
     slotRefs.forEach((ref, index) => { const slot = slotSnapshots[index].data() as FieldSlotEntity | undefined; if (slot?.bookingId === booking.id) transaction.update(ref, { status: releaseSlots ? FieldSlotStatus.available : FieldSlotStatus.booked, bookingId: releaseSlots ? null : booking.id, holdExpiresAt: null, updatedAt: now }); });
   });
   return updated;
 }
}

export class BookingConflictError extends Error {}
