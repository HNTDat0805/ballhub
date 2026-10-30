export enum FieldOwnerVerificationStatus {
  pending = 'pending',
  verified = 'verified',
  rejected = 'rejected',
  suspended = 'suspended',
}

export enum FieldStatus {
  draft = 'draft',
  active = 'active',
  inactive = 'inactive',
  maintenance = 'maintenance',
  archived = 'archived',
}

export enum FieldSlotStatus {
  available = 'available',
  held = 'held',
  booked = 'booked',
  blocked = 'blocked',
}

export enum BookingStatus {
  pending = 'pending',
  confirmed = 'confirmed',
  rejected = 'rejected',
  cancelledByUser = 'cancelledByUser',
  cancelledByOwner = 'cancelledByOwner',
  completed = 'completed',
}

export interface FieldOwnerProfileEntity {
  ownerId: string;
  businessName: string;
  phone: string;
  verificationStatus: FieldOwnerVerificationStatus;
  createdAt: string;
  updatedAt: string;
}

export interface FootballFieldEntity {
  id: string;
  ownerId: string;
  name: string;
  description: string;
  coverImageUrl: string;
  imageUrls: string[];
  address: string;
  district: string;
  city: string;
  latitude: number;
  longitude: number;
  fieldType: string;
  capacity: number;
  amenities: string[];
  basePrice: number;
  currency: string;
  slotDurationMinutes: number;
  status: FieldStatus;
  openingHours: Record<string, string[]>;
  timezone: string;
  createdAt: string;
  updatedAt: string;
  createdBy: string;
  updatedBy: string;
}

export interface FieldSlotEntity {
  id: string;
  fieldId: string;
  dateKey: string;
  startsAt: string;
  endsAt: string;
  durationMinutes: number;
  basePrice: number;
  currency: string;
  status: FieldSlotStatus;
  bookingId?: string | null;
  holdExpiresAt?: string | null;
  blockReason?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface BookingEntity {
  id: string;
  fieldId: string;
  ownerId: string;
  bookerId: string;
  dateKey: string;
  startsAt: string;
  endsAt: string;
  slotIds: string[];
  fieldNameSnapshot: string;
  fieldAddressSnapshot: string;
  priceSnapshot: number;
  currency: string;
  bookerNameSnapshot: string;
  bookerPhoneSnapshot: string;
  status: BookingStatus;
  statusReason?: string | null;
  subtotalAmount: number;
  discountAmount: number;
  totalAmount: number;
  customerNote?: string | null;
  ownerNote?: string | null;
  cancellationReason?: string | null;
  confirmedAt?: string | null;
  rejectedAt?: string | null;
  cancelledAt?: string | null;
  completedAt?: string | null;
  reviewedBy?: string | null;
  createdAt: string;
  updatedAt: string;
}
