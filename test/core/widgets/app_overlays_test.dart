import 'dart:async';

import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression tests for the "GoRouter.of - No GoRouter found in context"
/// crash (Crashlytics issue #4).
///
/// showBrownyDialog/showWalletDialog แสดงผลผ่าน Overlay ของตัวเอง ซึ่งเป็น
/// อิสระจาก lifecycle ของหน้าที่เรียก - ถ้าหน้าที่เรียกถูก pop ไปแล้วระหว่าง
/// dialog ยังค้างแสดงอยู่ (เช่น กด back ของระบบ) แล้วผู้ใช้เพิ่งมากดยืนยัน
/// ทีหลัง onConfirm ของผู้เรียกที่ใช้ context เดิมเรียก GoRouter จะ throw
/// ก่อนแก้ (ดู AppOverlays.showBrownyDialog -> GoRouter.of)
void main() {
  GoRouter buildRouter({required WidgetBuilder pageABuilder}) {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home-page')),
        ),
        GoRoute(path: '/a', builder: (context, state) => pageABuilder(context)),
      ],
    );
  }

  testWidgets(
    'onConfirm is skipped (no crash) when calling context is unmounted before confirm is tapped',
    (tester) async {
      var onConfirmCalled = false;

      late GoRouter router;
      router = buildRouter(
        pageABuilder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                unawaited(
                  AppOverlays.showBrownyDialog(
                    context,
                    message: 'test message',
                    confirmText: 'OK',
                    onConfirm: () {
                      onConfirmCalled = true;
                      // เหมือน call site จริงใน production (เช่น
                      // coupon_voucher_selected_page.dart) - ใช้ context ของ
                      // หน้าที่เรียก dialog ไปเรียก GoRouter ต่อ
                      context.pop();
                    },
                  ),
                );
              },
              child: const Text('show-dialog-button'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp.router(routerConfig: router),
        ),
      );

      router.push('/a');
      await tester.pumpAndSettle();

      await tester.tap(find.text('show-dialog-button'));
      await tester.pump();
      await tester.pump();

      expect(find.text('OK'), findsOneWidget, reason: 'dialog ควรแสดงอยู่');

      // จำลองหน้า A ถูก pop ไปแล้วขณะ dialog ยังค้างแสดงอยู่
      router.pop();
      await tester.pumpAndSettle();

      expect(
        find.text('OK'),
        findsOneWidget,
        reason: 'dialog เป็น Overlay อิสระ ไม่ได้หายไปตามหน้าที่ถูก pop',
      );

      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        onConfirmCalled,
        isFalse,
        reason: 'ไม่ควรเรียก onConfirm ของผู้เรียกเมื่อ context ไม่ mounted แล้ว',
      );
      expect(
        find.text('OK'),
        findsNothing,
        reason: 'dialog ต้องถูกปิดแม้ context ของผู้เรียกจะ unmounted แล้ว',
      );
    },
  );

  testWidgets(
    'onConfirm is called normally when calling context is still mounted',
    (tester) async {
      var onConfirmCalled = false;

      late GoRouter router;
      router = buildRouter(
        pageABuilder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                unawaited(
                  AppOverlays.showBrownyDialog(
                    context,
                    message: 'test message',
                    confirmText: 'OK',
                    onConfirm: () => onConfirmCalled = true,
                  ),
                );
              },
              child: const Text('show-dialog-button'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp.router(routerConfig: router),
        ),
      );

      router.push('/a');
      await tester.pumpAndSettle();

      await tester.tap(find.text('show-dialog-button'));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(onConfirmCalled, isTrue);
    },
  );
}
