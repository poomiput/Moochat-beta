import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';
import 'package:moochat/features/home/ui/widgets/redesigned_chat_card.dart';
import 'package:moochat/features/home/ui/widgets/sticky_section_header.dart';
import 'package:easy_localization/easy_localization.dart';

/// Redesigned home page with card layout and grouped chats
class RedesignedHomePage extends ConsumerStatefulWidget {
  final String searchQuery;

  const RedesignedHomePage({super.key, required this.searchQuery});

  @override
  ConsumerState<RedesignedHomePage> createState() => _RedesignedHomePageState();
}

class _RedesignedHomePageState extends ConsumerState<RedesignedHomePage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final userDataAsync = ref.watch(userDataProvider);

        return userDataAsync.when(
          data: (userData) => _buildChatList(userData.userChats.chats),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        );
      },
    );
  }

  Widget _buildChatList(List<UserChat> chats) {
    final filteredChats = _filterChats(chats);
    final groupedChats = _groupChatsByTime(filteredChats);

    if (filteredChats.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Pull to refresh indicator space
        SliverToBoxAdapter(child: SizedBox(height: 8.h)),

        // Grouped chat sections
        ...groupedChats.entries.map((entry) {
          return _buildChatSection(entry.key, entry.value);
        }).toList(),

        // Bottom padding
        SliverToBoxAdapter(child: SizedBox(height: 100.h)),
      ],
    );
  }

  Widget _buildChatSection(String sectionTitle, List<UserChat> chats) {
    return SliverMainAxisGroup(
      slivers: [
        // Sticky section header
        SliverPersistentHeader(
          pinned: true,
          delegate: StickySectionHeader(title: sectionTitle),
        ),

        // Chat cards
        SliverAnimatedList(
          initialItemCount: chats.length,
          itemBuilder: (context, index, animation) {
            if (index >= chats.length) return const SizedBox.shrink();

            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(
                opacity: animation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  child: RedesignedChatCard(
                    userChat: chats[index],
                    onTap: () => _navigateToChat(chats[index]),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: ColorsManager.cardColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorsManager.captionText,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading chats...',
            style: TextStyle(color: ColorsManager.captionText, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: ColorsManager.captionText,
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading chats',
            style: TextStyle(
              color: ColorsManager.bodyText,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(color: ColorsManager.captionText, fontSize: 12.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: ColorsManager.cardColor,
              borderRadius: BorderRadius.circular(60.r),
              border: Border.all(color: ColorsManager.strokeColor, width: 1),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: ColorsManager.captionText,
              size: 48.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            context.tr('no_chats'),
            style: TextStyle(
              color: ColorsManager.subtitleText,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr('start_new_conversation'),
            style: TextStyle(
              color: ColorsManager.captionText,
              fontSize: 14.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<UserChat> _filterChats(List<UserChat> chats) {
    if (widget.searchQuery.isEmpty) {
      return chats;
    }

    return chats.where((chat) {
      return chat.username2P.toLowerCase().contains(
        widget.searchQuery.toLowerCase(),
      );
    }).toList();
  }

  Map<String, List<UserChat>> _groupChatsByTime(List<UserChat> chats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<UserChat>> groups = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final chat in chats) {
      final lastMessageTime = chat.messages.isNotEmpty
          ? chat.messages.last.timestamp
          : DateTime.now();

      if (lastMessageTime != null) {
        final messageDate = DateTime(
          lastMessageTime.year,
          lastMessageTime.month,
          lastMessageTime.day,
        );

        if (messageDate.isAtSameMomentAs(today)) {
          groups['Today']!.add(chat);
        } else if (messageDate.isAtSameMomentAs(yesterday)) {
          groups['Yesterday']!.add(chat);
        } else if (messageDate.isAfter(thisWeek)) {
          groups['This Week']!.add(chat);
        } else {
          groups['Earlier']!.add(chat);
        }
      } else {
        groups['Earlier']!.add(chat);
      }
    }

    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  void _navigateToChat(UserChat userChat) {
    Navigator.pushNamed(
      context,
      '/chatScreen',
      arguments: {'userData': userChat},
    );
  }
}
