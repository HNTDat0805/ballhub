/// Trạng thái bất đồng bộ của dữ liệu (Initial, Loading, Success, Error).
///
/// Hỗ trợ chuẩn hóa trạng thái của các màn hình và Widget theo quy chuẩn AGENTS.md:
/// - Mọi màn hình tương tác phải có loading, data, empty và error state rõ ràng.
class AsyncLoadState<T> {
  final bool isLoading;
  final bool isInitial;
  final T? data;
  final String? errorMessage;
  final Object? error;

  const AsyncLoadState._({
    this.isLoading = false,
    this.isInitial = false,
    this.data,
    this.errorMessage,
    this.error,
  });

  /// Trạng thái ban đầu chưa kích hoạt tải dữ liệu
  factory AsyncLoadState.initial() => const AsyncLoadState._(isInitial: true);

  /// Trạng thái đang tải dữ liệu bất đồng bộ từ mạng hoặc cơ sở dữ liệu
  factory AsyncLoadState.loading({T? previousData}) =>
      AsyncLoadState._(isLoading: true, data: previousData);

  /// Trạng thái đã tải dữ liệu thành công
  factory AsyncLoadState.success(T data) => AsyncLoadState._(data: data);

  /// Trạng thái gặp lỗi khi tải dữ liệu
  factory AsyncLoadState.error(
    String message, {
    Object? error,
    T? previousData,
  }) =>
      AsyncLoadState._(errorMessage: message, error: error, data: previousData);

  /// Kiểm tra xem đã có dữ liệu thành công hay chưa
  bool get hasData => data != null;

  /// Kiểm tra xem có lỗi xảy ra hay không
  bool get hasError => errorMessage != null;

  /// Biến đổi hoặc render Widget phù hợp với từng trạng thái bất đồng bộ
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message) error,
    R Function()? initial,
  }) {
    if (isLoading && data == null) {
      return loading();
    }
    if (hasError && data == null) {
      return error(errorMessage ?? 'Đã xảy ra lỗi');
    }
    if (hasData) {
      return success(data as T);
    }
    if (isInitial && initial != null) {
      return initial();
    }
    return loading();
  }
}
