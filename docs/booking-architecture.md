# BallHub — Booking Architecture Documentation

> Tài liệu này giải thích toàn bộ kiến trúc, data flow, và business logic của module Booking trong dự án BallHub.
> Được viết bằng tiếng Việt để phù hợp với người học CNTT mới bắt đầu.

---

## 1. Tổng quan kiến trúc

BallHub áp dụng kiến trúc **API-first** — Flutter không gọi trực tiếp Firestore mà phải đi qua REST API.

```
Flutter App
    │
    ▼
Controller (quản lý UI state)
    │
    ▼
Repository (gọi REST API)
    │
    ▼
ApiClient (HTTP client tập trung)
    │
    ▼
REST API (Firebase Cloud Functions)
    │
    ▼
Route → Validation → Service → Repository → Firestore
```

### Tại sao thiết kế như vậy?

- **Bảo mật**: Firestore rules default-deny, chỉ Firebase Admin SDK (backend) có quyền đọc/ghi
- **Business logic tập trung**: Chống double booking, kiểm tra ownership đều nằm ở backend
- **Dễ test**: Backend có thể test độc lập không cần chạy app
- **Linh hoạt**: Có thể thay đổi Flutter UI mà không phá logic backend

---

## 2. Cấu trúc Firestore

```
fieldOwners/
  {ownerId}/              ← Hồ sơ chủ sân

fields/
  {fieldId}/              ← Thông tin sân bóng
    slots/
      {slotId}/           ← Khung giờ của sân

bookings/
  {bookingId}/            ← Yêu cầu đặt sân

tournaments/              ← Module giải đấu (KHÔNG liên quan đến Booking)
  {tournamentId}/
```

### Quy tắc Firestore Security

- Tất cả đều **default-deny** — không có client nào (kể cả Flutter) đọc được Firestore trực tiếp
- Firebase Admin SDK (chạy trên Cloud Functions) có full access
- Flutter chỉ gọi REST API, REST API mới gọi Firestore qua Admin SDK

---

## 3. Domain Models

### FootballField (Sân bóng)

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `id` | string | ID duy nhất |
| `ownerId` | string | ID chủ sân |
| `name` | string | Tên sân |
| `address` | string | Địa chỉ |
| `city` | string | Thành phố |
| `fieldType` | string | Loại sân (5 người, 7 người...) |
| `basePrice` | number | Giá cơ bản (VND) |
| `status` | FieldStatus | Trạng thái: draft/active/inactive/maintenance/archived |
| `timezone` | string | Múi giờ, mặc định Asia/Ho_Chi_Minh |

**Chỉ field `active` mới được phép đặt sân.**

### FieldSlot (Khung giờ)

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `id` | string | ID duy nhất |
| `fieldId` | string | ID sân chứa slot này |
| `dateKey` | string | Ngày theo dạng YYYY-MM-DD |
| `startsAt` | ISO datetime | Thời điểm bắt đầu (UTC) |
| `endsAt` | ISO datetime | Thời điểm kết thúc (UTC) |
| `basePrice` | number | Giá của slot này (có thể khác basePrice sân) |
| `status` | FieldSlotStatus | Trạng thái: available/held/booked/blocked |
| `bookingId` | string? | ID booking đang giữ/đặt slot này |
| `holdExpiresAt` | datetime? | Khi nào hold hết hạn |
| `blockReason` | string? | Lý do bị khóa |

> **Lưu ý**: `selected` và `disabled` chỉ là **UI state** — KHÔNG lưu vào Firestore.

### Booking (Đặt sân)

| Field | Kiểu | Mô tả |
|-------|------|-------|
| `id` | string | ID duy nhất |
| `fieldId` | string | ID sân |
| `ownerId` | string | ID chủ sân (lấy từ field) |
| `bookerId` | string | ID người đặt |
| `slotIds` | string[] | Danh sách slot đã đặt |
| `priceSnapshot` | number | Giá tổng tại thời điểm đặt |
| `subtotalAmount` | number | Tổng trước chiết khấu |
| `discountAmount` | number | Chiết khấu |
| `totalAmount` | number | Số tiền phải trả |
| `status` | BookingStatus | Trạng thái vòng đời |
| `fieldNameSnapshot` | string | Tên sân tại thời điểm đặt |
| `fieldAddressSnapshot` | string | Địa chỉ sân tại thời điểm đặt |

> **Snapshot**: Giá và thông tin sân được lưu **bản sao** vào booking. Khi chủ sân thay đổi giá, các booking cũ vẫn giữ giá gốc.

---

## 4. Booking Lifecycle (Vòng đời đặt sân)

### Slot State Transitions

```
available  ──────────────────────────► blocked
    │                                    (chủ sân khóa)
    │ createBooking()
    ▼
  held   ─── holdExpired() ──► available
    │                              ▲
    │ confirm()      │ reject()    │
    ▼                └─────────────┘
  booked
    │
    │ cancel() / complete()
    ▼
  available (released)
```

### Booking Status Transitions

```
              ┌──────────────────────────────┐
              │                              │
              ▼                              │
[pending] ──────► [confirmed] ──────► [completed]
    │                  │
    │ reject()         │ cancelledByOwner()
    ▼                  ▼
[rejected]         [cancelledByOwner]
    │
    │ cancel() by user
    ▼
[cancelledByUser]
```

### Quy trình Create Booking (Transaction)

```
1. Backend nhận request: { fieldId, slotIds, customerNote }
2. Xác thực user (lấy từ auth header, KHÔNG tin client)
3. Lấy FootballField → kiểm tra status == active
4. Lấy tất cả FieldSlot trong transaction
5. Kiểm tra từng slot:
   - Thuộc đúng fieldId
   - status == available
   - Các slot phải liền kề nhau (contiguous)
6. Tính giá: sum(slot.basePrice)
7. Snapshot: fieldName, fieldAddress, price
8. Tạo Booking document
9. Cập nhật từng slot: status → held, bookingId → bookingId
10. COMMIT toàn bộ trong db.runTransaction()
```

> Nếu bất kỳ bước nào fail, transaction tự động rollback → không có trạng thái nửa chừng.

---

## 5. Chống Double Booking

**Tình huống**: User A và User B cùng đặt slot X cùng lúc.

**Giải pháp**: Firestore Transaction với optimistic locking.

```typescript
await db.runTransaction(async (transaction) => {
  // READ tất cả slots trong transaction
  const snapshots = await Promise.all(refs.map(ref => transaction.get(ref)));
  
  // VALIDATE: nếu bất kỳ slot nào không còn available → throw error
  if (slots.some(slot => slot.status !== 'available')) {
    throw new BookingConflictError('Khung giờ vừa không còn trống');
  }
  
  // WRITE: chỉ thực thi nếu validate pass
  transaction.set(bookingRef, booking);
  for (const ref of slotRefs) {
    transaction.update(ref, { status: 'held', bookingId: booking.id });
  }
  // COMMIT: tự động, nếu có conflict thì Firestore retry
});
```

Chỉ **một** transaction thành công. Transaction còn lại sẽ retry và thấy slot không còn available → trả 409 BOOKING_CONFLICT.

---

## 6. Authorization

### Roles

| Role | Quyền |
|------|-------|
| `player` | Xem field active, đặt sân, xem/hủy booking của mình |
| `fieldOwner` | CRUD field của mình, confirm/reject booking của field mình |
| `admin` | Full access |

### Ownership Check

Backend **không tin** bất kỳ dữ liệu nào từ client về ownership:

```typescript
// Field Service
private assertOwner(field: FootballFieldEntity, user: AuthUser): void {
  if (user.role !== UserRole.admin && field.ownerId !== user.uid) {
    throw new Error('Bạn không có quyền quản lý sân này.');
  }
}

// Booking Service
private assertOwner(booking: BookingEntity, user: AuthUser): void {
  if (user.role !== UserRole.admin && booking.ownerId !== user.uid) {
    throw new BookingRequestError('FORBIDDEN', 'Bạn không có quyền...', 403);
  }
}
```

### Authentication Convention

Development dùng mock auth headers:
- `x-user-id`: User ID
- `x-user-role`: Role (player/fieldOwner/admin...)
- `x-user-name`: Tên hiển thị

Production sẽ dùng Firebase ID Token thật.

---

## 7. REST API Endpoints

### Field APIs

| Method | Path | Auth | Mô tả |
|--------|------|------|-------|
| GET | `/api/v1/fields` | Optional | Danh sách sân (mặc định chỉ active) |
| GET | `/api/v1/fields/:fieldId` | Optional | Chi tiết sân |
| POST | `/api/v1/fields` | fieldOwner/admin | Tạo sân mới |
| PATCH | `/api/v1/fields/:fieldId` | fieldOwner/admin | Cập nhật thông tin sân |
| PATCH | `/api/v1/fields/:fieldId/status` | fieldOwner/admin | Thay đổi trạng thái sân |

### Slot APIs

| Method | Path | Auth | Mô tả |
|--------|------|------|-------|
| GET | `/api/v1/fields/:fieldId/slots` | Optional | Danh sách slot |
| POST | `/api/v1/fields/:fieldId/slots` | fieldOwner/admin | Tạo slot mới |
| PATCH | `/api/v1/fields/:fieldId/slots/:slotId` | fieldOwner/admin | Cập nhật slot |
| POST | `/api/v1/fields/:fieldId/slots/:slotId/block` | fieldOwner/admin | Khóa slot |
| POST | `/api/v1/fields/:fieldId/slots/:slotId/unblock` | fieldOwner/admin | Mở khóa slot |

### Booking APIs (User)

| Method | Path | Auth | Mô tả |
|--------|------|------|-------|
| POST | `/api/v1/bookings` | player | Tạo booking mới |
| GET | `/api/v1/bookings/me` | player | Booking của tôi |
| GET | `/api/v1/bookings/:bookingId` | player/owner | Chi tiết booking |
| POST | `/api/v1/bookings/:bookingId/cancel` | player | Hủy booking |

### Booking APIs (Owner)

| Method | Path | Auth | Mô tả |
|--------|------|------|-------|
| GET | `/api/v1/owner/bookings` | fieldOwner | Booking thuộc sân của mình |
| POST | `/api/v1/owner/bookings/:bookingId/confirm` | fieldOwner | Xác nhận booking |
| POST | `/api/v1/owner/bookings/:bookingId/reject` | fieldOwner | Từ chối booking |

### Response Format

```json
// Success
{ "success": true, "data": { ... } }

// Error
{ "success": false, "error": { "code": "ERROR_CODE", "message": "Mô tả lỗi" } }
```

---

## 8. Flutter Architecture

### Folder structure

```
lib/
  core/
    api/          ← ApiClient (HTTP tập trung)
    auth/         ← AuthContext (user hiện tại)
    theme/        ← AppTheme (Material 3)
  features/
    booking/
      domain/
        models/   ← Booking, FootballField, FieldSlot (immutable)
      data/
        booking_repository.dart      ← Interface
        api_booking_repository.dart  ← Implementation dùng ApiClient
      presentation/
        controllers/  ← State management (ChangeNotifier)
        screens/      ← UI screens
        widgets/      ← Reusable widgets
    tournament/   ← Module giải đấu (KHÔNG sửa)
```

### Controllers quan trọng

| Controller | Màn hình | Chức năng |
|-----------|---------|-----------|
| `FieldListController` | Field List | Tải danh sách sân, search, filter |
| `FieldDetailController` | Field Detail | Chi tiết sân, slots theo ngày |
| `SlotSelectionController` | Slot Selection | Chọn slot liên tiếp, tính tiền |
| `CreateBookingController` | Booking Form | Tạo booking, handle success/error |
| `BookingListController` | My Bookings | Booking của user, filter theo status |
| `BookingDetailController` | Booking Detail | Chi tiết và hủy booking |
| `OwnerBookingController` | Owner Bookings | Quản lý booking, confirm/reject |
| `OwnerFieldController` | Owner Fields | Quản lý sân, tạo/sửa/đổi trạng thái |

### Data Flow ví dụ: Đặt sân

```
1. User chọn slot → SlotSelectionController.toggleSlot()
2. User nhấn "Đặt sân" → CreateBookingController.createBooking()
3. Controller gọi → BookingRepository.createBooking(fieldId, slotIds)
4. Repository dùng → ApiClient.post('/bookings', body)
5. ApiClient gửi → HTTP POST với auth header
6. Backend Route nhận → validates body bằng Zod
7. Route gọi → BookingService.create()
8. Service kiểm tra field, slot → gọi BookingRepository.reserve()
9. Repository chạy → db.runTransaction() → commit
10. Response trả về → Repository parse → Controller update state
11. Controller set success state → UI navigate đến BookingDetailScreen
```

---

## 9. Firestore Indexes (hiện tại)

Indexes đã được khai báo trong `firestore.indexes.json`:

```json
slots:
  dateKey + status + startsAt (ASC)

bookings:
  bookerId + startsAt (DESC)
  ownerId + status + startsAt (ASC)
  fieldId + startsAt (ASC)
```

---

## 10. How to Run

### Backend (Cloud Functions local)

```bash
cd C:\ballhub\functions
npm install
npm run build
npm test                  # Chạy integration tests (in-memory)
```

### Flutter App

```bash
cd C:\ballhub
flutter pub get
flutter analyze lib       # Kiểm tra lint (phải 0 issues)
flutter test              # Chạy unit tests
flutter run               # Chạy app (cần device/emulator)
```

### Build APK (Android)

```bash
cd C:\ballhub
flutter build apk --debug    # Debug APK
flutter build apk --release  # Release APK (cần signing)
```

---

## 11. Khái niệm cần hiểu

### Transaction là gì?
Transaction là một nhóm thao tác database được thực hiện **nguyên tử** — hoặc tất cả thành công, hoặc tất cả bị hủy bỏ. Không có trạng thái nửa chừng.

### Snapshot là gì?
Khi tạo booking, ta sao chép (snapshot) thông tin sân vào booking. Nếu sau này sân đổi tên hay đổi giá, booking cũ vẫn hiển thị thông tin tại thời điểm đặt.

### Held vs Booked slot?
- **held**: Slot đang được "giữ chỗ" cho một booking pending. Có thể bị release nếu booking bị hủy/từ chối.
- **booked**: Slot đã được xác nhận. Chỉ released khi booking bị cancel hoặc hoàn thành.

### ChangeNotifier là gì?
Là cơ chế state management trong Flutter. Controller extends ChangeNotifier, khi state thay đổi gọi `notifyListeners()`, UI (widget) rebuild tự động.

### API-first là gì?
Flutter không đọc Firestore trực tiếp. Mọi dữ liệu phải qua REST API. Điều này đảm bảo business logic luôn chạy ở backend, không thể bị bypass từ client.
