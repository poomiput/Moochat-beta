import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/widgets/modern_navigation.dart';
import 'package:moochat/core/widgets/quick_actions_bar.dart';
import 'package:moochat/features/home/ui/screens/new_main_page.dart';
import 'package:moochat/features/devices/ui/screens/devices_screen.dart';
import 'package:moochat/features/settings/ui/screens/settings_screen.dart';

/// Main app shell with modern navigation and responsive layout
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _searchQuery = '';
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.chat_bubble_outline, label: 'Chats'),
    NavigationItem(icon: Icons.devices_outlined, label: 'Devices'),
    NavigationItem(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  bool get _isTablet => MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      body: Column(
        children: [
          // Status bar spacer
          SizedBox(height: MediaQuery.of(context).padding.top),

          // Quick actions bar
          QuickActionsBar(
            searchQuery: _searchQuery,
            onSearchChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
            onScanQR: () {
              // Handle QR scan
            },
            onAddContact: () {
              // Handle add contact
            },
            onSettings: () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),

          // Main content area
          Expanded(
            child: Row(
              children: [
                // Navigation rail for tablets
                if (_isTablet)
                  ModernNavigation(
                    currentIndex: _currentIndex,
                    onIndexChanged: _onNavigationChanged,
                    items: _navigationItems,
                    isTablet: true,
                  ),

                // Main content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCurrentPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom navigation for phones
      bottomNavigationBar: _isTablet
          ? null
          : ModernNavigation(
              currentIndex: _currentIndex,
              onIndexChanged: _onNavigationChanged,
              items: _navigationItems,
              isTablet: false,
            ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const NewMainPage();
      case 1:
        return const DevicesScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const NewMainPage();
    }
  }

  void _onNavigationChanged(int index) {
    if (index != _currentIndex) {
      _transitionController.reset();
      setState(() {
        _currentIndex = index;
      });
      _transitionController.forward();
    }
  }
}
