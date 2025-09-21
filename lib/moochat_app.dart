import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/routing/app_router.dart';
import 'package:moochat/core/shared/providers/bluetooth_state_provider.dart';
import 'package:moochat/features/home/ui/screens/home_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/home/ui/screens/on_bluetooth_disable_screen.dart';

class MooChatApp extends ConsumerWidget {
  final AppRouter appRouter;

  const MooChatApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isBluetoothEnabled = ref.watch(isBluetoothOnProvider);
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only if you need to use library outside ScreenUtilInit context
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: appRouter.generateRoute,
        home: isBluetoothEnabled
            ? const HomePage()
            : const OnBluetoothDisableScreen(),
      ),
    );
  }
}
