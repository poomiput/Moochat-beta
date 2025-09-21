import 'package:flutter/material.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/features/chat/ui/screens/chat_screen.dart';
import 'package:moochat/features/home/ui/screens/home_page.dart';
import 'package:moochat/features/invite/ui/screens/my_qr_screen.dart';
import 'package:moochat/features/invite/ui/screens/scanner_screen.dart';

// NOTE: This file is responsible for routing in the app.
class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesManager.myQrScreen:
        return _createSlideRoute(const MyQrScreen());
      case RoutesManager.qrScannerScreen:
        return _createSlideRoute(const ScannerScreen());
      case RoutesManager.chatScreen:
        // Assuming you have a ChatScreen that takes a name argument
        final args = settings.arguments as Map<String, dynamic>;
        return _createSlideRoute(ChatScreen(userData: args['userData']));
      case RoutesManager.homeScreen:
        // Assuming you have a HomeScreen widget
        return _createSlideRoute(const HomePage());
      default:
        return null;
    }
  }

  // NOTE: Animation methods for different transitions

  // Simple slide transition from right to left
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Start from right
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Simple fade transition
  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // Scale transition (bonus - you can use this too)
  Route _createScaleRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  // Slide from bottom (good for modals or auth screens)
  Route _createSlideFromBottomRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
