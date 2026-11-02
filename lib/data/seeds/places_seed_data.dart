import '../../models/place_location.dart';

/// Dữ liệu mẫu khởi tạo (Seed / Mock Data) cho các Hub thể thao và sân bóng đá phong trào.
///
/// Phục vụ cho tính năng tìm kiếm địa điểm, tự động điền địa chỉ (Address Autocomplete)
/// khi chạy ngoại tuyến (offline) hoặc khi Google Places API chưa được cấu hình.
class PlacesSeedData {
  /// Danh sách các Hub thể thao & sân bóng đá phong trào mẫu để fallback khi offline
  static const List<PlacePrediction> sampleHubPredictions = [
    PlacePrediction(
      placeId: 'hub_thuduc',
      mainText: 'TP. Thủ Đức',
      secondaryText: 'TP. Hồ Chí Minh, Việt Nam',
      description: 'TP. Thủ Đức, TP. Hồ Chí Minh, Việt Nam',
      types: ['locality', 'political'],
    ),
    PlacePrediction(
      placeId: 'hub_binhthanh',
      mainText: 'Quận Bình Thạnh',
      secondaryText: 'TP. Hồ Chí Minh, Việt Nam',
      description: 'Quận Bình Thạnh, TP. Hồ Chí Minh, Việt Nam',
      types: ['administrative_area_level_2', 'political'],
    ),
    PlacePrediction(
      placeId: 'hub_chaolua',
      mainText: 'Sân bóng đá Chảo Lửa',
      secondaryText: '30 Phan Thúc Duyện, Phường 4, Tân Bình, TP. Hồ Chí Minh',
      description: 'Sân bóng đá Chảo Lửa, 30 Phan Thúc Duyện, Phường 4, Tân Bình, TP. Hồ Chí Minh',
      types: ['establishment', 'point_of_interest'],
    ),
    PlacePrediction(
      placeId: 'hub_caugiay',
      mainText: 'Quận Cầu Giấy',
      secondaryText: 'Hà Nội, Việt Nam',
      description: 'Quận Cầu Giấy, Hà Nội, Việt Nam',
      types: ['administrative_area_level_2', 'political'],
    ),
    PlacePrediction(
      placeId: 'hub_mydinh',
      mainText: 'Sân vận động Quốc gia Mỹ Đình',
      secondaryText: 'Đường Lê Đức Thọ, Mỹ Đình, Nam Từ Liêm, Hà Nội',
      description: 'Sân vận động Quốc gia Mỹ Đình, Đường Lê Đức Thọ, Mỹ Đình, Nam Từ Liêm, Hà Nội',
      types: ['stadium', 'establishment'],
    ),
    PlacePrediction(
      placeId: 'hub_danang_haichau',
      mainText: 'Quận Hải Châu',
      secondaryText: 'Đà Nẵng, Việt Nam',
      description: 'Quận Hải Châu, Đà Nẵng, Việt Nam',
      types: ['administrative_area_level_2', 'political'],
    ),
    PlacePrediction(
      placeId: 'hub_tuyenson',
      mainText: 'Làng Thể thao Tuyên Sơn',
      secondaryText: 'Nại Nam 2, Hòa Cường Bắc, Hải Châu, Đà Nẵng',
      description: 'Làng Thể thao Tuyên Sơn, Nại Nam 2, Hòa Cường Bắc, Hải Châu, Đà Nẵng',
      types: ['establishment', 'point_of_interest'],
    ),
    PlacePrediction(
      placeId: 'hub_bienhoa',
      mainText: 'TP. Biên Hòa',
      secondaryText: 'Đồng Nai, Việt Nam',
      description: 'TP. Biên Hòa, Đồng Nai, Việt Nam',
      types: ['locality', 'political'],
    ),
    PlacePrediction(
      placeId: 'hub_thudaumot',
      mainText: 'TP. Thủ Dầu Một',
      secondaryText: 'Bình Dương, Việt Nam',
      description: 'TP. Thủ Dầu Một, Bình Dương, Việt Nam',
      types: ['locality', 'political'],
    ),
  ];
}
