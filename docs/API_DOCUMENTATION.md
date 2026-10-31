# Ballhub Tournament Management API Specification (OpenAPI 3.0 / REST)

Phiên bản API: `v1`  
Base URL: `/api/v1`  
Định dạng dữ liệu: `application/json`

---

## 1. Xác thực & Phân quyền (Authentication & RBAC)

API sử dụng Firebase Authentication ID Token:
- Header bắt buộc với các endpoint yêu cầu đăng nhập:
  ```http
  Authorization: Bearer <FIREBASE_ID_TOKEN>
  ```
- Môi trường Local/Development hỗ trợ Dev Persona Headers:
  - `x-user-id`: ID người dùng (ví dụ: `user_organizer_01`, `user_captain_01`, `user_viewer_01`)
  - `x-user-role`: Vai trò (`admin`, `organizer`, `teamCaptain`, `player`, `viewer`)
  - `x-user-name`: Họ và tên hiển thị
  - `x-user-team`: Mã đội bóng quản lý (nếu là đội trưởng)

### Ma trận phân quyền:
| Endpoint | Quyền yêu cầu | Mô tả |
|---|---|---|
| `GET /tournaments` | Public / Khách | Xem danh sách giải đấu |
| `POST /tournaments` | `organizer`, `admin` | Tạo giải đấu mới |
| `GET /tournaments/:id` | Public / Khách | Xem chi tiết giải đấu |
| `PATCH /tournaments/:id` | `organizer` (chủ giải), `admin` | Cập nhật thông tin giải đấu |
| `DELETE /tournaments/:id` | `organizer` (chủ giải), `admin` | Xóa/Hủy giải đấu |
| `GET /tournaments/:id/registrations` | Public / Khách | Xem danh sách đội đăng ký |
| `POST /tournaments/:id/registrations` | `teamCaptain`, `organizer`, `admin` | Đăng ký đội tham gia |
| `PATCH /tournaments/:id/registrations/:regId` | `organizer`, `admin` | Duyệt / Từ chối đăng ký đội |
| `DELETE /tournaments/:id/registrations/:regId` | `teamCaptain` (chủ đội), `organizer`, `admin` | Hủy đăng ký đội |
| `POST /tournaments/:id/schedule` | `organizer`, `admin` | Tự động sinh lịch thi đấu |
| `GET /tournaments/:id/matches` | Public / Khách | Xem danh sách trận đấu |
| `GET /matches/:matchId` | Public / Khách | Xem chi tiết trận đấu |
| `PATCH /matches/:matchId` | `organizer`, `admin` | Điều chỉnh lịch thi đấu/địa điểm |
| `PUT /matches/:matchId/result` | `organizer`, `admin` | Nhập/cập nhật tỷ số và tự động tính lại BXH |
| `GET /tournaments/:id/standings` | Public / Khách | Xem bảng xếp hạng |
| `GET /tournaments/:id/audits` | Authenticated | Xem nhật ký điều chỉnh kết quả |

---

## 2. Danh sách Endpoint chi tiết

### 2.1. Quản lý giải đấu (Tournaments)

#### `POST /api/v1/tournaments`
Tạo mới giải đấu bóng đá.
- **Request Body:**
  ```json
  {
    "name": "Ballhub Super Cup 2026",
    "description": "Giải bóng đá phong trào tranh cúp vô địch",
    "bannerUrl": "https://example.com/banner.jpg",
    "location": "Sân vận động Thống Nhất, TP. Hồ Chí Minh",
    "startDate": "2026-11-01T08:00:00.000Z",
    "endDate": "2026-11-15T18:00:00.000Z",
    "registrationDeadline": "2026-10-28T23:59:59.000Z",
    "maxTeams": 8,
    "format": "roundRobinSingle", // "roundRobinSingle" | "roundRobinDouble" | "knockout"
    "status": "registrationOpen" // "preparing" | "registrationOpen" | "inProgress" | "completed" | "cancelled"
  }
  ```
- **Response 201 Created:**
  ```json
  {
    "success": true,
    "data": {
      "id": "tour_17109282910_abc12",
      "name": "Ballhub Super Cup 2026",
      "maxTeams": 8,
      "format": "roundRobinSingle",
      "status": "registrationOpen",
      "organizerId": "user_organizer_01",
      "organizerName": "Nguyễn Văn Quản Lý",
      "createdAt": "2026-10-20T08:00:00.000Z",
      "updatedAt": "2026-10-20T08:00:00.000Z"
    }
  }
  ```

#### `GET /api/v1/tournaments`
Lấy danh sách các giải đấu có hỗ trợ lọc và tìm kiếm.
- **Query Params:**
  - `status`: Lọc theo trạng thái (`registrationOpen`, `inProgress`, ...)
  - `search`: Tìm kiếm theo tên giải hoặc địa điểm.
- **Response 200 OK:**
  ```json
  {
    "success": true,
    "data": [ ... ],
    "count": 1
  }
  ```

#### `GET /api/v1/tournaments/{id}`
Xem chi tiết một giải đấu.

#### `PATCH /api/v1/tournaments/{id}`
Cập nhật thông tin giải đấu. Kiểm tra quyền sở hữu và ngăn đổi thể thức/số đội nếu giải đã bắt đầu.

#### `DELETE /api/v1/tournaments/{id}`
Xóa giải đấu (chỉ cho phép khi giải chưa diễn ra; nếu đang diễn ra phải chuyển trạng thái `cancelled`).

---

### 2.2. Đăng ký & Quản lý đội bóng (Registrations)

#### `POST /api/v1/tournaments/{id}/registrations`
Đăng ký đội bóng tham gia giải đấu.
- **Quy tắc nghiệp vụ:**
  - Giải đấu phải đang ở trạng thái `registrationOpen`.
  - Chưa quá thời hạn `registrationDeadline`.
  - Kiểm tra chống đăng ký trùng: một đội bóng không được đăng ký 2 lần vào cùng 1 giải.
  - Sử dụng Firestore Transaction để đảm bảo số đội được duyệt không bao giờ vượt quá `maxTeams` kể cả khi có nhiều request đồng thời.
- **Request Body:**
  ```json
  {
    "teamId": "team_sao_vang",
    "teamName": "FC Sao Vàng",
    "logoUrl": "https://example.com/logo.png",
    "captainName": "Trần Đội Trưởng",
    "captainPhone": "0901234567",
    "captainEmail": "captain1@ballhub.vn",
    "membersCount": 12
  }
  ```
- **Response 201 Created:** Trả về đối tượng đăng ký với trạng thái ban đầu (`pending` hoặc `approved` nếu BTC trực tiếp thêm).

#### `GET /api/v1/tournaments/{id}/registrations`
Lấy danh sách các đội đăng ký. Query param: `status=pending|approved|rejected|cancelled`.

#### `PATCH /api/v1/tournaments/{id}/registrations/{registrationId}`
Duyệt hoặc từ chối đội bóng (Chỉ Organizer/Admin).
- **Request Body:**
  ```json
  {
    "status": "approved", // "approved" | "rejected"
    "reviewNote": "Hồ sơ thành viên đầy đủ và hợp lệ"
  }
  ```

#### `DELETE /api/v1/tournaments/{id}/registrations/{registrationId}`
Hủy đăng ký đội (Đội trưởng hoặc Organizer/Admin).

---

### 2.3. Lịch thi đấu & Kết quả (Schedule & Matches)

#### `POST /api/v1/tournaments/{id}/schedule`
Tự động sinh lịch thi đấu theo thể thức giải đấu.
- **Quy tắc nghiệp vụ:**
  - Chỉ sinh lịch từ các đội đã được duyệt (`status == approved`).
  - Yêu cầu tối thiểu 2 đội bóng được duyệt.
  - Hỗ trợ thể thức vòng tròn 1 lượt (Berger Circle Method), vòng tròn 2 lượt (lượt đi/về) và loại trực tiếp (Knockout).
  - Tự động phân bổ số lượt đấu, thời gian và sân đấu.
  - Xử lý số đội lẻ thông qua cơ chế lượt nghỉ (BYE).
  - Bảo lưu các trận đấu đã có kết quả chính thức (Safe Merge).
  - Tự động chuyển trạng thái giải đấu sang `inProgress`.
- **Request Body:**
  ```json
  {
    "venue": "Sân vận động Thống Nhất"
  }
  ```

#### `GET /api/v1/tournaments/{id}/matches`
Xem danh sách trận đấu. Hỗ trợ lọc theo `round`, `status`, `teamId`.

#### `PUT /api/v1/matches/{matchId}/result`
Cập nhật tỷ số trận đấu chính thức (Chỉ Organizer/Admin).
- **Quy tắc nghiệp vụ:**
  - Kiểm tra tỷ số hợp lệ (không âm).
  - Kiểm tra giải đấu chưa kết thúc (`status != completed`).
  - Tự động ghi nhật ký điều chỉnh (`match_audits`) lưu vết người sửa, tỷ số cũ, tỷ số mới và lý do.
  - **TỰ ĐỘNG TÍNH LẠI BẢNG XẾP HẠNG:** Ngay khi tỷ số được ghi nhận, backend tự động tính toán lại điểm số, số trận, hiệu số và xếp hạng của tất cả các đội trong giải đấu và cập nhật vào collection `standings`.
- **Request Body:**
  ```json
  {
    "homeScore": 3,
    "awayScore": 1,
    "status": "finished",
    "isConfirmed": true,
    "notes": "Trận đấu diễn ra hấp dẫn",
    "reason": "Nhập tỷ số chính thức vòng 1"
  }
  ```
- **Response 200 OK:**
  ```json
  {
    "success": true,
    "data": { ... },
    "standings": [ ... ],
    "message": "Cập nhật tỷ số trận đấu và tự động tính lại bảng xếp hạng thành công."
  }
  ```

---

### 2.4. Bảng xếp hạng (Standings)

#### `GET /api/v1/tournaments/{id}/standings`
Lấy bảng xếp hạng giải đấu theo thời gian thực.
- **Tiêu chí xếp hạng chính thức:**
  1. Điểm số (Thắng = 3 điểm, Hòa = 1 điểm, Thua = 0 điểm)
  2. Hiệu số bàn thắng - bàn thua (`goalDifference = goalsFor - goalsAgainst`)
  3. Tổng số bàn thắng ghi được (`goalsFor`)
  4. Thành tích đối đầu trực tiếp giữa các đội bằng điểm (`head-to-head`)
  5. Thứ tự bảng chữ cái tên đội bóng.
- **Response 200 OK:**
  ```json
  {
    "success": true,
    "data": [
      {
        "rank": 1,
        "teamId": "team_sao_vang",
        "teamName": "FC Sao Vàng",
        "played": 1,
        "won": 1,
        "drawn": 0,
        "lost": 0,
        "goalsFor": 3,
        "goalsAgainst": 1,
        "goalDifference": 2,
        "points": 3
      },
      {
        "rank": 2,
        "teamId": "team_rong_do",
        "teamName": "FC Rồng Đỏ",
        "played": 1,
        "won": 0,
        "drawn": 0,
        "lost": 1,
        "goalsFor": 1,
        "goalsAgainst": 3,
        "goalDifference": -2,
        "points": 0
      }
    ],
    "count": 2
  }
  ```

---

### 2.5. Quản lý đội bóng & Thành viên (Teams & Members)

- `GET /api/v1/teams`: Tìm kiếm và lọc danh sách đội bóng (`keyword`, `area`).
- `GET /api/v1/teams/mine`: Lấy danh sách các đội bóng người dùng hiện tại đang tham gia (Authenticated).
- `GET /api/v1/teams/{id}`: Xem chi tiết thông tin đội bóng.
- `POST /api/v1/teams`: Tạo đội bóng mới. Người tạo tự động trở thành Đội trưởng (Captain).
- `PATCH /api/v1/teams/{id}`: Cập nhật thông tin đội bóng (chỉ Đội trưởng hoặc Admin).
- `GET /api/v1/teams/{id}/members`: Lấy danh sách thành viên đội bóng.
- `DELETE /api/v1/teams/{id}/members/{userId}`: Xóa thành viên khỏi đội (Đội trưởng/Admin) hoặc tự rời đội.
- `POST /api/v1/teams/{id}/join-requests`: Gửi yêu cầu xin gia nhập đội bóng.
- `GET /api/v1/teams/{id}/join-requests`: Lấy danh sách yêu cầu xin gia nhập đang chờ duyệt (Đội trưởng/Admin).
- `PATCH /api/v1/teams/{id}/join-requests/{requestId}`: Phê duyệt (`Approved`) hoặc từ chối (`Rejected`) yêu cầu gia nhập (Đội trưởng/Admin).

---

### 2.6. Cáp kèo tìm đối & Lời mời giao hữu (Matchmaking & Friendly Invitations)

- `GET /api/v1/matchmaking/opponents`: Thuật toán đề xuất các đội bóng đối thủ tiềm năng dựa trên tiêu chí cùng khu vực và hoạt động.
- `POST /api/v1/invitations`: Gửi lời mời giao hữu / thách đấu tới đội trưởng đội đối thủ.
- `GET /api/v1/invitations?teamId={teamId}`: Xem danh sách lời mời giao hữu đã gửi hoặc nhận của đội bóng.
- `PATCH /api/v1/invitations/{id}`: Phản hồi lời mời giao hữu (`Accepted`, `Declined`, hoặc `Cancelled`).

---

### 2.7. Quản lý hồ sơ người dùng (User Profile & Avatar)

- `GET /api/v1/users/me`: Lấy thông tin chi tiết hồ sơ cá nhân của người dùng hiện tại.
- `PATCH /api/v1/users/me`: Cập nhật họ tên, số điện thoại, vị trí thi đấu, khu vực.
- `POST /api/v1/users/me/avatar`: Cập nhật ảnh đại diện (Base64 chuỗi ảnh tối đa 700KB).
