# AGENTS.md — Quy tắc cho AI Agent/Codex trong Ballhub

Tài liệu này là hướng dẫn bắt buộc khi làm việc trong repository Ballhub. Người dùng là người mới học CNTT, vì vậy khi bàn giao cần giải thích ngắn gọn, bằng tiếng Việt, các quyết định kỹ thuật và thuật ngữ mới.

## 1. Tổng quan và architecture rules

- Frontend: Flutter, Dart 3.13.4, Material 3.
- Backend: Node.js 20, TypeScript, Express 4, Firebase Cloud Functions Gen 2, Firebase Admin SDK và Zod.
- Database chính: Cloud Firestore.
- Kiến trúc hiện tại phải được giữ nguyên: `UI -> Controller -> Repository -> REST API`; backend: `Route -> Service -> Repository -> Firestore`.
- Không tự ý thay đổi architecture hiện tại hoặc tạo architecture mới khi có thể tái sử dụng cấu trúc hiện có.
- Module mới là Booking / Football Field. Booking và `TournamentMatch` là hai domain khác nhau; tuyệt đối không biến `TournamentMatch` thành Booking.
- Không implement tính năng ngoài phạm vi yêu cầu hiện tại.
- Mọi thay đổi lớn (public API, schema, authentication, routing, dependency hoặc kiến trúc) phải giải thích impact và xin/chờ xác nhận trước khi implement.

## 2. Folder structure rules

- Giữ frontend theo feature-first:

  ```text
  lib/core/                         # thành phần dùng chung: API, auth, theme
  lib/features/tournament/          # module hiện có
  lib/features/<feature>/
    domain/                         # model và logic thuần nghiệp vụ
    data/                           # repository, API mapper/implementation
    presentation/                   # controller, screen, widget
  ```

- Giữ backend theo cấu trúc hiện có:

  ```text
  functions/src/routes/             # nhận HTTP request và điều hướng
  functions/src/services/           # business logic backend
  functions/src/repositories/       # truy cập Firestore
  functions/src/middleware/         # auth và validation
  functions/src/types/              # type, enum, interface dùng chung backend
  ```

- Không tạo duplicate component, service, model hoặc repository. Tìm và tái sử dụng phần phù hợp trước khi tạo file mới.

## 3. Naming conventions

- Dart file: `snake_case.dart`; TypeScript file giữ convention hiện có, ví dụ `booking.service.ts`.
- Class, enum, widget, controller, service, repository: `PascalCase`.
- Variable, method và parameter: `camelCase`.
- Dart private member bắt đầu bằng `_`.
- Route dùng danh từ số nhiều, chữ thường, ví dụ `/api/v1/bookings` và `/api/v1/fields`.
- Tên phải nêu rõ nghiệp vụ; tránh `Helper`, `Manager`, `Data` khi có tên cụ thể hơn.

## 4. Flutter/Dart conventions

- Widget chỉ chịu trách nhiệm hiển thị UI và nhận thao tác người dùng. Không đưa business logic, HTTP call, Firestore query hoặc API URL vào Widget.
- API call phải đi qua Repository; UI gọi Controller, Controller gọi Repository.
- Dùng model immutable với `final` fields khi có thể, null-safety và `const` widget khi phù hợp.
- Tách widget nhỏ nếu một phần UI có thể tái sử dụng hoặc làm `build()` khó đọc.
- Sau `await` trong `State`, kiểm tra `mounted` trước khi dùng `BuildContext`.
- Dùng `AppTheme` và Material 3 hiện có; không tự tạo style lặp lại nếu component/theme đã đáp ứng.
- Không hard-code API URL trong UI hoặc widget.

## 5. Backend TypeScript conventions

- Route chỉ nhận request, gắn middleware, gọi Service và trả response; không chứa business logic phức tạp.
- Service xử lý business rule, authorization theo sở hữu dữ liệu, transaction orchestration và các quyết định nghiệp vụ.
- Repository chỉ chịu trách nhiệm truy cập Firestore; không để HTTP hoặc Express object lọt vào Repository.
- Dùng type/interface/enum rõ ràng; tránh `any` trừ khi không thể tránh và có lý do.
- Giữ response thống nhất: thành công `{ success: true, data: ... }`; lỗi `{ success: false, error: { code, message, details? } }`.

## 6. Firestore conventions

- Cloud Firestore là database chính. Không xây module mới trên Firebase Realtime Database legacy/fallback nếu chưa được yêu cầu rõ.
- Trước khi thay schema, xác định collection, document/subcollection, field bắt buộc, kiểu dữ liệu, index, rule, migration và impact đến consumer.
- Không thay đổi database schema của module khác nếu không cần thiết và chưa đánh giá impact.
- Dùng transaction hoặc batch write cho thao tác cần tính nguyên tử, ví dụ chống trùng khung giờ booking.
- Cập nhật `firestore.rules` và `firestore.indexes.json` cùng thay đổi truy vấn/schema khi cần.
- Không hard-code dữ liệu production. Seed/mock data chỉ dùng cho test, emulator hoặc development-only code.

## 7. API conventions

- Giữ REST API dưới `/api/v1`.
- Không thay đổi endpoint, request/response contract hoặc status code hiện có nếu chưa kiểm tra frontend repository, backend test, tài liệu và consumer liên quan.
- Breaking change phải có migration/versioning hoặc backward compatibility rõ ràng.
- Mọi endpoint mới phải ghi rõ quyền truy cập, request, response, HTTP status và error code trong `docs/API_DOCUMENTATION.md`.
- Cấu hình API URL tập trung trong `ApiClient`, không nằm trong UI.

## 8. Repository rules

- Repository là cổng duy nhất để frontend truy cập REST API và backend truy cập Firestore.
- Mỗi repository có interface/contract rõ ràng ở layer phù hợp và không để UI phụ thuộc trực tiếp vào HTTP/Firestore implementation.
- Repository chỉ map dữ liệu, thực hiện truy cập dữ liệu và trả model/domain value; business rule phức tạp không nằm ở đây.
- Tái sử dụng `ApiClient`, error mapping và pattern repository hiện có trước khi tạo cơ chế mạng mới.

## 9. Service layer rules

- Backend Service là nơi xử lý business logic: kiểm tra điều kiện nghiệp vụ, kiểm tra quyền sở hữu, chống conflict và điều phối transaction.
- Flutter Controller điều phối trạng thái UI (loading, error, filter) và gọi Repository; không biến Controller thành nơi truy cập Firestore/HTTP trực tiếp.
- Không đặt business logic phức tạp trong Route, Widget, dialog hoặc Repository.

## 10. Controller rules

- Controller phải quản lý trạng thái UI rõ ràng: loading, data, empty và error.
- Controller không được phụ thuộc vào widget cụ thể hoặc `BuildContext`.
- Mỗi action bất đồng bộ phải chống gửi trùng phù hợp và luôn kết thúc loading state, kể cả khi lỗi.
- Thông báo lỗi trả về UI phải dễ hiểu, bằng tiếng Việt và không lộ dữ liệu kỹ thuật nhạy cảm.

## 11. Validation rules

- Validate ở frontend để phản hồi sớm và ở backend để bảo vệ dữ liệu; backend là nguồn quyết định cuối cùng.
- Validate request backend bằng Zod theo convention trong `functions/src/middleware/validate.middleware.ts`.
- Kiểm tra required field, chuỗi rỗng, enum, số âm, ngày/giờ, giới hạn số lượng và quan hệ dữ liệu trước khi ghi Firestore.
- Không dựa vào UI validation cho authorization, uniqueness hoặc chống tranh chấp dữ liệu.

## 12. Authentication và authorization rules

- Role hiện có: `admin`, `organizer`, `teamCaptain`, `player`, `viewer`.
- Không hard-code user role. Lấy role từ auth context/token đã được backend xác minh.
- Không tự ý sửa authentication, Firebase token flow, custom claims hoặc role model.
- Backend bảo vệ mutation bằng `requireAuth`, `requireRoles` và kiểm tra ownership trong Service khi phù hợp.
- Mock token và `x-user-*` header chỉ dành cho development/testing; không coi là cơ chế production.

## 13. Error handling rules

- Frontend dùng `ApiException` để chuẩn hóa lỗi HTTP/network; Controller chuyển lỗi thành trạng thái UI phù hợp.
- Backend trả status đúng ngữ nghĩa: 400 validation/input, 401 chưa xác thực, 403 không có quyền, 404 không tìm thấy, 409 xung đột, 500 lỗi không dự kiến.
- Không nuốt exception im lặng. Không hiển thị stack trace, secret hoặc cấu hình nội bộ cho người dùng.
- Luôn có loading state, error state, khả năng thử lại khi hợp lý và success feedback sau hành động thành công.

## 14. Testing rules

- Logic mới hoặc bugfix phải có test mới/điều chỉnh test tương ứng.
- Flutter: dùng `dart format`, `dart analyze lib test`, `flutter test` khi thay đổi Dart/Flutter.
- Backend: từ `functions/`, dùng `npm run build` và `npm test` khi thay đổi TypeScript backend.
- Sau mỗi task, chạy formatter/linter/build/test phù hợp với phạm vi thay đổi. Nếu không chạy được, nêu rõ command và lý do.
- Với task chỉ thay đổi Markdown/config không ảnh hưởng code, kiểm tra Markdown/diff là đủ; không giả vờ đã chạy compile/test không liên quan.

## 15. Security rules

- Áp dụng default-deny và quyền tối thiểu cho Firestore rules.
- Không commit secret, password, Firebase service account, token hoặc `.env` chứa dữ liệu nhạy cảm.
- Không log token, PII hoặc dữ liệu bảo mật.
- Không tin role, user ID hoặc ownership do client tự gửi; backend phải xác minh.
- Rà soát quyền cho mọi API tạo/sửa/xóa và cấu hình CORS an toàn khi production.

## 16. UI/UX rules

- Thiết kế mobile-first, Material 3, sạch, hiện đại theo phong cách ứng dụng đặt sân thể thao premium nhưng dễ dùng.
- Dùng spacing nhất quán, phân cấp thị giác rõ, nút hành động dễ nhận biết và component có thể tái sử dụng.
- Mỗi màn hình tương tác phải có loading, empty, error, disabled state và success feedback phù hợp.
- Nội dung UI dùng tiếng Việt rõ ràng, tránh thuật ngữ kỹ thuật không giải thích.
- Hành động phá hủy như xóa/hủy phải yêu cầu xác nhận.

### 16.1. Booking UI/UX rules

- Booking UI bắt buộc dùng Material 3, mobile-first và sports booking visual language: rõ ràng, nhanh để quét thông tin, hiện đại nhưng không nhiều decoration.
- Ưu tiên **information hierarchy hơn decoration**: người dùng phải nhận ra lần lượt sân, ngày, khung giờ, giá/trạng thái (nếu có) và CTA chính mà không cần đọc toàn bộ màn hình.
- Dùng design token từ `AppTheme` trước khi thêm giá trị mới. Spacing, typography, border radius và elevation phải nhất quán giữa các màn hình; không hard-code kích thước, màu, radius hoặc elevation tùy tiện trong từng widget.
- Dùng tương phản dễ đọc và phân cấp typography nhất quán cho tiêu đề, thông tin chính, metadata và trạng thái. Không dùng màu sắc là cách duy nhất để truyền đạt trạng thái.
- CTA booking phải có nhãn hành động cụ thể, ví dụ “Chọn khung giờ”, “Tiếp tục đặt sân”, “Xác nhận đặt sân”; vị trí và trạng thái enabled/disabled phải rõ ràng.
- Form validation phải hiển thị lỗi ngay gần field tương ứng, bằng thông điệp có thể hành động; không chỉ báo lỗi chung ở đầu/cuối form.
- Loading phải có feedback nhìn thấy được và không cho gửi trùng. API error phải chuyển thành thông báo thân thiện, nêu hướng xử lý hoặc thao tác thử lại khi phù hợp.

#### Booking components tái sử dụng

- Thiết kế `FieldCard`, `SearchBar`, `FilterChip`, `DateSelector`, `TimeSlot`, `BookingCard`, `BookingStatusBadge`, `PrimaryButton`, `EmptyState`, `LoadingState` và `ErrorState` theo hướng reusable, nhận dữ liệu/callback qua parameter thay vì tự gọi HTTP hoặc chứa business logic.
- Kiểm tra component/theme hiện có trước khi tạo component mới. Chỉ tạo biến thể booking khi component chung không đáp ứng đúng nghĩa nghiệp vụ.
- `FieldCard` ưu tiên tên sân, vị trí, thông tin quyết định đặt sân và CTA; không nhồi decoration làm che thông tin.
- `BookingCard` phải hiển thị rõ sân, ngày, giờ, booking state và hành động khả dụng.
- `EmptyState`, `LoadingState`, `ErrorState` cần có icon/visual vừa đủ, nội dung ngắn gọn và CTA thử lại hoặc điều hướng hợp lý khi cần.

#### TimeSlot states

`TimeSlot` phải biểu đạt rõ cả bằng text/icon và kiểu hiển thị các trạng thái sau:

| State | Ý nghĩa UI | Hành vi |
|---|---|---|
| `AVAILABLE` | Có thể đặt | Có thể chọn; hiện nhãn hoặc icon cho biết còn trống |
| `SELECTED` | Người dùng đã chọn | Nổi bật rõ ràng, có nhãn “Đã chọn” và có thể bỏ chọn |
| `BOOKED` | Đã có người đặt | Không thể chọn; có nhãn “Đã đặt” |
| `BLOCKED` | Chủ sân/hệ thống khóa | Không thể chọn; có nhãn “Không khả dụng” hoặc lý do phù hợp |
| `DISABLED` | Tạm không thao tác được | Không thể chọn; vẫn phải giữ độ tương phản và lý do khi cần |

- Không chỉ đổi màu `TimeSlot` để biểu đạt state. Kết hợp text; dùng icon và semantic label/tooltip khi hữu ích.
- Mọi trạng thái disabled/blocked/booked phải có lý do hoặc nhãn rõ để người dùng hiểu vì sao không thể chọn.

## 17. Accessibility rules

- Bảo đảm tương phản chữ/nền đủ rõ; không chỉ dùng màu để truyền đạt trạng thái.
- Badge/trạng thái phải có nhãn chữ hoặc icon có tooltip/semantic label.
- Hỗ trợ cỡ chữ hệ thống và tránh layout dễ tràn trên màn hình nhỏ.
- Vùng chạm của button/icon phải đủ lớn, label rõ ràng và thứ tự focus hợp lý.
- Với icon không có text, cung cấp tooltip hoặc semantics phù hợp.

## 18. Git safety rules

- Trước khi sửa, kiểm tra `git status` và giữ nguyên thay đổi không thuộc task của người khác.
- Không tự ý xóa code đang hoạt động, `git reset --hard`, `git checkout --`, ghi đè hoặc xóa hàng loạt file.
- Commit phải nhỏ, độc lập, dùng Conventional Commits và chỉ tạo commit khi người dùng yêu cầu.
- Không gộp refactor không liên quan vào cùng thay đổi tính năng/bugfix.

## 19. Rules khi sửa module Tournament

- Không sửa module `lib/features/tournament/` hoặc backend tournament nếu không thật sự cần thiết cho task.
- Không biến `TournamentMatch` thành Booking và không thêm field booking vào match chỉ vì tiện lợi.
- Không thay đổi tournament API, Firestore schema, rules, service hoặc repository nếu chưa phân tích đầy đủ dependency và impact.
- Ưu tiên tích hợp lỏng: nếu Booking cần liên hệ với trận đấu, dùng reference rõ ràng giữa hai domain thay vì gộp model.

## 20. Rules khi nhiều developer cùng sửa project

- Đọc đủ file, dependency và lịch sử thay đổi liên quan trước khi sửa code của thành viên khác.
- Giới hạn diff đúng phạm vi task; không format hàng loạt hoặc refactor code không liên quan.
- Bảo toàn style, naming, test và fallback đang hoạt động trừ khi có lý do kỹ thuật rõ ràng.
- Nếu phát hiện thay đổi đang dang dở hoặc conflict, dừng phần có rủi ro và báo rõ file, tác động và lựa chọn xử lý.
- Khi bàn giao, luôn liệt kê file tạo/sửa, lý do, hành vi thay đổi, cách kiểm tra và lỗi/rủi ro còn lại.
