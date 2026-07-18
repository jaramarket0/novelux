import 'package:flutter/widgets.dart';

/// App-wide observer for RouteAware widgets (e.g. the reading interface's
/// screenshot lock). Registered on GetMaterialApp.navigatorObservers.
///
/// Typed to PageRoute so popup routes (bottom sheets, dialogs) shown over a
/// page do NOT trigger didPushNext/didPopNext on subscribers.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
