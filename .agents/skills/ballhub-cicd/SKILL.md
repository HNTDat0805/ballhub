---
name: ballhub-cicd
description: >-
  Cẩm nang tự động hóa quy trình CI/CD (Tích hợp và Triển khai liên tục) cho dự án Ballhub.
  Kích hoạt skill này khi cấu hình hoặc kiểm tra GitHub Actions workflows, tự động chạy kiểm thử
  (Backend integration tests & Flutter widget tests), phân tích mã tĩnh (dart analyze & linting),
  biên dịch gói cài đặt di động (Android APK / AAB) và tự động deploy Firebase Cloud Functions,
  Firestore Security Rules & Composite Indexes lên môi trường Production.
---

# Ballhub CI/CD Automation & Deployment Skill

Tài liệu hướng dẫn quy chuẩn thiết lập và vận hành hệ thống **CI/CD (Continuous Integration / Continuous Deployment)** cho dự án Quản lý bóng đá **Ballhub**, tích hợp **GitHub Actions**, **Flutter SDK**, và **Firebase CLI**.

---

## 1. Kiến trúc Tổng thể Đường ống CI/CD

Đường ống (Pipeline) của Ballhub được chia làm 3 pha độc lập nhưng liên kết chặt chẽ:

```text
[Push / Pull Request to main]
            │
    ┌───────┴───────────────────────┐
    ▼                               ▼
[1. Backend CI Workflow]    [2. Frontend CI Workflow]
  - Node.js 20.x              - Flutter SDK 3.x
  - npm ci                    - flutter pub get
  - TypeScript build          - dart analyze lib test
  - Run 17 Integration Tests  - flutter test
    │                               │
    └───────┬───────────────────────┘
            ▼ (Chỉ khi cả 2 CI Passed)
[3. CD & Release Workflow]
    ├── Firebase Deploy:
    │     ├── Firestore Security Rules (`firestore.rules`)
    │     ├── Firestore Composite Indexes (`firestore.indexes.json`)
    │     └── Cloud Functions Backend (`functions/`)
    └── Mobile App Artifacts Build:
          ├── Android APK (`flutter build apk --release`)
          └── Android App Bundle (`flutter build appbundle --release`)
```

---

## 2. Các GitHub Actions Workflows Mẫu

### 2.1. Backend CI (`.github/workflows/backend-ci.yml`)
Workflow chạy tự động khi có code thay đổi trong thư mục `functions/**`:
```yaml
name: Backend CI (Cloud Functions)

on:
  push:
    paths:
      - 'functions/**'
      - 'firestore.rules'
      - 'firestore.indexes.json'
  pull_request:
    paths:
      - 'functions/**'

jobs:
  test-and-build:
    name: Backend Test & Build
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20.x
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json

      - name: Install Dependencies
        working-directory: functions
        run: npm ci

      - name: Compile TypeScript
        working-directory: functions
        run: npm run build

      - name: Run Integration Tests
        working-directory: functions
        run: npm test
```

### 2.2. Frontend CI (`.github/workflows/frontend-ci.yml`)
Workflow kiểm tra chất lượng mã nguồn Dart và Flutter:
```yaml
name: Frontend CI (Flutter)

on:
  push:
    paths:
      - 'lib/**'
      - 'test/**'
      - 'pubspec.yaml'
  pull_request:
    paths:
      - 'lib/**'
      - 'test/**'

jobs:
  analyze-and-test:
    name: Flutter Analyze & Test
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Setup Java JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install Flutter Dependencies
        run: flutter pub get

      - name: Verify Code Formatting & Lints
        run: dart analyze lib test

      - name: Run Flutter Tests
        run: flutter test --coverage
```

### 2.3. CD Deploy Firebase & Build Release (`.github/workflows/deploy-production.yml`)
Workflow triển khai tự động lên Firebase Production khi merge vào nhánh `main`:
```yaml
name: Deploy Production & Build Artifacts

on:
  push:
    branches:
      - main

jobs:
  deploy-firebase:
    name: Deploy Cloud Functions & Rules
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20.x

      - name: Build Functions
        working-directory: functions
        run: |
          npm ci
          npm run build

      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions,firestore
        env:
          GCP_SA_KEY: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_BALLHUB }}

  build-android-release:
    name: Build Android APK Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Install Dependencies
        run: flutter pub get

      - name: Build Android Release APK
        run: flutter build apk --release --split-per-abi

      - name: Upload APK Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ballhub-release-apk
          path: build/app/outputs/flutter-apk/*.apk
```

---

## 3. Cấu hình Secrets và Biến môi trường

Các secrets cần thiết lập trong GitHub Repository Settings (`Settings > Secrets and variables > Actions`):

| Tên Secret | Mục đích sử dụng |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT_BALLHUB` | JSON Service Account của Google Cloud cấp quyền Admin Deploy |
| `FIREBASE_PROJECT_ID` | Định danh dự án Firebase (ví dụ: `ballhub-ac5a7`) |
| `ANDROID_KEYSTORE_BASE64` | File Keystore mã hóa base64 để ký số ứng dụng Android |
| `ANDROID_KEY_ALIAS` | Alias của Signing Key |
| `ANDROID_KEY_PASSWORD` | Mật khẩu của Signing Key |
| `ANDROID_STORE_PASSWORD` | Mật khẩu của Key Store |

---

## 4. Quy trình Release và Đánh số Phiên bản (Semantic Versioning)

1. **Cập nhật phiên bản trong [pubspec.yaml](file:///c:/Users/Admin/Downloads/do_an_mobile/ballhub/pubspec.yaml):**
   - Định dạng: `version: MAJOR.MINOR.PATCH+BUILD_NUMBER` (ví dụ: `1.0.1+2`).
2. **Commit và tạo Git Tag:**
   ```bash
   git add pubspec.yaml
   git commit -m "chore(release): bump version to 1.0.1"
   git tag -a v1.0.1 -m "Release version 1.0.1 - Quản lý giải đấu và đặt sân"
   git push origin main --tags
   ```

---

## 5. Quy trình Kiểm thử & Triển khai Cục bộ (Local Verification)

Trước khi đẩy commit lên GitHub, nhà phát triển cần kiểm tra tại máy cá nhân:

```bash
# 1. Kiểm tra Backend
cd functions
npm test
npm run build
cd ..

# 2. Kiểm tra Flutter
flutter test
dart analyze lib test

# 3. Thử nghiệm deploy Firebase (Dry run hoặc dùng Firebase CLI)
firebase deploy --only firestore:rules
firebase deploy --only functions
```

---

## 6. Kế hoạch Rollback khi gặp sự cố

1. **Rollback Cloud Functions:**
   - Trong Google Cloud Console > Cloud Functions: chọn hàm `api` > Khôi phục phiên bản Revision ổn định trước đó.
2. **Rollback Firestore Rules:**
   - Trong Firebase Console > Firestore > Rules: Lựa chọn lịch sử phiên bản (Rules history) và nhấn "Publish" bản sao lưu.
