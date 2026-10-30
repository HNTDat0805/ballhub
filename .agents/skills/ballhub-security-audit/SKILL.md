---
name: ballhub-security-audit
description: >-
  Cẩm nang và quy trình rà soát lỗi bảo mật toàn diện cho hệ thống Quản lý bóng đá Ballhub.
  Kích hoạt skill này khi kiểm tra lỗ hổng bảo mật, rà soát Firestore & Realtime Database Security Rules,
  kiểm tra phân quyền RBAC (Organizer, Captain, Player), phòng chống gian lận tỷ số,
  ngăn ngừa xung đột đồng thời (Race Conditions khi đặt sân hoặc duyệt đội) và kiểm tra tính an toàn của API.
---

# Ballhub Security Audit & Hardening Skill

Cẩm nang rà soát, đánh giá và khắc phục các lỗ hổng bảo mật cho toàn bộ nền tảng bóng đá **Ballhub** (Flutter Mobile Client, Node.js/Express Backend, Firebase Firestore & Realtime Database).

---

## 1. Mô hình Phòng thủ Đa tầng (Defense in Depth)

Hệ thống Ballhub áp dụng nguyên tắc **API-First Security**:
```text
[Flutter Client] 
      │  (HTTPS + Bearer Firebase ID Token)
      ▼
[API Gateway / Cloud Functions]
      ├── 1. Auth Middleware (Xác thực chữ ký JWT ID Token)
      ├── 2. RBAC Middleware (Kiểm tra vai trò & quyền hạn tài nguyên)
      ├── 3. Zod Input Validator (Làm sạch, validate chặt chẽ kiểu dữ liệu)
      ├── 4. Service Transactions (Chống Race Condition & Overbooking)
      └── 5. Audit Logger (Ghi nhật ký thay đổi kết quả thi đấu)
      │
      ▼ (Firebase Admin SDK với đặc quyền Server)
[Cloud Firestore / Realtime DB] 
      └── Security Rules: Khóa hoàn toàn Client Direct Write (allow write: if false)
```

---

## 2. Danh mục Kiểm tra Bảo mật (Security Audit Checklist)

### 2.1. Kiểm tra Firestore & Realtime Database Security Rules
- [ ] **Firestore Client Lockout:**
  - Kiểm tra file [firestore.rules](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/firestore.rules).
  - Đảm bảo client **không được phép ghi trực tiếp** (`allow write: if false`) vào các collection: `tournaments`, `registrations`, `matches`, `standings`, `pitches`, `bookings`. Mọi thay đổi bắt buộc phải đi qua Cloud Functions đã kiểm tra logic và quyền hạn.
- [ ] **Realtime Database Validation:**
  - Kiểm tra file [database.rules.json](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/database.rules.json).
  - Đảm bảo chỉ người dùng có quyền (`auth.uid === organizerId` hoặc `auth.token.admin === true`) mới có quyền cập nhật bảng điểm và thông tin giải.
  - Phải có ràng buộc schema: kiểm tra kiểu số bàn thắng không âm (`newData.child('homeScore').val() >= 0`).

### 2.2. Kiểm tra Phân quyền & Chống IDOR (Broken Object Level Authorization)
- [ ] **Quyền sở hữu giải đấu:**
  - Khi gọi `PATCH /tournaments/:id` hoặc `DELETE /tournaments/:id`, backend **bắt buộc** phải kiểm tra `tournament.organizerId === req.user.id` (hoặc vai trò là `admin`). Ngăn chặn tuyệt đối việc Organizer A sửa hoặc hủy giải của Organizer B.
- [ ] **Quyền Đội trưởng (Team Captain):**
  - Chỉ đội trưởng của đội (`captainId === req.user.id`) mới có quyền hủy đơn đăng ký của đội mình hoặc gửi lời mời cáp kèo giao hữu.
- [ ] **Quyền Cập nhật Kết quả:**
  - Chỉ Organizer của giải đấu hoặc Super Admin mới được phép gọi `PUT /matches/:id/result`. Đội trưởng hay cầu thủ thông thường cố tình gọi API này phải nhận lỗi `403 Forbidden`.

### 2.3. Phòng chống Race Conditions & Xung đột Đồng thời (Concurrency Control)
- [ ] **Chống vượt giới hạn số đội (`maxTeams` bypass):**
  - Khi duyệt đội tham gia giải, nếu 2 Organizer cùng duyệt 2 đội cùng 1 mili-giây, hoặc có nhiều request gửi đồng thời:
  - **Bắt buộc** sử dụng `db.runTransaction` để đọc số lượng đội `approved` hiện tại và khóa trước khi ghi trạng thái `approved` cho đội mới. Nếu `count >= maxTeams`, phải ném ra lỗi `MAX_TEAMS_REACHED` (409 Conflict).
- [ ] **Chống Trùng lịch Đặt sân (Double Booking Prevention):**
  - Đối với phân hệ đặt sân (`pitch_booking`), 2 người cùng đặt 1 sân vào khung giờ 19:00 - 20:30 ngày hôm nay:
  - Bắt buộc kiểm tra trong Firestore Transaction. Nếu slot đã được chiếm (`status == confirmed` hoặc `pending` có khóa), yêu cầu sau phải bị từ chối ngay lập tức.
- [ ] **Chống đăng ký trùng lặp (Duplicate Registration):**
  - Một đội bóng không thể nộp đơn đăng ký 2 lần vào cùng 1 giải đấu. Kiểm tra sự tồn tại của `teamId` trong sub-collection `registrations`.

### 2.4. Xác thực & Làm sạch Dữ liệu Đầu vào (Input Validation & Anti-Tampering)
- [ ] **Validate bằng Zod Schema:**
  - Mọi trường đầu vào phải kiểm tra chặt chẽ:
    - Số bàn thắng: số nguyên `>= 0` (ngăn chặn gửi điểm âm hoặc số thập phân).
    - `maxTeams`: số nguyên chẵn/lẻ hợp lệ `>= 2`.
    - Chuỗi văn bản (`name`, `description`, `notes`): Cắt tỉa khoảng trắng (trim), giới hạn độ dài tối đa (max 255 ký tự cho tên, 2000 ký tự cho mô tả), loại bỏ các thẻ HTML script chống XSS Stored.
    - Thời gian: `startDate < endDate`, `registrationDeadline < startDate`.

### 2.5. Kiểm soát Thay đổi Kết quả & Audit Logging (Anti-Fraud)
- [ ] **Không sửa kết quả giải đã đóng:**
  - Khi giải đấu đã chuyển sang `completed`, việc sửa đổi tỷ số phải bị chặn, trừ trường hợp khiếu nại chính thức được phê duyệt bởi Super Admin.
- [ ] **Lưu vết Audit Log bắt buộc (`match_audits`):**
  - Mọi thao tác ghi/sửa tỷ số trận đấu phải lưu lại bản ghi:
    - `matchId`, `tournamentId`.
    - `updatedBy`: ID người thực hiện.
    - `previousScore`: Tỷ số cũ (`homeScore`, `awayScore`).
    - `newScore`: Tỷ số mới.
    - `reason`: Lý do điều chỉnh (bắt buộc nhập khi sửa kết quả đã có).
    - `timestamp`: Thời gian chính xác trên server (`admin.firestore.FieldValue.serverTimestamp()`).

### 2.6. Bảo mật Phía Client Flutter & Bí mật API
- [ ] **Không hardcode Private Keys:**
  - Không bao giờ lưu file service account JSON hoặc private token trong thư mục `lib/` hoặc commit vào Git.
  - Sử dụng biến môi trường qua `--dart-define` khi build app:
    `flutter build apk --dart-define=API_BASE_URL=https://...`
- [ ] **Kiểm tra chứng chỉ HTTPS & Timeout:**
  - Tất cả các cuộc gọi API trên môi trường Production phải chạy qua HTTPS.
  - `ApiClient` đặt timeout 10 giây để chống tấn công treo kết nối (Denial of Service / Slowloris).

---

## 3. Quy trình Thực hiện Audit Bảo mật Nhanh

Khi cần rà soát bảo mật cho một tính năng mới, thực hiện 4 bước sau:

1. **Chạy kiểm thử bảo mật tích hợp:**
   ```bash
   cd functions
   npm test
   ```
   *Xác nhận: Các test case 401 Unauthorized, 403 Forbidden, 400 Validation Error và 409 Conflict đều vượt qua 100%.*

2. **Kiểm tra Rule Firestore:**
   Chạy Firestore Emulator và gửi lệnh trực tiếp từ client để xác nhận lệnh bị từ chối `PERMISSION_DENIED`.

3. **Rà soát mã nguồn (Static Code Analysis):**
   - Tìm kiếm các truy vấn không dùng Transaction khi ghi đè số lượng hoặc slot đặt sân.
   - Kiểm tra các endpoint thiếu middleware `authenticate` hoặc `requireRole`.

4. **Kiểm tra Headers & Persona trong môi trường Production:**
   - Đảm bảo các header dev persona (`x-user-id`, `x-user-role`) chỉ được kích hoạt khi `process.env.NODE_ENV !== 'production'`. Trên Production, thông tin người dùng bắt buộc giải mã từ Firebase ID Token.
