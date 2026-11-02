import '../../domain/models/field_slot.dart';
import '../../domain/models/football_field.dart';

/// Dữ liệu mẫu khởi tạo (Seed / Mock Data) cho phân hệ Đặt sân bóng (Booking & Fields).
///
/// Tách biệt hoàn toàn khỏi Repository và Service nhằm:
/// 1. Tinh gọn mã nguồn nghiệp vụ trong ApiBookingRepository.
/// 2. Phục vụ dữ liệu giả lập cho việc chạy demo ngoại tuyến (offline) hoặc kiểm thử tự động.
/// 3. Dễ dàng điều chỉnh danh sách sân mẫu, khung giờ mẫu độc lập mà không ảnh hưởng luồng gọi API.
class BookingSeedData {
  /// Danh sách các sân bóng đá mẫu tại TP.HCM, Hà Nội, Đà Nẵng
  static List<FootballField> getSampleFields({
    String? city,
    String? district,
    String? fieldType,
    String? search,
  }) {
    final now = DateTime.now();
    final fields = [
      FootballField(
        id: 'field_gia_dinh',
        ownerId: 'owner_01',
        name: 'Sân bóng Gia Định',
        description:
            'Sân cỏ nhân tạo chất lượng cao, thoáng mát, đạt chuẩn thi đấu.',
        coverImageUrl: 'https://images.unsplash.com/photo-1529900245534-47fbfb57835a?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1529900245534-47fbfb57835a?auto=format&fit=crop&w=800&q=80',
        ],
        address: '2A Phan Chu Trinh, Phường 12',
        district: 'Bình Thạnh',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8012,
        longitude: 106.6987,
        fieldType: '7-a-side',
        capacity: 14,
        amenities: const [
          'Wifi',
          'Gửi xe',
          'Nước uống',
          'Đèn chiếu sáng',
          'Phòng thay đồ',
        ],
        basePrice: 300000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_binh_quoi',
        ownerId: 'owner_01',
        name: 'Sân bóng Bình Quới',
        description: 'Cụm sân 5 và sân 7 ven sông, không khí mát mẻ, bãi giữ xe ô tô rộng rãi.',
        coverImageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        ],
        address: '1143 Bình Quới, Cư xá Thanh Đa',
        district: 'Bình Thạnh',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8256,
        longitude: 106.7312,
        fieldType: '7-a-side',
        capacity: 14,
        amenities: const ['Căn tin', 'Gửi xe ô tô', 'Nước uống', 'Trọng tài'],
        basePrice: 350000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_thanh_da',
        ownerId: 'owner_01',
        name: 'Sân bóng Thanh Đa',
        description:
            'Sân cỏ nhân tạo mới nâng cấp mặt cỏ đạt chuẩn FIFA 2 sao.',
        coverImageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
        ],
        address: 'Lô IV Cư xá Thanh Đa',
        district: 'Bình Thạnh',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8142,
        longitude: 106.7210,
        fieldType: '5-a-side',
        capacity: 10,
        amenities: const ['Wifi', 'Gửi xe máy', 'Áo bib thi đấu'],
        basePrice: 280000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_chao_lua',
        ownerId: 'owner_01',
        name: 'Sân vận động Chảo Lửa',
        description: 'Cụm sân 11 người mặt cỏ tự nhiên tiêu chuẩn thi đấu chuyên nghiệp.',
        coverImageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        ],
        address: '30 Phan Thúc Duyện, Phường 4',
        district: 'Tân Bình',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8032,
        longitude: 106.6621,
        fieldType: '11-a-side',
        capacity: 22,
        amenities: const [
          'Khán đài',
          'Đèn cao áp',
          'Phòng tắm nóng lạnh',
          'Bãi xe ô tô',
        ],
        basePrice: 650000,
        currency: 'VND',
        slotDurationMinutes: 90,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_futsal_tan_binh',
        ownerId: 'owner_01',
        name: 'Sân Futsal Hoàng Gia',
        description: 'Sân bóng đá trong nhà mặt sàn thảm vinyl cao cấp, máy lạnh thoáng khí.',
        coverImageUrl: 'https://images.unsplash.com/photo-1529900245534-47fbfb57835a?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1529900245534-47fbfb57835a?auto=format&fit=crop&w=800&q=80',
        ],
        address: '18 Cộng Hòa, Phường 13',
        district: 'Tân Bình',
        city: 'TP. Hồ Chí Minh',
        latitude: 10.8010,
        longitude: 106.6450,
        fieldType: 'futsal',
        capacity: 10,
        amenities: const [
          'Máy lạnh',
          'Sàn thảm Futsal',
          'Tủ đồ thông minh',
          'Nước uống',
        ],
        basePrice: 320000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_my_dinh',
        ownerId: 'owner_01',
        name: 'Sân bóng Cỏ Nhân Tạo Mỹ Đình',
        description:
            'Cụm sân 7 người chất lượng cao ngay gần SVĐ Quốc Gia Mỹ Đình.',
        coverImageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=800&q=80',
        ],
        address: 'Đường Lê Đức Thọ, Mỹ Đình',
        district: 'Nam Từ Liêm',
        city: 'Hà Nội',
        latitude: 21.0200,
        longitude: 105.7650,
        fieldType: '7-a-side',
        capacity: 14,
        amenities: const [
          'Bãi đỗ ô tô',
          'Căng tin',
          'Đèn chiếu sáng',
          'Trọng tài',
        ],
        basePrice: 350000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
      FootballField(
        id: 'field_tuyen_son',
        ownerId: 'owner_01',
        name: 'Làng Thể Thao Tuyên Sơn',
        description: 'Tổ hợp thể thao giải trí hàng đầu miền Trung, sân 7 đạt chuẩn FIFA.',
        coverImageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        imageUrls: const [
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=800&q=80',
        ],
        address: 'Đường 2 Tháng 9, Hòa Cường Nam',
        district: 'Hải Châu',
        city: 'Đà Nẵng',
        latitude: 16.0350,
        longitude: 108.2250,
        fieldType: '7-a-side',
        capacity: 14,
        amenities: const ['Bãi đỗ ô tô', 'Căng tin', 'Wifi', 'Trọng tài'],
        basePrice: 300000,
        currency: 'VND',
        slotDurationMinutes: 60,
        status: FieldStatus.active,
        openingHours: const {
          'mon': ['06:00', '23:00'],
          'tue': ['06:00', '23:00'],
          'wed': ['06:00', '23:00'],
          'thu': ['06:00', '23:00'],
          'fri': ['06:00', '23:00'],
          'sat': ['06:00', '23:00'],
          'sun': ['06:00', '23:00'],
        },
        timezone: 'Asia/Ho_Chi_Minh',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
        createdBy: 'owner_01',
        updatedBy: 'owner_01',
      ),
    ];

    return fields.where((f) {
      if (city != null && f.city.toLowerCase() != city.toLowerCase()) {
        return false;
      }
      if (district != null &&
          f.district.toLowerCase() != district.toLowerCase()) {
        return false;
      }
      if (fieldType != null && f.fieldType != fieldType) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        final match =
            f.name.toLowerCase().contains(query) ||
            f.address.toLowerCase().contains(query) ||
            f.district.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  /// Danh sách khung giờ mẫu cho sân bóng
  static List<FieldSlot> getSampleSlots(
    String fieldId, {
    String? dateKey,
    Set<String> bookedSlotIds = const {},
  }) {
    final now = DateTime.now();
    final dKey =
        dateKey ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final parts = dKey.split('-');
    final targetDate = parts.length == 3
        ? DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          )
        : now;

    final hours = [7, 8, 9, 15, 16, 17, 18, 19, 20, 21];
    return hours.map((h) {
      final start = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        h,
        0,
      );
      final end = start.add(const Duration(hours: 1));
      final slotKey = 'slot_${fieldId}_${dKey}_$h';
      final isHeld = h == 18;
      final isBooked =
          h == 19 ||
          bookedSlotIds.contains(slotKey) ||
          bookedSlotIds.any(
            (id) => id == slotKey || id.endsWith('_${dKey}_$h'),
          );
      return FieldSlot(
        id: slotKey,
        fieldId: fieldId,
        dateKey: dKey,
        startsAt: start,
        endsAt: end,
        durationMinutes: 60,
        basePrice: (h >= 17 && h <= 20) ? 350000 : 250000,
        currency: 'VND',
        status: isBooked
            ? FieldSlotStatus.booked
            : isHeld
            ? FieldSlotStatus.held
            : FieldSlotStatus.available,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );
    }).toList();
  }
}
