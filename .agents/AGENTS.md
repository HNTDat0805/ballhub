# Dự án Quản lý Bóng đá Ballhub - Hướng dẫn & Quy tắc Phát triển

Hệ thống quản lý bóng đá toàn diện: **Tổ chức giải đấu, Đặt sân bóng, Cáp kèo tìm đối, Lịch thi đấu và Bảng xếp hạng trực tiếp**.

## 1. Công nghệ chính
- **Mobile Frontend:** Flutter (Dart 3.x), Material 3, Clean Feature-First Architecture, Presentation Controller (`ChangeNotifier`) kết hợp `Stream<List<T>>`.
- **Backend API:** Firebase Cloud Functions (Node.js 20.x, TypeScript, Express), Layered Architecture (`routes`, `middleware`, `services`, `repositories`).
- **Database & Storage:** Google Cloud Firestore (Primary Datastore) & Firebase Realtime Database.
- **Xác thực & Bảo mật:** Firebase Authentication (JWT ID Token), Role-Based Access Control (Admin, Organizer, Team Captain, Player, Viewer), Firestore Default Deny Security Rules.

## 2. Quy tắc lập trình cốt lõi
1. **API-First Security:** Mọi thao tác ghi dữ liệu không được gọi trực tiếp Firestore từ Client mà phải đi qua Backend REST API `/api/v1/...` để kiểm tra phân quyền, validate và lưu audit log.
2. **Concurrency Control:** Sử dụng Firestore Transactions cho các hành động nhạy cảm: duyệt đội không vượt `maxTeams`, đặt sân không trùng slot thời gian.
3. **Quản lý lỗi nhất quán:** Phía backend luôn trả về cấu trúc lỗi chuẩn `{success: false, error: {code, message, details}}`. Phía Flutter luôn bọc thành `ApiException` và hiển thị thông báo tiếng Việt thân thiện.
4. **Kiểm thử tự động:** Trước khi release, bắt buộc chạy `cd functions && npm test` và `flutter test && dart analyze lib test`.

## 3. Bộ kỹ năng chuyên biệt (.agents/skills)
- `ballhub-backend`: Hướng dẫn phát triển Express Cloud Functions, Firestore schema, thuật toán Berger & Knockout, tính toán BXH.
- `ballhub-frontend`: Hướng dẫn lập trình giao diện Flutter, UI/UX bóng đá (Match card, Standings table, Pitch booking, Team finding).
- `ballhub-security-audit`: Cẩm nang rà soát lỗ hổng, Firestore Rules, phân quyền RBAC và kiểm toán gian lận.
- `ballhub-secret-scan`: Rà soát và ngăn chặn rò rỉ API Keys, Private Keys, Service Accounts, Keystore trước khi commit/push lên GitHub.
- `ballhub-cicd`: Tự động hóa kiểm thử, GitHub Actions pipeline và triển khai Firebase Production.
