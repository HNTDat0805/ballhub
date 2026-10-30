import '../domain/models/booking.dart';
import '../domain/models/field_slot.dart';
import '../domain/models/football_field.dart';

/// Định nghĩa contract (giao diện) cho tất cả thao tác booking qua REST API.
/// Implementation thực tế là [ApiBookingRepository].
///
/// Architecture: UI → Controller → BookingRepository → ApiClient → REST API
abstract interface class BookingRepository {
  // ───────── Field ─────────

  /// Lấy danh sách sân bóng có thể lọc theo city, district, fieldType, status, ownerId
  Future<List<FootballField>> getFields({
    String? city,
    String? district,
    String? fieldType,
    String? status,
    String? ownerId,
    String? search,
  });

  /// Lấy chi tiết một sân bóng theo ID
  Future<FootballField> getFieldById(String fieldId);

  /// Tạo sân mới (chỉ fieldOwner/admin)
  Future<FootballField> createField(Map<String, dynamic> data);

  /// Cập nhật thông tin sân (chỉ owner của sân)
  Future<FootballField> updateField(String fieldId, Map<String, dynamic> data);

  /// Cập nhật trạng thái sân (active/inactive/maintenance/archived)
  Future<FootballField> updateFieldStatus(String fieldId, String status);

  // ───────── Slot ─────────

  /// Lấy danh sách slot của một sân theo ngày (dateKey: YYYY-MM-DD)
  Future<List<FieldSlot>> getFieldSlots(String fieldId, {String? dateKey});

  /// Tạo slot mới cho sân
  Future<FieldSlot> createSlot(String fieldId, Map<String, dynamic> data);

  /// Cập nhật slot (giá, trạng thái)
  Future<FieldSlot> updateSlot(String fieldId, String slotId, Map<String, dynamic> data);

  /// Chủ sân khóa một slot
  Future<FieldSlot> blockSlot(String fieldId, String slotId, {String? reason});

  /// Chủ sân mở khóa một slot
  Future<FieldSlot> unblockSlot(String fieldId, String slotId);

  // ───────── Booking ─────────

  /// Tạo booking mới (user gửi fieldId + slotIds)
  Future<Booking> createBooking({
    required String fieldId,
    required List<String> slotIds,
    String? customerNote,
  });

  /// Lấy danh sách booking của user hiện tại
  Future<List<Booking>> getMyBookings();

  /// Lấy chi tiết một booking
  Future<Booking> getBooking(String bookingId);

  /// User hủy booking của mình
  Future<Booking> cancelBooking(String bookingId, {String? reason});

  // ───────── Owner Booking ─────────

  /// Chủ sân xem danh sách booking thuộc sân của mình
  Future<List<Booking>> getOwnerBookings();

  /// Chủ sân xác nhận booking
  Future<Booking> confirmBooking(String bookingId);

  /// Chủ sân từ chối booking (cần lý do)
  Future<Booking> rejectBooking(String bookingId, {required String reason});
}
