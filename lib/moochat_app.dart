import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/routing/app_router.dart';
import 'package:moochat/core/shared/providers/bluetooth_state_provider.dart';
import 'package:moochat/core/widgets/app_shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/home/ui/screens/on_bluetooth_disable_screen.dart';
import 'package:moochat/core/theming/colors.dart';

class MooChatApp extends ConsumerWidget {
  final AppRouter appRouter;

  const MooChatApp({super.key, required this.appRouter});

  ThemeData _buildTheme() {
    return ThemeData(
      scaffoldBackgroundColor: ColorsManager.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorsManager.surfaceColor,
        foregroundColor: ColorsManager.primaryText,
        elevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ColorsManager.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: ColorsManager.mainColor,
        secondary: ColorsManager.accentColor,
        surface: ColorsManager.surfaceColor,
        onPrimary: ColorsManager.primaryText,
        onSecondary: ColorsManager.secondaryText,
        onSurface: ColorsManager.primaryText,
        outline: ColorsManager.borderColor,
      ),
      cardTheme: CardThemeData(
        color: ColorsManager.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ColorsManager.subtleBorder, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.interactiveGrey,
          foregroundColor: ColorsManager.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      useMaterial3: true,
    );
  }

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
        theme: _buildTheme(),
        onGenerateRoute: appRouter.generateRoute,
        home: isBluetoothEnabled
            ? const AppShell()
            : const OnBluetoothDisableScreen(),
      ),
    );
  }
}
