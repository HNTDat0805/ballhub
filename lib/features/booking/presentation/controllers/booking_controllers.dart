import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../data/booking_repository.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/field_slot.dart';
import '../../domain/models/football_field.dart';

/// Controller quản lý state UI cho toàn bộ Booking feature.
///
/// Phân trách nhiệm:
/// - [FieldListController] : danh sách sân + search/filter
/// - [FieldDetailController]: chi tiết sân + slots theo ngày
/// - [SlotSelectionController]: chọn slot liên tiếp + tính tiền
/// - [BookingListController]: danh sách booking của user
/// - [OwnerBookingController]: owner quản lý booking

// ─────────────────────────────────────────────────────────────────────────────
// FieldListController
// ─────────────────────────────────────────────────────────────────────────────

class FieldListController extends ChangeNotifier {
  final BookingRepository _repo;

  FieldListController({required BookingRepository repository}) : _repo = repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<FootballField> _fields = [];
  String _searchQuery = '';
  String? _cityFilter;
  String? _fieldTypeFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FootballField> get fields => _fields;
  String get searchQuery => _searchQuery;
  String? get cityFilter => _cityFilter;
  String? get fieldTypeFilter => _fieldTypeFilter;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCityFilter(String? city) {
    _cityFilter = city;
    notifyListeners();
  }

  void setFieldTypeFilter(String? type) {
    _fieldTypeFilter = type;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadFields() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _fields = await _repo.getFields(
        city: _cityFilter,
        fieldType: _fieldTypeFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: 'active',
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách sân. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FieldDetailController
// ─────────────────────────────────────────────────────────────────────────────

class FieldDetailController extends ChangeNotifier {
  final BookingRepository _repo;

  FieldDetailController({required BookingRepository repository}) : _repo = repository;

  bool _isLoading = false;
  String? _errorMessage;
  FootballField? _field;
  List<FieldSlot> _slots = [];
  String _selectedDateKey = _todayKey();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FootballField? get field => _field;
  List<FieldSlot> get slots => _slots;
  String get selectedDateKey => _selectedDateKey;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadField(String fieldId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _field = await _repo.getFieldById(fieldId);
      await _loadSlots();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin sân. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectDate(String dateKey) async {
    if (_selectedDateKey == dateKey) return;
    _selectedDateKey = dateKey;
    notifyListeners();
    if (_field != null) {
      await _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    if (_field == null) return;
    try {
      _slots = await _repo.getFieldSlots(_field!.id, dateKey: _selectedDateKey);
    } catch (_) {
      _slots = [];
    }
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SlotSelectionController — xử lý chọn slot liên tiếp
// ─────────────────────────────────────────────────────────────────────────────

class SlotSelectionController extends ChangeNotifier {
  final List<FieldSlot> _selectedSlots = [];

  List<FieldSlot> get selectedSlots => List.unmodifiable(_selectedSlots);
  List<String> get selectedSlotIds => _selectedSlots.map((s) => s.id).toList();

  bool get hasSelection => _selectedSlots.isNotEmpty;

  /// Tổng số tiền cần trả cho các slot đã chọn
  int get totalAmount => _selectedSlots.fold(0, (sum, s) => sum + s.basePrice);

  /// Tổng thời gian tính theo phút
  int get totalMinutes => _selectedSlots.fold(0, (sum, s) => sum + s.durationMinutes);

  /// Thời gian bắt đầu (slot đầu tiên)
  DateTime? get startsAt => _selectedSlots.isEmpty ? null : _selectedSlots.first.startsAt;

  /// Thời gian kết thúc (slot cuối cùng)
  DateTime? get endsAt => _selectedSlots.isEmpty ? null : _selectedSlots.last.endsAt;

  String get currency => _selectedSlots.isEmpty ? 'VND' : _selectedSlots.first.currency;

  /// Kiểm tra slot có đang được chọn không
  bool isSelected(String slotId) => _selectedSlots.any((s) => s.id == slotId);

  /// Toggle chọn/bỏ slot — đảm bảo các slot phải liên tiếp nhau
  /// Trả về null nếu thành công, hoặc thông báo lỗi nếu không hợp lệ
  String? toggleSlot(FieldSlot slot) {
    if (slot.status != FieldSlotStatus.available) {
      return 'Khung giờ này không khả dụng.';
    }

    if (isSelected(slot.id)) {
      // Bỏ chọn: chỉ cho phép bỏ chọn slot đầu hoặc cuối (để giữ tính liên tiếp)
      if (_selectedSlots.first.id == slot.id || _selectedSlots.last.id == slot.id) {
        _selectedSlots.removeWhere((s) => s.id == slot.id);
        notifyListeners();
        return null;
      }
      return 'Chỉ có thể bỏ chọn khung giờ đầu hoặc cuối của dãy đã chọn.';
    }

    // Thêm slot mới: phải liền kề với slot đầu hoặc cuối đang chọn
    if (_selectedSlots.isEmpty) {
      _selectedSlots.add(slot);
      notifyListeners();
      return null;
    }

    final first = _selectedSlots.first;
    final last = _selectedSlots.last;

    // Slot mới liền sau slot cuối cùng
    if (slot.startsAt.isAtSameMomentAs(last.endsAt)) {
      _selectedSlots.add(slot);
      _selectedSlots.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      notifyListeners();
      return null;
    }

    // Slot mới liền trước slot đầu tiên
    if (slot.endsAt.isAtSameMomentAs(first.startsAt)) {
      _selectedSlots.insert(0, slot);
      notifyListeners();
      return null;
    }

    return 'Các khung giờ phải liền nhau. Hãy chọn khung giờ ngay trước hoặc sau dãy đã chọn.';
  }

  void clearSelection() {
    _selectedSlots.clear();
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CreateBookingController — xử lý tạo booking
// ─────────────────────────────────────────────────────────────────────────────

class CreateBookingController extends ChangeNotifier {
  final BookingRepository _repo;

  CreateBookingController({required BookingRepository repository}) : _repo = repository;

  bool _isSubmitting = false;
  String? _errorMessage;
  Booking? _createdBooking;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  Booking? get createdBooking => _createdBooking;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String fieldId,
    required List<String> slotIds,
    String? customerNote,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    _createdBooking = null;
    notifyListeners();
    try {
      _createdBooking = await _repo.createBooking(
        fieldId: fieldId,
        slotIds: slotIds,
        customerNote: customerNote,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = _friendlyError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Không thể tạo đặt sân. Vui lòng thử lại.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _friendlyError(ApiException e) {
    return switch (e.code) {
      'BOOKING_CONFLICT' => 'Khung giờ này vừa được người khác đặt. Vui lòng chọn khung giờ khác.',
      'FIELD_UNAVAILABLE' => 'Sân hiện không nhận đặt chỗ.',
      'NOT_FOUND' => 'Sân hoặc khung giờ không còn tồn tại.',
      'UNAUTHENTICATED' => 'Vui lòng đăng nhập để đặt sân.',
      _ => e.message,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingListController — lịch sử booking của user
// ─────────────────────────────────────────────────────────────────────────────

class BookingListController extends ChangeNotifier {
  final BookingRepository _repo;

  BookingListController({required BookingRepository repository}) : _repo = repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Booking> _bookings = [];
  BookingStatus? _statusFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingStatus? get statusFilter => _statusFilter;

  List<Booking> get bookings {
    if (_statusFilter == null) return _bookings;
    return _bookings.where((b) => b.status == _statusFilter).toList();
  }

  void setStatusFilter(BookingStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadMyBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _bookings = await _repo.getMyBookings();
      _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đặt sân. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final updated = await _repo.cancelBooking(bookingId, reason: reason);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể hủy đặt sân. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingDetailController — chi tiết 1 booking
// ─────────────────────────────────────────────────────────────────────────────

class BookingDetailController extends ChangeNotifier {
  final BookingRepository _repo;

  BookingDetailController({required BookingRepository repository}) : _repo = repository;

  bool _isLoading = false;
  bool _isCancelling = false;
  String? _errorMessage;
  Booking? _booking;

  bool get isLoading => _isLoading;
  bool get isCancelling => _isCancelling;
  String? get errorMessage => _errorMessage;
  Booking? get booking => _booking;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _booking = await _repo.getBooking(bookingId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin đặt sân. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking({String? reason}) async {
    if (_booking == null || _isCancelling) return false;
    _isCancelling = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _booking = await _repo.cancelBooking(_booking!.id, reason: reason);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Không thể hủy đặt sân. Vui lòng thử lại.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OwnerBookingController — chủ sân quản lý booking
// ─────────────────────────────────────────────────────────────────────────────

class OwnerBookingController extends ChangeNotifier {
  final BookingRepository _repo;

  OwnerBookingController({required BookingRepository repository}) : _repo = repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Booking> _bookings = [];
  BookingStatus? _statusFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BookingStatus? get statusFilter => _statusFilter;

  List<Booking> get bookings {
    if (_statusFilter == null) return _bookings;
    return _bookings.where((b) => b.status == _statusFilter).toList();
  }

  int get pendingCount => _bookings.where((b) => b.status == BookingStatus.pending).length;
  int get confirmedCount => _bookings.where((b) => b.status == BookingStatus.confirmed).length;

  void setStatusFilter(BookingStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadOwnerBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _bookings = await _repo.getOwnerBookings();
      _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đặt sân. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmBooking(String bookingId) async {
    _errorMessage = null;
    try {
      final updated = await _repo.confirmBooking(bookingId);
      _updateBooking(updated);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể xác nhận đặt sân. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, {required String reason}) async {
    _errorMessage = null;
    try {
      final updated = await _repo.rejectBooking(bookingId, reason: reason);
      _updateBooking(updated);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể từ chối đặt sân. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  void _updateBooking(Booking updated) {
    final index = _bookings.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _bookings[index] = updated;
      notifyListeners();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OwnerFieldController — chủ sân quản lý sân
// ─────────────────────────────────────────────────────────────────────────────

class OwnerFieldController extends ChangeNotifier {
  final BookingRepository _repo;

  OwnerFieldController({required BookingRepository repository}) : _repo = repository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<FootballField> _fields = [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<FootballField> get fields => _fields;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadMyFields(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _fields = await _repo.getFields(ownerId: ownerId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách sân. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createField(Map<String, dynamic> data) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final field = await _repo.createField(data);
      _fields.insert(0, field);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Không thể tạo sân. Vui lòng thử lại.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateField(String fieldId, Map<String, dynamic> data) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repo.updateField(fieldId, data);
      _replaceField(updated);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật sân. Vui lòng thử lại.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String fieldId, String newStatus) async {
    _errorMessage = null;
    try {
      final updated = await _repo.updateFieldStatus(fieldId, newStatus);
      _replaceField(updated);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái sân. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  void _replaceField(FootballField updated) {
    final index = _fields.indexWhere((f) => f.id == updated.id);
    if (index != -1) {
      _fields[index] = updated;
    } else {
      _fields.insert(0, updated);
    }
    notifyListeners();
  }
}
