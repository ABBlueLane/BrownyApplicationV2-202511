import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/feature/home/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression tests for the "GoRouterDelegate.pop - GoError: There is
/// nothing to pop" crash (Crashlytics issue #1, fixed via `safePop`).
void main() {
  /// สร้าง GoRouter ที่มีแค่หน้าเดียวใน stack (จำลองการเปิดหน้าตรงจาก
  /// deep link โดยไม่มีหน้าอื่นให้ pop กลับ) - เป็นสถานการณ์ที่ทำให้
  /// `context.pop()` ปกติ throw GoError จริงบน production
  GoRouter buildSinglePageRouter() {
    return GoRouter(
      initialLocation: '/only',
      routes: [
        GoRoute(
          path: '/only',
          builder: (context, state) => const Scaffold(body: Text('only-page')),
        ),
      ],
    );
  }

  group('raw go_router behavior (sanity check the crash is real)', () {
    testWidgets('context.pop() throws GoError when there is nothing to pop', (
      tester,
    ) async {
      final router = buildSinglePageRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final context = tester.element(find.text('only-page'));

      expect(() => context.pop(), throwsA(isA<GoError>()));
    });
  });

  group('AppBuildeContext.safePop', () {
    testWidgets(
      'does not throw when there is nothing to pop (falls back instead of crashing)',
      (tester) async {
        final router = buildSinglePageRouter();
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));

        final context = tester.element(find.text('only-page'));

        expect(() => context.safePop(), returnsNormally);
      },
    );

    testWidgets('pops normally when a previous page is available', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/first',
        routes: [
          GoRoute(
            path: '/first',
            builder: (context, state) => const Scaffold(body: Text('first-page')),
          ),
          GoRoute(
            path: '/second',
            builder: (context, state) => const Scaffold(body: Text('second-page')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.push('/second');
      await tester.pumpAndSettle();
      expect(find.text('second-page'), findsOneWidget);

      final context = tester.element(find.text('second-page'));
      context.safePop();
      await tester.pumpAndSettle();

      expect(find.text('first-page'), findsOneWidget);
    });
  });

  group('AppBuildeContext.popUntil', () {
    testWidgets('pops through intermediate pages until predicate matches', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            name: HomePage.pageName,
            builder: (context, state) => const Scaffold(body: Text('home-page')),
          ),
          GoRoute(
            path: '/a',
            name: 'a',
            builder: (context, state) => const Scaffold(body: Text('a-page')),
          ),
          GoRoute(
            path: '/b',
            name: 'b',
            builder: (context, state) => const Scaffold(body: Text('b-page')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.push('/a');
      await tester.pumpAndSettle();
      router.push('/b');
      await tester.pumpAndSettle();
      expect(find.text('b-page'), findsOneWidget);

      final context = tester.element(find.text('b-page'));
      context.popUntil(predicate: (state) => state.name == HomePage.pageName);
      await tester.pumpAndSettle();

      expect(find.text('home-page'), findsOneWidget);
    });

    testWidgets('does nothing when already on the matching route', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            name: HomePage.pageName,
            builder: (context, state) => const Scaffold(body: Text('home-page')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final context = tester.element(find.text('home-page'));

      expect(
        () => context.popUntil(
          predicate: (state) => state.name == HomePage.pageName,
        ),
        returnsNormally,
      );
    });
  });
}
