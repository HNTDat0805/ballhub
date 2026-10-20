# Hướng dẫn cấu hình môi trường, chạy thử nghiệm và deploy Ballhub

Tài liệu này cung cấp toàn bộ hướng dẫn cho các kỹ sư để chạy cục bộ, kiểm thử và deploy hệ thống quản lý giải đấu API-first của Ballhub.

---

## 1. Yêu cầu môi trường

- **Flutter SDK:** >= 3.13.0 (Hiện tại: Flutter 3.47 / Dart 3.13)
- **Node.js:** >= 20.x (Hiện tại: v26.10)
- **NPM:** >= 10.x
- **Firebase CLI:** >= 13.x (`npm install -g firebase-tools`)
- **Java Runtime (JDK):** >= 17 (Hiện tại: Java 27)

---

## 2. Cấu trúc mã nguồn

```text
ballhub/
├── functions/                    # Backend REST API (Firebase Cloud Functions / TypeScript)
│   ├── src/
│   │   ├── config/              # Cấu hình Firebase Admin & MemoryStore fallback
│   │   ├── middleware/          # Auth, RBAC, Zod Validation, Error handler
│   │   ├── repositories/        # Firestore Repository Layer
│   │   ├── services/            # Tournament, Registration, Schedule, Match, Standings
│   │   ├── routes/              # Express API Routes (/api/v1/...)
│   │   ├── app.ts               # Express application entry
│   │   ├── index.ts             # Firebase Cloud Function onRequest export
│   │   └── local.ts             # Local Express Server Runner
│   ├── tests/                   # Integration test suite (Node test runner + Supertest)
│   ├── package.json
│   └── tsconfig.json
├── lib/                         # Flutter Client (Presentation, UI State & API Client)
│   ├── core/
│   │   ├── api/                 # ApiClient (HTTP, Auth headers, Error mapping)
│   │   ├── auth/                # AuthContext (Role-based personas)
│   │   └── theme/               # AppTheme & Design System
│   └── features/
│       └── tournament/
│           ├── data/            # ApiTournamentRepository (Triển khai TournamentRepository)
│           ├── domain/          # Models (Tournament, Team, Match, Standings)
│           └── presentation/    # Screens, Controllers, Widgets
├── firestore.rules              # Cloud Firestore Security Rules (Khóa client write)
├── firestore.indexes.json       # Composite indexes cho truy vấn
├── firebase.json                # Cấu hình Firebase CLI & Emulators
└── test/                        # Flutter Unit & Widget Tests
```

---

## 3. Chạy Backend REST API

### Cách 1: Chạy trực tiếp qua Express Local Server (Khuyên dùng cho phát triển nhanh)
```bash
cd functions
npm install
npm run build
npm run local
```
- Server sẽ khởi động tại: `http://localhost:5001/api/v1`
- Kiểm tra trạng thái: `http://localhost:5001/api/v1/health`
- Xem tài liệu OpenAPI: `http://localhost:5001/api/v1/docs`

### Cách 2: Chạy qua Firebase Emulator Suite
```bash
firebase emulators:start --only functions,firestore,auth
```
- Emulator UI: `http://localhost:4000`
- Functions: `http://localhost:5001/ballhub-ac5a7/asia-southeast1/api`
- Firestore: `localhost:8080`

---

## 4. Chạy kiểm thử tự động (Automated Testing)

### 4.1. Kiểm thử Backend REST API
Chạy bộ 17 bài test tích hợp kiểm tra toàn bộ luồng nghiệp vụ:
```bash
cd functions
npm test
```
Kết quả kiểm tra:
- Xác thực và từ chối 401 khi thiếu token.
- Phân quyền RBAC và từ chối 403 đối với vai trò không được phép.
- Validate dữ liệu đầu vào và trả về lỗi 400 chi tiết.
- Tạo, sửa, xem chi tiết và lọc giải đấu.
- Đăng ký đội bóng và ngăn chặn đội đăng ký trùng.
- Duyệt đội bóng và kiểm tra giới hạn số đội tối đa `maxTeams`.
- Tự động sinh lịch thi đấu theo thể thức vòng tròn và loại trực tiếp.
- Cập nhật tỷ số trận đấu, lưu nhật ký audit log.
- Tự động tính toán lại bảng xếp hạng (điểm số, hiệu số, đối đầu trực tiếp).

### 4.2. Kiểm thử Flutter Client
Chạy bộ test kiểm tra mô hình, API Client, ApiTournamentRepository và UI:
```bash
flutter test
```
Phân tích tĩnh kiểm tra chất lượng code:
```bash
dart analyze lib test
```

---

## 5. Chạy ứng dụng Flutter

```bash
# Chạy trên trình duyệt Web (Chrome)
flutter run -d chrome

# Chạy trên thiết bị hoặc máy ảo Android
flutter run -d android
```

*Lưu ý:* Khi chạy trên máy ảo Android, `ApiClient` tự động định tuyến địa chỉ `http://10.0.2.2:5001/api/v1` trỏ về máy chủ phát triển trên máy tính của bạn.

---

## 6. Quy trình Deploy lên Firebase Production

1. Đăng nhập Firebase CLI:
   ```bash
   firebase login
   ```
2. Chọn dự án:
   ```bash
   firebase use ballhub-ac5a7
   ```
3. Deploy Firestore Security Rules & Indexes:
   ```bash
   firebase deploy --only firestore
   ```
4. Build và Deploy Cloud Functions API:
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```
5. Cập nhật `baseUrl` trong `ApiClient` sang Cloud Functions Production URL:
   `https://asia-southeast1-ballhub-ac5a7.cloudfunctions.net/api/api/v1`
