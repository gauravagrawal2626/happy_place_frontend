import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/analytics/analytics_button_names.dart';
import '../../core/analytics/analytics_facade.dart';
import '../../core/bloc/app_bloc.dart';
import '../../core/bloc/app_state.dart';
import 'account_modal.dart';
import 'app_bottom_nav.dart';

/// Bottom-nav tab index: Search = 0, Chat = 1, Account = 2.
enum MainTabIndex {
  search(0),
  chat(1),
  account(2);

  const MainTabIndex(this.navIndex);
  final int navIndex;
}

String searchRouteForRole(String role) =>
    role == 'LISTER' ? '/list/lister' : '/map/seeker';

void openAccountModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AccountModalWithBlur(),
  );
}

void navigateToSearch(BuildContext context) {
  final state = context.read<AppBloc>().state;
  if (state is! AppAuthenticated) return;
  context.go(searchRouteForRole(state.authResponse.role));
}

void navigateToChats(BuildContext context) {
  context.go('/chats');
}

Widget buildMainBottomNav(
  BuildContext context, {
  required MainTabIndex currentTab,
  required String screenName,
}) {
  return AppBottomNav(
    currentIndex: currentTab.navIndex,
    onResultsTap: () {
      unawaited(
        context.read<AnalyticsFacade>().button(
              AnalyticsButtonNames.bottomNavSearchResults,
              screenName: screenName,
            ),
      );
      navigateToSearch(context);
    },
    onChatTap: () {
      unawaited(
        context.read<AnalyticsFacade>().button(
              AnalyticsButtonNames.bottomNavChat,
              screenName: screenName,
            ),
      );
      navigateToChats(context);
    },
    onAccountTap: () {
      unawaited(
        context.read<AnalyticsFacade>().button(
              AnalyticsButtonNames.bottomNavAccount,
              screenName: screenName,
            ),
      );
      openAccountModal(context);
    },
  );
}
