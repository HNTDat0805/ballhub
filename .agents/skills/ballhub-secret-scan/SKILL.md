---
name: ballhub-secret-scan
description: >-
  Cẩm nang và quy trình rà soát, phát hiện và phòng chống lộ lọt API Keys, Secrets, Token,
  Private Keys, Service Account JSON và Keystore trước khi commit hoặc push code lên GitHub cho dự án Ballhub.
  Kích hoạt skill này khi chuẩn bị commit/push mã nguồn, kiểm tra an toàn tệp .gitignore, rà soát hardcoded credentials,
  thiết lập Git pre-commit hooks hoặc xử lý khẩn cấp khi nghi ngờ lộ thông tin nhạy cảm.
---

# Ballhub Secret Scanning & Pre-Push Leak Prevention Skill

Cẩm nang chuyên biệt giúp kỹ sư phát hiện, ngăn chặn và xử lý triệt để nguy cơ rò rỉ **Secrets, API Keys, Private Credentials, Service Accounts và Keystores** lên GitHub công khai hoặc nội bộ trong dự án **Ballhub** (Flutter, Firebase, Node.js).

---

## 1. Danh mục Các Thông tin Nhạy cảm Tuyệt đối KHÔNG ĐƯỢC Commit

| Loại thông tin | Mẫu tệp / Định dạng nhận diện | Rủi ro nếu bị lộ |
|---|---|---|
| **Google Cloud Service Account** | `*.json` có chứa `"type": "service_account"` và `"private_key"` | Kẻ xấu chiếm quyền quản trị toàn bộ Firebase, đọc/ghi/xóa toàn bộ database |
| **Android Keystore & Signing Passwords** | `key.properties`, `*.keystore`, `*.jks` | Bị giả mạo chữ ký số ứng dụng, kẻ xấu có thể cập nhật mã độc lên máy người dùng |
| **iOS Certificates & Profiles** | `*.p12`, `*.mobileprovision`, `ExportOptions.plist` | Mất quyền kiểm soát phân phối ứng dụng iOS |
| **Biến môi trường Secrets** | `.env`, `.env.local`, `.env.production`, `functions/.runtimeconfig.json` | Lộ các khóa bí mật backend, webhook secrets, database credentials |
| **Payment Gateway Secrets** | Stripe Secret Key (`sk_live_...`), MoMo / VNPay / ZaloPay Secret Key | Thao tác rút tiền, làm sai lệch hóa đơn thanh toán tiền sân bóng / lệ phí giải |
| **Private Keys & SSH Keys** | `*.pem`, `*.key`, `id_rsa`, `id_ed25519` | Xâm nhập máy chủ hạ tầng |
| **Hardcoded Admin Tokens / Secrets** | Chuỗi bí mật hardcode trong `.dart` hoặc `.ts` | Vượt cơ chế xác thực API |

> [!NOTE]
> **Phân biệt giữa API Key công khai và Bí mật:**
> - Trong Flutter Firebase, `apiKey` trong [firebase_options.dart](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/lib/firebase_options.dart) là Firebase Web/App Client Identifier (chỉ dùng để định danh dự án, được bảo vệ bằng Firestore Rules).
> - Tuy nhiên, **Service Account Private Key**, **Cloud Secret Key**, **Stripe Secret**, và **Database Passwords** là bí mật tối mật, TUYỆT ĐỐI không bao giờ được commit.

---

## 2. Checklist Rà soát Trước khi Commit & Push (`git push`)

Thực hiện lần lượt 5 bước kiểm tra bắt buộc:

### Bước 1: Kiểm tra trạng thái Git Staging
```bash
# Xem danh sách các file đang chuẩn bị commit
git status -s

# Đảm bảo KHÔNG CÓ các file sau nằm trong vùng Staged (xanh lá):
# - .env hoặc .env.*
# - service-account*.json hoặc bất kỳ file .json nào chứa credentials
# - key.properties hoặc *.keystore / *.jks
# - functions/.runtimeconfig.json
```

### Bước 2: Rà soát Diff nội dung thay đổi
```bash
# Xem chi tiết từng dòng code sắp commit
git diff --cached

# Tìm kiếm xem có dòng nào vô tình paste private key, secret token hoặc password
```

### Bước 3: Kiểm tra tệp `.gitignore`
Đảm bảo [ballhub/.gitignore](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/.gitignore) đã chứa đầy đủ các mẫu loại trừ:
```gitignore
# Environment & Secrets
.env
.env.*
!.env.example
functions/.runtimeconfig.json

# Service Accounts & Private Keys
*service-account*.json
*service_account*.json
*.pem
*.key
*.p12

# Android Signing
android/key.properties
*.keystore
*.jks

# iOS Secrets
ios/Pods/
*.mobileprovision

# Firebase Logs
firebase-debug.log*
firestore-debug.log*
ui-debug.log*
```

### Bước 4: Chạy Script Tự động Quét Secrets Cục bộ
Chạy script quét tự động được tích hợp sẵn trong skill:
```powershell
# Chạy script quét nhanh toàn bộ repository
powershell -ExecutionPolicy Bypass -File .agents/skills/ballhub-secret-scan/scripts/scan_secrets.ps1
```
*Script sẽ kiểm tra toàn bộ cây thư mục và cảnh báo ngay lập tức nếu phát hiện chuỗi regex nghi vấn hoặc file nhạy cảm.*

### Bước 5: Cài đặt Git Pre-Commit Hook (Khuyên dùng)
Tự động ngăn chặn lệnh `git commit` nếu phát hiện có secret:
```powershell
powershell -ExecutionPolicy Bypass -File .agents/skills/ballhub-secret-scan/scripts/install_pre_commit.ps1
```

---

## 3. Các Biểu thức Chính quy (Regex Patterns) Nhận diện Secrets

Khi rà soát mã nguồn hoặc commit log, các pattern sau cần được gắn cờ báo động đỏ:

| Tên mẫu nhận diện | Biểu thức Regex |
|---|---|
| **Google Service Account JSON** | `"type"\s*:\s*"service_account"\|"private_key"\s*:\s*"-----BEGIN PRIVATE KEY` |
| **GCP / Firebase API Key** | `AIza[0-9A-Za-z\\-_]{35}` |
| **Stripe Live Secret Key** | `sk_live_[0-9a-zA-Z]{24}` |
| **Generic Secret/Password in Code** | `(?i)(password\|secret\|apiKey\|private_key\|jwt_secret)\s*[:=]\s*['"][^'"\s]{8,}['"]` |
| **RSA / OpenSSH Private Key** | `-----BEGIN (RSA \|EC \|OPENSSH \|DSA )?PRIVATE KEY-----` |
| **Slack / Discord Webhook** | `https://hooks.slack.com/services/T[a-zA-Z0-9_]+/B[a-zA-Z0-9_]+/[a-zA-Z0-9_]+` |

---

## 4. Giải pháp Quản lý Bí mật Đúng Chuẩn trong Ballhub

### 4.1. Phía Flutter Mobile
- **Không nhúng Secret vào source code:**
  - Nếu ứng dụng cần kết nối dịch vụ ngoài (Payment, Maps, v.v.), hãy định nghĩa qua `--dart-define` khi build:
    ```bash
    flutter run --dart-define=API_BASE_URL=https://... --dart-define=MAPS_KEY=xyz
    ```
  - Trong Dart, đọc bằng:
    ```dart
    const String apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5001/api/v1');
    ```

### 4.2. Phía Firebase Cloud Functions Backend
- **Sử dụng Google Cloud Secret Manager hoặc Firebase Functions Secrets:**
  ```typescript
  // Khai báo secret với Cloud Functions v2
  import { defineSecret } from 'firebase-functions/params';
  const paymentApiKey = defineSecret('PAYMENT_API_KEY');

  export const processPayment = onRequest({ secrets: [paymentApiKey] }, (req, res) => {
    const key = paymentApiKey.value();
    // Xử lý an toàn mà không lộ trong mã nguồn
  });
  ```

---

## 5. Quy trình Khẩn cấp khi Phát hiện ĐÃ LỠ PUSH Secret lên GitHub

Nếu một commit chứa Private Key / Secret vừa được đẩy (`push`) lên GitHub:

> [!CAUTION]
> **ĐỪNG CHỈ COMMIT ĐÈ LÊN ĐỂ XÓA!**
> Lịch sử Git vẫn lưu vết bản ghi cũ và bot quét tự động của hacker trên GitHub có thể thu thập secret chỉ trong vòng vài giây!

Thực hiện ngay lập tức 3 bước sau:

1. **BƯỚC 1: REVOKE & ROTATE KEY NGAY LẬP TỨC (Ưu tiên số 1):**
   - Đăng nhập vào Google Cloud Console / Firebase Console / Payment Dashboard.
   - **Xóa (Delete/Disable)** Service Account key hoặc API Key vừa bị lộ.
   - Tạo khóa mới thay thế. Khóa cũ bị vô hiệu hóa sẽ triệt tiêu khả năng tấn công của kẻ xấu.

2. **BƯỚC 2: XÓA FILE KHỎI TOÀN BỘ LỊCH SỬ GIT BẰNG `git-filter-repo` HOẶC BFG:**
   ```bash
   # Cài đặt git-filter-repo hoặc dùng BFG Repo-Cleaner
   git filter-repo --invert-paths --path đường-dẫn-tệp-lộ

   # Hoặc xóa commit gần nhất nếu chưa có ai pull (chỉ dùng khi vừa push nhánh riêng)
   git reset --soft HEAD~1
   git push origin main --force
   ```

3. **BƯỚC 3: KIỂM TOÁN HOẠT ĐỘNG (AUDIT LOG REVIEW):**
   - Vào Google Cloud Audit Logs kiểm tra xem trong khoảng thời gian key bị lộ có request bất thường nào (đọc trộm dữ liệu, tạo tài khoản lạ, gọi hàm lạ) hay không.
