---
name: ballhub-code-review
description: >-
  Cẩm nang và quy trình chuẩn hóa Review Code (Đánh giá mã nguồn) toàn diện cho dự án Ballhub.
  Kích hoạt skill này khi người dùng yêu cầu review code, đánh giá Pull Request (PR), kiểm tra chất lượng mã nguồn
  trước khi merge/commit, rà soát tuân thủ kiến trúc Flutter Feature-First & Express Layered Backend,
  phát hiện lỗi tiềm ẩn (bugs, memory leaks, race conditions, async unmounted context), và kiểm định quy chuẩn bảo mật/hiệu năng.
---

# Ballhub Code Review Standard & Guidelines

Tài liệu quy chuẩn và cẩm nang thực hành **Code Review (Đánh giá mã nguồn)** toàn diện cho hệ thống Quản lý bóng đá **Ballhub** (Flutter Mobile Client, Node.js/TypeScript Cloud Functions, Firestore & Realtime Database).

---

## 1. Tôn chỉ & Hệ thống Phân loại Mức độ (Severities)

### 1.1. Tôn chỉ Review trong Ballhub
- **Nghiêm ngặt về kiến trúc & bảo mật:** Đảm bảo hệ thống vận hành đúng quy chuẩn API-First, an toàn dữ liệu bóng đá và không có xung đột đồng thời.
- **Thân thiện với người học CNTT:** Giải thích ngắn gọn, bằng tiếng Việt, nêu rõ **Nguyên nhân gốc rễ (Root Cause)**, **Rủi ro tiềm ẩn (Impact)** và cung cấp **Mã nguồn khắc phục (Diff Before/After)**.
- **Bảo toàn tính độc lập của domain:** Nghiêm cấm gộp sai module (ví dụ: tuyệt đối không biến `TournamentMatch` thành `Booking`).

### 1.2. Thang đánh giá mức độ nghiêm trọng

| Cấp độ | Biểu tượng | Ý nghĩa & Tiêu chuẩn | Hành động yêu cầu |
|---|:---:|---|---|
| **BLOCKER** | 🔴 | Lỗi nghiêm trọng: Crash ứng dụng, rò rỉ bảo mật (IDOR, bypass Auth, leak secret), ghi trực tiếp Firestore từ Client, Race Condition (trùng slot sân, vượt `maxTeams`), phá vỡ kiến trúc cốt lõi, hỏng Test/Build. | **Bắt buộc sửa** trước khi commit hoặc merge. Không ngoại lệ. |
| **MAJOR** | 🟠 | Cảnh báo cao: Thiếu `if (!mounted) return;` sau `await` trong Flutter State, rò rỉ bộ nhớ (quên `dispose` Controller/Stream/Timer), silent catch nuốt lỗi, thiếu Zod validation ở Backend, hardcoded URL/màu sắc/kích thước, thiếu xử lý trạng thái Loading/Error. | Khuyến nghị sửa ngay trong PR hiện tại. |
| **MINOR** | 🟡 | Cải thiện chất lượng code: Vi phạm quy ước đặt tên (`snake_case`, `camelCase`), thiếu từ khóa `const` trên Widget, code trùng lặp nhỏ, chuỗi hiển thị tiếng Việt chưa tối ưu, thiếu comment giải thích logic thuật toán phức tạp. | Sửa nếu có thời gian, không chặn merge. |
| **NIT / PRAISE** | 🟢 | Khen ngợi & Tối ưu nhỏ: Đánh giá cao cách xử lý khéo léo, gợi ý cú pháp ngắn gọn hơn (syntactic sugar) hoặc vi tối ưu hiệu năng không bắt buộc. | Tùy chọn tham khảo. |

---

## 2. Quy trình 5 Bước Review Code Thực Chiến

Khi thực hiện review một nhánh code, commit hoặc pull request, Agent/Reviewer thực hiện tuần tự 5 bước:

```text
[Bước 1: Khảo sát Phạm vi & Diff]
       │
       ▼
[Bước 2: Kiểm tra Tự động (Lint, Build, Test)]
       │
       ▼
[Bước 3: Rà soát Kiến trúc & Phân tầng]
       │
       ▼
[Bước 4: Kiểm tra Lỗ hổng & Edge Cases theo Ma trận Rủi ro]
       │
       ▼
[Bước 5: Lập Báo cáo Review Chi tiết & Đề xuất Khắc phục]
```

### Bước 1: Khảo sát Phạm vi & Diff (Scope Analysis)
1. Kiểm tra danh sách file thay đổi: `git status -s` hoặc `git diff --name-only`.
2. Xác minh phạm vi thay đổi:
   - Thay đổi có bám sát yêu cầu nghiệp vụ hay không?
   - Có tự ý format hàng loạt file không liên quan làm loãng diff không?
   - Nếu đang làm module Booking/Matchmaking, có vô tình sửa chéo sang `lib/features/tournament/` hoặc backend tournament không?

### Bước 2: Kiểm tra Tự động (Automated Verification)
Reviewer chạy (hoặc yêu cầu chạy) các công cụ kiểm tra tự động:
```bash
# 1. Kiểm tra Frontend Flutter
flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test

# 2. Kiểm tra Backend Cloud Functions
cd functions
npm run build
npm test
```
> [!IMPORTANT]
> Nếu có bất kỳ lỗi linter hoặc test case nào bị fail, đây là 🔴 **BLOCKER**. Phải fix lỗi compile/test trước khi đi sâu vào review chi tiết logic.

### Bước 3: Rà soát Kiến trúc & Phân tầng (Architecture Compliance)
Đối chiếu các file sửa đổi với cấu trúc phân tầng bắt buộc:
- **Frontend Flutter:**
  - `Widget/Screen` (Presentation) ➜ `Controller (ChangeNotifier)` ➜ `Repository` ➜ `ApiClient` ➜ Backend REST API.
  - Tuyệt đối không import `cloud_firestore` hoặc gọi HTTP trực tiếp trong Widget hoặc Controller.
- **Backend Cloud Functions:**
  - `Route` (`routes/`) ➜ `Middleware` (Auth, Zod) ➜ `Service` (`services/`) ➜ `Repository` (`repositories/`) ➜ Firestore.
  - Tuyệt đối không để Route xử lý logic DB, không để Repository nhận Express `req`/`res`.

### Bước 4: Kiểm tra Lỗ hổng & Edge Cases theo Ma trận Rủi ro
Sử dụng Bộ Checklist Chuyên sâu ở Mục 3 để rà soát chi tiết từng dòng mã nguồn.

### Bước 5: Lập Báo cáo Review Chi tiết
Tổng hợp kết quả review theo **Khuôn mẫu Chuẩn ở Mục 4**.

---

## 3. Bộ Checklist Review Chuyên sâu theo Từng Tầng

### 3.1. Frontend Flutter — Widgets & Màn hình (`lib/**/presentation/screens|widgets`)

- [ ] **Tách biệt Logic & Giao diện:**
  - Widget chỉ chịu trách nhiệm dựng UI và nhận tương tác người dùng.
  - Không khởi tạo HTTP request, không chứa câu lệnh query Firestore, không tính toán bảng xếp hạng trực tiếp trong hàm `build()`.
- [ ] **Bảo vệ BuildContext bất đồng bộ (Async Mounted Guard):**
  - Sau mọi câu lệnh `await` (gọi controller, dialog, async action), **bắt buộc** phải kiểm tra `if (!mounted) return;` trước khi sử dụng `context` (Navigator, ScaffoldMessenger, Theme).
  ```dart
  // ❌ SAI (Dễ crash khi user pop màn hình trước khi API trả về)
  await controller.bookField(fieldId, slot);
  Navigator.of(context).pop();

  // ✅ ĐÚNG
  await controller.bookField(fieldId, slot);
  if (!context.mounted) return;
  Navigator.of(context).pop();
  ```
- [ ] **Đủ 4 trạng thái giao diện (UI States):**
  - Mọi màn hình tải dữ liệu phải xử lý trọn vẹn:
    1. `LoadingState`: Hiển thị Skeleton hoặc `CircularProgressIndicator`.
    2. `EmptyState`: Hiển thị hình minh họa/icon + thông điệp tiếng Việt thân thiện khi không có dữ liệu.
    3. `ErrorState`: Thông báo lỗi rõ ràng kèm nút "Thử lại" (Retry CTA).
    4. `DataState`: Hiển thị danh sách hoặc nội dung chính.
- [ ] **Thiết kế & Design System:**
  - Tuân thủ Material 3 và sử dụng tokens từ [AppTheme](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/lib/core/theme/): `Theme.of(context).colorScheme`, spacing và typography chuẩn.
  - Không hardcode màu sắc kiểu `Color(0xFF2E7D32)` rải rác; không hardcode kích thước tùy tiện.
- [ ] **Chống Double Submission (Chặn bấm liên tục):**
  - Nút bấm (PrimaryButton / CTA) phải bị disable khi controller đang trong trạng thái `isLoading`.
- [ ] **Tối ưu Widget Tree:**
  - Sử dụng từ khóa `const` ở tất cả các Constructor của Widget tĩnh để tránh re-build lãng phí.
  - Tách các Widget con phức tạp thành các file riêng biệt thay vì viết hàm trả về `Widget _buildItem()`.

---

### 3.2. Frontend Flutter — Controllers & Quản lý Trạng thái (`presentation/controllers/`)

- [ ] **Quản lý vòng đời bất đồng bộ:**
  - Luôn quản lý cờ `bool _isLoading` đúng cách: bật `true` trước khi gọi async và **luôn đưa về `false` trong khối `finally`**.
  ```dart
  // ✅ ĐÚNG
  Future<void> submit() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.submit(...);
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Có lỗi xảy ra, vui lòng thử lại';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  ```
- [ ] **Phòng chống Memory Leak:**
  - Khi Controller có `StreamSubscription`, `TextEditingController`, hoặc `ScrollController`, phải hủy đăng ký hoặc `dispose()` trong hàm `dispose()` của Controller.
- [ ] **Không phụ thuộc UI Framework trong Controller:**
  - Controller không được import `package:flutter/material.dart` chỉ để nhận `BuildContext`. Controller phải hoàn toàn độc lập với UI.

---

### 3.3. Frontend Flutter — Repositories & API Client (`data/` & `core/api/`)

- [ ] **Chuẩn hóa Xử lý Lỗi (Exception Handling):**
  - Mọi phản hồi lỗi từ server hoặc lỗi mạng phải được chuyển đổi thành `ApiException` có thông điệp tiếng Việt rõ ràng.
  - Tuyệt đối không nuốt exception im lặng (`catch (e) {}` không làm gì).
- [ ] **Serialization / Deserialization an toàn:**
  - Các hàm `fromJson` / `toMap` phải có fallback an toàn, tránh bị crash `TypeError` khi server trả về `null` hoặc thiếu field.

---

### 3.4. Backend Cloud Functions — Routes & Middleware (`functions/src/routes|middleware/`)

- [ ] **Tiền tố & Định tuyến chuẩn:**
  - Mọi route nằm dưới `/api/v1/...`. Danh từ số nhiều, chữ thường (ví dụ: `/api/v1/pitches`, `/api/v1/tournaments`).
- [ ] **Xác thực & Phân quyền bắt buộc (Authentication & RBAC):**
  - Các endpoint thay đổi dữ liệu (POST, PUT, PATCH, DELETE) phải được bảo vệ bởi middleware `requireAuth`.
  - Nếu endpoint yêu cầu vai trò cụ thể (ví dụ: chỉ Organizer mới được tạo giải), phải có middleware `requireRoles(['organizer', 'admin'])`.
- [ ] **Validate đầu vào với Zod:**
  - Mọi dữ liệu nhận từ Client (`req.body`, `req.params`, `req.query`) **bắt buộc** phải được validate qua schema Zod bằng `validateRequest(...)`.
  - Kiểm tra kỹ: chuỗi rỗng, số âm (ví dụ: tỷ số không âm, giá sân > 0), định dạng ngày giờ, enum hợp lệ.
- [ ] **Không chứa Business Logic:**
  - Route chỉ làm nhiệm vụ: `Đón Request ➜ Gọi Middleware ➜ Gọi Service ➜ Trả Standard Response`. Không viết query Firestore trực tiếp trong Route.

---

### 3.5. Backend Cloud Functions — Services & Domain Logic (`functions/src/services/`)

- [ ] **Kiểm tra Quyền Sở hữu Dữ liệu (Chống lỗ hổng IDOR):**
  - Khi thao tác trên một tài nguyên (ví dụ cập nhật giải đấu, hủy đơn đặt sân, cập nhật kết quả):
  - Service **bắt buộc** phải đọc tài nguyên lên và kiểm tra xem người gửi yêu cầu (`req.user.id`) có phải là chủ sở hữu (`organizerId`, `userId`, `captainId`) hoặc `admin` hay không.
  - Không tin tưởng `userId` hoặc `role` gửi lên trong request body.
- [ ] **Kiểm soát Xung đột Đồng thời (Concurrency Control with Transactions):**
  - **Duyệt đội tham gia giải:** Bắt buộc dùng `db.runTransaction` để kiểm tra số lượng đội đã duyệt hiện tại `< maxTeams` trước khi duyệt thêm đội mới.
  - **Đặt sân bóng (Slot Locking):** Bắt buộc dùng Transaction để kiểm tra xem khung giờ (`date`, `startTime`, `endTime`, `pitchId`) đã có booking nào `confirmed` hoặc `pending` chưa trước khi ghi nhận đơn mới.
- [ ] **Toàn vẹn Dữ liệu Bóng đá (Football Domain Rules):**
  - **Lịch thi đấu (Schedule):** Khi tạo lại lịch, phải bảo toàn kết quả của các trận đã đấu (`status == 'finished'`). Không được xóa sạch ghi đè làm mất tỷ số cũ.
  - **Bảng xếp hạng (Standings):** Khi có kết quả trận đấu mới, phải tự động tính toán lại BXH theo đúng thứ tự ưu tiên: Điểm (3-1-0) ➜ Hiệu số bàn thắng bại ➜ Số bàn thắng ghi được ➜ Đối đầu trực tiếp.
  - **Ghi nhật ký kiểm toán (Match Audits):** Mọi thao tác sửa tỷ số phải ghi lại bản ghi audit vào collection `match_audits` (lưu ai sửa, lúc nào, tỷ số cũ, tỷ số mới).

---

### 3.6. Backend Cloud Functions — Repositories & Firestore Access (`functions/src/repositories/`)

- [ ] **Cô lập Data Access Layer:**
  - Repositories chỉ tương tác với Firestore DB và chuyển đổi qua lại giữa Firestore Document và TypeScript Data Interface.
  - Tuyệt đối không nhận `req`, `res` của Express vào repository.
- [ ] **Tối ưu hóa Truy vấn & Index:**
  - Tránh các câu truy vấn dẫn đến N+1 queries.
  - Các truy vấn kết hợp nhiều `where` và `orderBy` phải có composite index tương ứng trong [firestore.indexes.json](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/firestore.indexes.json).

---

### 3.7. Bảo mật, Security Rules & Ngăn chặn Rò rỉ Thông tin

- [ ] **Firestore Rules Default Deny:**
  - Kiểm tra [firestore.rules](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/firestore.rules).
  - Đảm bảo client **không được phép ghi trực tiếp** (`allow write: if false;`) vào các collection nghiệp vụ cốt lõi. Mọi thay đổi phải đi qua Cloud Functions.
- [ ] **Không Rò rỉ Bí mật (No Secret Leaks):**
  - Không commit file `.env`, file Google Cloud Service Account `*.json`, Android Keystore `*.keystore` / `key.properties`.
  - Không log token JWT, password, hoặc PII (thông tin cá nhân nhạy cảm) vào Cloud Logging hoặc `console.log`.

---

## 4. Khuôn mẫu Báo cáo Review Chuẩn (Review Output Template)

Khi thực hiện review, hãy xuất kết quả dưới dạng Markdown theo mẫu chuẩn sau:

```markdown
# 📋 Báo cáo Đánh giá Mã nguồn (Code Review Report)

### 📌 Thông tin Tổng quan
- **Nhánh / Phạm vi Review:** `<Tên nhánh hoặc danh sách file>`
- **Người thực hiện:** `<Tên hoặc Agent>`
- **Kết luận chung:** 🟢 SẴN SÀNG MERGE | 🟠 CẦN ĐIỀU CHỈNH | 🔴 CHẶN MERGE (BLOCKERS)

---

### 📊 Bảng tổng kết phát hiện (Summary Table)

| Mức độ | Số lượng | Mô tả tóm tắt |
|---|:---:|---|
| 🔴 **BLOCKER** | 0 | Không có lỗi nghiêm trọng gây crash hoặc hổng bảo mật |
| 🟠 **MAJOR** | 1 | Cần bổ sung mounted check sau await trong màn hình X |
| 🟡 **MINOR** | 2 | Cần thêm const widget và sửa naming convention |
| 🟢 **NIT / PRAISE** | 1 | Xử lý transaction đặt sân rất chặt chẽ |

---

### 🔍 Chi tiết từng phát hiện & Đề xuất khắc phục

#### 1. [🟠 MAJOR] Thiếu mounted check trước khi đóng màn hình
- **Tệp:** `lib/features/booking/presentation/screens/pitch_booking_screen.dart` (Dòng 142)
- **Vấn đề:** Sau lệnh `await controller.confirmBooking(...)`, mã nguồn gọi trực tiếp `Navigator.of(context).pop()` mà không kiểm tra `context.mounted`. Nếu người dùng ấn nút Back hoặc thoát màn hình trong lúc mạng chậm, app sẽ bị throw warning hoặc crash runtime.
- **Khắc phục đề xuất:**
```diff
- await controller.confirmBooking(slotId);
- Navigator.of(context).pop();
+ await controller.confirmBooking(slotId);
+ if (!context.mounted) return;
+ Navigator.of(context).pop();
```

#### 2. [🔴 BLOCKER] Thiếu Transaction kiểm tra số đội tối đa khi duyệt giải đấu
- **Tệp:** `functions/src/services/registration.service.ts` (Dòng 88)
- **Vấn đề:** Đang dùng `db.collection('registrations').doc(id).update({ status: 'approved' })` trực tiếp mà không đọc lại số lượng đội `approved` trong transaction. Khi 2 Organizer duyệt cùng lúc có thể vượt quá `tournament.maxTeams`.
- **Khắc phục đề xuất:** Sử dụng `db.runTransaction` để đọc số lượng đội `approved` hiện tại và throw lỗi `MAX_TEAMS_REACHED` nếu đã đủ số lượng.

---

### 💡 Lời khuyên & Bước tiếp theo
- Chạy lại lệnh: `flutter test && dart analyze lib test` sau khi sửa các lỗi trên.
- [ ] Đã sửa tất cả BLOCKERs
- [ ] Đã kiểm tra lại trên thiết bị / local emulator
```

---

## 5. Kịch bản Tự động Kiểm tra Nhanh (Quick Verification Command)

Reviewer có thể chạy script kiểm tra nhanh toàn bộ project từ thư mục gốc:

```powershell
# Chạy trên Windows PowerShell
# 1. Kiểm tra Flutter Analyzer & Tests
cd ballhub
flutter pub get
dart analyze lib test
flutter test

# 2. Kiểm tra Backend Build & Tests
cd functions
npm run build
npm test
```
