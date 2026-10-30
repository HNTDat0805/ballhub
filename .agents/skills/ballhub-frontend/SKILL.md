---
name: ballhub-frontend
description: >-
  Hướng dẫn và quy chuẩn phát triển giao diện ứng dụng di động Flutter/Dart cho dự án Ballhub.
  Kích hoạt skill này khi xây dựng hoặc tối ưu hóa màn hình (Screens), Widgets, Controllers,
  quản lý trạng thái (ChangeNotifier/Streams), tích hợp ApiClient REST, giao diện giải đấu (Tournament),
  bảng xếp hạng (Standings), lịch thi đấu (Match Center), đặt sân bóng (Pitch Booking) và tìm đội (Team Finding).
---

# Ballhub Frontend Development & UI/UX Skill

Tài liệu hướng dẫn quy chuẩn lập trình giao diện người dùng **Flutter (Dart 3)** cho nền tảng di động Quản lý bóng đá **Ballhub**, tuân thủ cấu trúc **Feature-First Architecture** và hệ thống giao diện **Material 3**.

---

## 1. Cấu trúc thư mục Flutter Client (`lib/`)

Mã nguồn frontend được tổ chức theo từng phân hệ chức năng (Feature-First):
```text
lib/
├── core/
│   ├── api/                 # ApiClient (HTTP, Auth headers, Error mapping thành ApiException)
│   ├── auth/                # AuthContext (Role-based personas, switch persona cho dev/test)
│   └── theme/               # AppTheme, màu sắc bóng đá (Emerald/Pitch Green), Typography
├── features/
│   ├── tournament/          # Phân hệ Quản lý Giải đấu
│   │   ├── data/            # TournamentRepository & ApiTournamentRepository
│   │   ├── domain/          # Models: Tournament, TournamentTeam, TournamentMatch, StandingsRow
│   │   └── presentation/    # Screens, Controllers, Widgets
│   │       ├── controllers/ # TournamentController (ChangeNotifier)
│   │       ├── screens/     # TournamentListScreen, TournamentDetailScreen, ScheduleScreen...
│   │       └── widgets/     # StandingsTable, MatchCard, TournamentHeader...
│   ├── booking/             # Phân hệ Đặt sân bóng (Pitch Booking)
│   └── matchmaking/         # Phân hệ Cáp kèo, Tìm đối (Team Finding)
├── firebase_options.dart    # Cấu hình Firebase Client (nếu dùng)
└── main.dart                # Điểm khởi động ứng dụng Flutter
```

---

## 2. Hệ thống Quản lý trạng thái (State Management)

Dự án áp dụng mô hình **Presentation Controller (`ChangeNotifier`) kết hợp `Stream<List<T>>`**:

### 2.1. Quy tắc Controller
- Controller kế thừa `ChangeNotifier`.
- Quản lý trạng thái bất đồng bộ rõ ràng:
  - `bool isLoading`: Bật khi đang gọi API, tắt trong khối `finally`.
  - `String? errorMessage`: Lưu thông báo lỗi thân thiện để hiển thị `SnackBar` hoặc Banner thông báo.
  - Sau mỗi thay đổi state, gọi `notifyListeners()`.

### 2.2. Luồng dữ liệu thời gian thực (Reactive Streams)
- Sử dụng `StreamBuilder<List<T>>` cho các danh sách cần cập nhật động:
  - `watchTournaments()`: Lọc theo `searchQuery` và `statusFilter`.
  - `watchTeams(tournamentId)`: Danh sách đội đăng ký theo thời gian thực.
  - `watchMatches(tournamentId)`: Lịch và tỷ số các trận đấu.
  - `watchStandings(tournamentId)`: Bảng xếp hạng cập nhật ngay sau khi nhập tỷ số.

---

## 3. Tích hợp Backend qua `ApiClient`

Mọi tương tác mạng **bắt buộc** thông qua class [ApiClient](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/lib/core/api/api_client.dart):
- **Phân giải URL linh hoạt:**
  - Máy ảo Android Emulator: `http://10.0.2.2:5001/api/v1`
  - Flutter Web & Desktop: `http://localhost:5001/api/v1`
  - Production: Trỏ đến Cloud Functions base URL.
- **Header xác thực tự động:**
  - `Authorization: Bearer <TOKEN>`
  - Persona headers: `x-user-id`, `x-user-role`, `x-user-name`, `x-user-team`.
- **Xử lý ngoại lệ chuẩn hóa:**
  - Mọi lỗi HTTP hoặc mạng đều bọc thành `ApiException(code, message, statusCode, details)`.
  - Bắt lỗi tại tầng Repository hoặc Controller để hiển thị thông báo tiếng Việt rõ ràng.

---

## 4. Thiết kế Giao diện Bóng đá Chuyên sâu (Football UI/UX)

### 4.1. Bảng màu & Phong cách (Design System)
- **Primary Color:** `Color(0xFF0F9D58)` / Emerald Green (Sắc xanh cỏ bóng đá chuyên nghiệp).
- **Secondary / Accent:** Vàng đồng cúp vô địch `Color(0xFFFFB300)` và Xanh Navy `Color(0xFF1A237E)`.
- **Dark Mode Support:** Nền xám đen huyền ảo (`Color(0xFF121212)`) với thẻ bo góc viền bóng mờ (Subtle card border), tạo cảm giác hiện đại như các ứng dụng thể thao hàng đầu (LiveScore, SofaScore).

### 4.2. Các thành phần giao diện đặc trưng

#### A. Thẻ Trận đấu (Match Card)
- Hiển thị logo 2 đội bóng, tên đội viết hoa nổi bật.
- Giữa 2 đội là Tỷ số lớn (nếu trận đã kết thúc) hoặc Khung giờ thi đấu & Tên sân (nếu sắp diễn ra).
- Trạng thái trận đấu gắn nhãn có màu:
  - `scheduled`: Xám/Xanh nhạt.
  - `inProgress`: Đỏ/Cam nhấp nháy "LIVE".
  - `finished`: Xanh lục đậm kèm icon còi kết thúc.
- Quyền nhập tỷ số: Chỉ hiển thị nút sửa/nhập cho BTC (`organizer`, `admin`).

#### B. Bảng xếp hạng (Standings Table)
- Thiết kế dạng bảng tối ưu cho màn hình di động:
  - Cột cố định: Vị trí (Rank 1, 2, 3 có huy chương vàng/bạc/đồng), Tên đội bóng + Logo.
  - Cột cuộn ngang: Trận (P), Thắng (W), Hòa (D), Thua (L), Bàn thắng/bàn thua (GF/GA), Hiệu số (GD), Điểm (PTS in đậm).
- Highlight các vị trí trong Top tranh cúp (Xanh lá) hoặc xuống hạng (Đỏ).

#### C. Lưới Đặt sân bóng (Pitch Booking Grid)
- Chọn loại sân: Sân 5, Sân 7, Sân 11.
- Thanh trượt chọn ngày trong tuần (Horizontal Date Picker).
- Ma trận các khung giờ (Slot Matrix): 17:30 - 19:00, 19:00 - 20:30, 20:30 - 22:00.
  - Màu xanh: Trống (Có thể đặt).
  - Màu xám gạch chéo: Đã có đội đặt.
  - Màu vàng cam: Đang chờ giữ chỗ.

#### D. Bảng Cáp kèo Tìm đối (Team Matchmaking Board)
- Thẻ lời mời thi đấu: Logo đội, Trình độ (5 sao hoặc nhãn "Vui là chính", "Khá - Mềm", "Chuyên nghiệp"), Sân bóng dự kiến, Điều khoản (Tiền sân chia đôi, Nước uống tự lo).
- Nút "Cáp kèo ngay" để kết nối trao đổi giữa 2 Đội trưởng.

---

## 5. Quy trình Kiểm thử & Chất lượng Code Frontend

Trước khi hoàn thành bất kỳ tính năng UI nào, chạy các lệnh kiểm tra:

```bash
# 1. Kiểm tra cú pháp và tuân thủ phân tích tĩnh Dart
dart analyze lib test

# 2. Chạy toàn bộ Unit test và Widget test
flutter test

# 3. Chạy thử trên trình duyệt Chrome để test nhanh UI
flutter run -d chrome

# 4. Chạy trên máy ảo Android
flutter run -d android
```

---

## 6. Hướng dẫn UX mượt mà (Micro-interactions)
- Dùng `RefreshIndicator` ở đầu danh sách để kéo vuốt làm mới dữ liệu.
- Sử dụng `Hero` animation khi người dùng nhấn vào thẻ giải đấu để chuyển mượt mà vào màn hình chi tiết.
- Hiển thị Skeleton loading (Placeholder xám nhấp nháy) thay vì vòng xoay tròn đơn điệu khi tải bảng xếp hạng và danh sách trận.
