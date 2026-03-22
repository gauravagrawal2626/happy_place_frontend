import 'package:flutter/widgets.dart';

import 'analytics_facade.dart';
import 'analytics_route_mapper.dart';

/// Emits [AnalyticsEventNames.screenView] when the root navigator pushes/replaces a route.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this._facade);

  final AnalyticsFacade _facade;
  String? _lastEmittedPath;

  void _emit(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    if (name == _lastEmittedPath) return;
    _lastEmittedPath = name;
    final screen = mapRouteNameToScreenName(name);
    _facade.screen(screen, routePath: name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _emit(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emit(previousRoute);
  }
}
