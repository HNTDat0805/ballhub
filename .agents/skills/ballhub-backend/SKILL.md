---
name: ballhub-backend
description: >-
  Hướng dẫn và quy chuẩn triển khai Backend REST API cho dự án Ballhub (Firebase Cloud Functions,
  Node.js/TypeScript, Express, Firestore và Realtime Database). Kích hoạt skill này khi phát triển
  hoặc sửa đổi API endpoints, mô hình dữ liệu Firestore, thuật toán sinh lịch thi đấu (Berger, Knockout),
  tự động tính điểm bảng xếp hạng (Standings Engine), quản lý đặt sân (Pitch Booking) và tìm đội (Team Matchmaking).
---

# Ballhub Backend Development & Architecture Skill

Tài liệu hướng dẫn quy chuẩn kỹ thuật cho hệ thống Backend API-First của nền tảng Quản lý bóng đá **Ballhub**, xây dựng trên nền tảng **Firebase Cloud Functions (TypeScript/Express)** và **Google Cloud Firestore**.

---

## 1. Cấu trúc thư mục Backend (`functions/`)

Backend tuân thủ kiến trúc phân tầng (Layered Architecture):
```text
functions/
├── src/
│   ├── config/              # Cấu hình Firebase Admin SDK & MemoryStore fallback
│   ├── middleware/          # Auth (Bearer Token/Persona), RBAC, Zod Validation, Error Handler
│   ├── repositories/        # Firestore Repository Layer (Data Access Object)
│   ├── services/            # Nghiệp vụ: Tournament, Registration, Schedule, Match, Standings
│   ├── routes/              # Express API Routers (/api/v1/...)
│   ├── types/               # TypeScript Interfaces, Enums & Zod Schemas
│   ├── app.ts               # Khởi tạo Express App, middleware toàn cục, route mapping
│   ├── index.ts             # Export Firebase Cloud Function onRequest (Deploy target)
│   └── local.ts             # Local Express Server Runner (Phục vụ dev nhanh)
├── tests/                   # Bộ kiểm thử tích hợp (Node test runner + Supertest)
├── package.json
└── tsconfig.json
```

---

## 2. Quy chuẩn thiết kế REST API & Phản hồi

### 2.1. Định dạng Base URL
- Mọi endpoint REST API nằm dưới prefix: `/api/v1`
- Định dạng dữ liệu trao đổi: `application/json`

### 2.2. Cấu trúc phản hồi chuẩn (Standard JSON Response)
- **Thành công (2xx):**
```json
{
  "success": true,
  "data": { ... },
  "message": "Thông điệp phản hồi (tùy chọn)",
  "count": 10 // (Nếu là mảng)
}
```

- **Thất bại (4xx, 5xx):**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR | UNAUTHORIZED | FORBIDDEN | NOT_FOUND | CONFLICT",
    "message": "Mô tả lỗi thân thiện với người dùng",
    "details": [ ... ] // Chi tiết lỗi từ Zod hoặc hệ thống
  }
}
```

---

## 3. Nghiệp vụ cốt lõi bóng đá (Football Domain Logic)

### 3.1. Quản lý Giải đấu & Vòng đời (Tournament Lifecycle)
- **Các trạng thái giải đấu:**
  - `preparing`: Vừa tạo, đang cấu hình điều lệ, chưa mở đăng ký.
  - `registrationOpen`: Đang nhận hồ sơ đăng ký đội bóng.
  - `inProgress`: Đã sinh lịch và đang diễn ra các trận đấu.
  - `completed`: Đã kết thúc toàn bộ giải đấu, vinh danh nhà vô địch.
  - `cancelled`: Giải đấu bị hủy.

- **Quy tắc chuyển trạng thái:**
  - Không cho phép chỉnh sửa thể thức (`format`) hoặc giảm `maxTeams` khi giải đã `inProgress`.
  - Chỉ cho phép chuyển sang `inProgress` khi đã sinh lịch thi đấu chính thức.
  - Không cho phép xóa giải đấu đang `inProgress` (chỉ được `cancelled`).

### 3.2. Đăng ký & Duyệt đội tham gia (Registration & Concurrency Control)
- **Quy tắc bắt buộc:**
  - Đội bóng phải đăng ký trong thời hạn `registrationDeadline`.
  - Một đội (`teamId`) **không được phép** đăng ký trùng vào cùng một giải đấu.
  - **Firestore Transaction bắt buộc:** Khi Organizer duyệt đội (`status: approved`), phải đọc lại danh sách đội đã duyệt trong Transaction để đảm bảo số đội được duyệt **không vượt quá `maxTeams`** khi có nhiều thao tác đồng thời.

### 3.3. Thuật toán Lịch thi đấu (Schedule Generation)
- **Vòng tròn 1 lượt (Single Round Robin):**
  - Sử dụng thuật toán vòng quay **Berger Tables** (Circle Method).
  - Nếu số đội lẻ, tự động bổ sung đội ảo `BYE`. Đội nào gặp `BYE` sẽ được nghỉ vòng đấu đó.
  - Mỗi vòng đấu (Round) phải cách nhau tối thiểu khoảng thời gian hợp lý (mặc định 2-3 ngày) để đảm bảo thể lực.
- **Vòng tròn 2 lượt (Double Round Robin):**
  - Lượt về đảo ngược vị trí sân nhà/sân khách (`homeTeamId` <-> `awayTeamId`).
- **Loại trực tiếp (Knockout):**
  - Hỗ trợ số đội 4, 8, 16. Phân nhánh từ Tứ kết (Quarter-final) -> Bán kết (Semi-final) -> Chung kết (Final).
- **Safe Merge (Bảo toàn lịch cũ):**
  - Khi BTC tạo lại lịch thi đấu, thuật toán phải kiểm tra các trận đấu đã kết thúc (`status == finished`) hoặc đã có tỷ số để **bảo lưu kết quả**, không xóa hoặc ghi đè tùy tiện.

### 3.4. Hệ thống Tự động Tính Bảng xếp hạng (Standings Engine)
Mỗi khi có cập nhật kết quả trận đấu (`PUT /matches/:id/result`):
1. Cập nhật tỷ số trận đấu: `homeScore`, `awayScore`, `status: finished`.
2. Ghi nhật ký vào collection `match_audits` (lưu vết ai sửa, thời gian, điểm cũ, điểm mới, lý do).
3. **Tự động kích hoạt tính lại BXH:**
   - Thắng = 3 điểm, Hòa = 1 điểm, Thua = 0 điểm.
   - Hiệu số bàn thắng bại: `goalDifference = goalsFor - goalsAgainst`.
   - Tiêu chí ưu tiên xếp hạng:
     1. `points` (Điểm số cao hơn)
     2. `goalDifference` (Hiệu số tốt hơn)
     3. `goalsFor` (Ghi nhiều bàn thắng hơn)
     4. `head-to-head` (Thành tích đối đầu giữa các đội bằng điểm)
     5. Thứ tự bảng chữ cái tên đội.
   - Ghi đè vào collection `tournaments/{tournamentId}/standings/{teamId}`.

### 3.5. Mở rộng Module: Đặt sân bóng (Pitch Booking)
- **Data Model:**
  - `pitches`: Sân 5, sân 7, sân 11; mặt sân cỏ nhân tạo/tự nhiên, địa chỉ, đơn giá theo khung giờ (Peak/Off-peak).
  - `bookings`: `pitchId`, `date`, `startTime`, `endTime`, `userId`, `status` (`pending`, `confirmed`, `cancelled`).
- **Xử lý xung đột slot (Slot Lock):**
  - Sử dụng Firestore Transaction để kiểm tra khung giờ đã có ai đặt trước khi xác nhận đơn.

### 3.6. Mở rộng Module: Tìm đối / Cáp kèo (Team Matchmaking)
- **Data Model:**
  - `match_requests`: Đội cần tìm đối, trình độ (Trung bình khá, Vui là chính, Chuyên nghiệp), khu vực, thời gian mong muốn, tiền sân chia đôi.
  - Phù hợp kèo -> Cho phép Đội trưởng 2 bên xác nhận và chuyển thành trận giao hữu.

---

## 4. Các lệnh phát triển & Kiểm thử Backend

```bash
# 1. Di chuyển vào thư mục functions
cd functions

# 2. Cài đặt thư viện
npm install

# 3. Biên dịch TypeScript sang JavaScript
npm run build

# 4. Chạy server Express cục bộ (Port 5001)
npm run local

# 5. Chạy bộ 17 bài kiểm thử tích hợp (Node test runner + Supertest)
npm test

# 6. Chạy Firebase Emulators (Auth, Firestore, Functions)
firebase emulators:start --only functions,firestore,auth
```

---

## 5. Quy chuẩn viết code & Xử lý lỗi

- **Validate đầu vào:** Luôn sử dụng thư viện `zod` để định nghĩa schema cho `req.body`, `req.params`, `req.query`.
- **Phân tách trách nhiệm:** Routes chỉ nhận request -> gọi Middleware -> gọi Service -> trả về Response. Mọi tính toán logic nằm ở `services/`.
- **Database Access:** Mọi truy vấn Firestore phải đi qua `repositories/`. Không gọi `admin.firestore()` trực tiếp trong Controller.
- **Log rõ ràng:** Sử dụng `console.info` và `console.error` có gắn tiền tố `[Module][Action]` để dễ tra cứu trong Cloud Logging.
