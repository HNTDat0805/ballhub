import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ballhub/models/place_location.dart';
import 'package:ballhub/widgets/address_autocomplete_field.dart';

void main() {
  group('AddressAutocompleteField Widget Tests', () {
    testWidgets('1. Renders label, hint, and suffix icons correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AddressAutocompleteField(
              labelText: 'Địa chỉ sân bóng *',
              hintText: 'Nhập số nhà, tên đường...',
              isRequired: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Địa chỉ sân bóng *'), findsOneWidget);
      expect(find.text('Nhập số nhà, tên đường...'), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    });

    testWidgets('2. Shows clear icon when text is entered and clears on tap', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Sân Chảo Lửa');
      bool wasCleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressAutocompleteField(
              controller: controller,
              labelText: 'Địa chỉ',
              onCleared: () => wasCleared = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clearIcon = find.byIcon(Icons.clear);
      expect(clearIcon, findsOneWidget);

      await tester.tap(clearIcon);
      await tester.pumpAndSettle();

      expect(controller.text, '');
      expect(wasCleared, isTrue);
    });

    testWidgets(
      '3. Triggers search with debounce and shows suggestions in overlay',
      (tester) async {
        PlaceLocation? selectedLocation;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AddressAutocompleteField(
                  labelText: 'Khu vực',
                  onPlaceSelected: (place) {
                    selectedLocation = place;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Nhập 'Thủ Đức'
        final input = find.byType(TextFormField);
        await tester.enterText(input, 'Thủ Đức');
        // Đợi debounce 350ms
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        // Kiểm tra gợi ý xuất hiện trong overlay
        expect(find.text('TP. Thủ Đức'), findsAtLeastNWidgets(1));

        // Bấm chọn gợi ý 'TP. Thủ Đức'
        await tester.tap(find.text('TP. Thủ Đức').first);
        await tester.pumpAndSettle();

        expect(selectedLocation, isNotNull);
        expect(selectedLocation!.name, 'TP. Thủ Đức');
      },
    );
  });
}
