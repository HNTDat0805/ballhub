import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/screens/teams/team_form_screen.dart';
import 'package:ballhub/services/team_service.dart';
import 'package:ballhub/widgets/google_maps_area_picker_modal.dart';

void main() {
  setUp(() {
    TeamService.resetStateForTesting();
  });

  group('GoogleMapsAreaPickerModal & TeamFormScreen Tests', () {
    testWidgets(
      '1. TeamFormScreen displays clean area autocomplete field and quick chips without map preview',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TeamFormScreen()));
        await tester.pumpAndSettle();

        // Kiểm tra tiêu đề trang
        expect(find.text('Tạo đội bóng'), findsOneWidget);

        // Kiểm tra sự xuất hiện của mục Khu vực hoạt động
        expect(find.text('Khu vực hoạt động *'), findsOneWidget);
        expect(
          find.text('Gõ tên quận huyện, thành phố hoặc sân bóng...'),
          findsNothing,
        );

        // Kiểm tra bản đồ preview đã được loại bỏ hoàn toàn
        expect(find.text('Mở bản đồ'), findsNothing);
        expect(
          find.text('Chưa chọn khu vực. Bấm để chọn trên Google Maps.'),
          findsNothing,
        );
        expect(find.text('Chạm để ghim vị trí'), findsNothing);

        // Kiểm tra các chip gợi ý nhanh địa điểm
        expect(find.text('Gợi ý nhanh:'), findsOneWidget);
        expect(find.text('TP. Thủ Đức'), findsOneWidget);
        expect(find.text('Quận Bình Thạnh'), findsOneWidget);
        expect(find.text('Quận Cầu Giấy'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Tapping a quick suggested location chip updates the area field text',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TeamFormScreen()));
        await tester.pumpAndSettle();

        // Bấm vào chip 'TP. Thủ Đức'
        final chip = find.text('TP. Thủ Đức');
        expect(chip, findsOneWidget);
        await tester.tap(chip);
        await tester.pumpAndSettle();

        // Trường nhập liệu địa chỉ phải cập nhật sang TP. Thủ Đức, TP. Hồ Chí Minh
        expect(find.text('TP. Thủ Đức, TP. Hồ Chí Minh'), findsOneWidget);
      },
    );

    testWidgets(
      '3. GoogleMapsAreaPickerModal renders Google Maps search and tabs',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => GoogleMapsAreaPickerModal.show(
                    ctx,
                    initialArea: 'Bình Thạnh, TP.HCM',
                  ),
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        );

        // Mở modal
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // Kiểm tra giao diện phong cách Google Maps
        expect(find.text('Chọn khu vực đội bóng'), findsOneWidget);
        expect(
          find.text('Tìm địa điểm, quận huyện, sân bóng...'),
          findsOneWidget,
        );
        expect(find.text('Bản đồ tương tác'), findsOneWidget);
        expect(find.text('Tỉnh / Quận huyện'), findsOneWidget);
        expect(find.text('Xác nhận khu vực này'), findsOneWidget);
      },
    );
  });
}
