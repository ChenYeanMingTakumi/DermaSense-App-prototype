import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';


import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => const SplashscreenWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const SplashscreenWidget(),
        ),
        FFRoute(
          name: 'home',
          path: '/home',
          builder: (context, params) => const HomeWidget(),
        ),
        FFRoute(
          name: 'signin',
          path: '/signin',
          builder: (context, params) => const SigninWidget(),
        ),
        FFRoute(
          name: 'signup',
          path: '/signup',
          builder: (context, params) => const SignupWidget(),
        ),
        FFRoute(
          name: 'splashscreen',
          path: '/splashscreen',
          builder: (context, params) => const SplashscreenWidget(),
        ),
        FFRoute(
          name: 'welcomepage',
          path: '/welcomepage',
          builder: (context, params) => const WelcomepageWidget(),
        ),
        FFRoute(
          name: 'diagnosis_scan',
          path: '/diagnosis_scan',
          builder: (context, params) => const DiagnosisScanWidget(),
        ),
        FFRoute(
          name: DiagnosisResultWidget.routeName,
          path: DiagnosisResultWidget.routePath,
          builder: (context, params) => const DiagnosisResultWidget(),
        ),
        FFRoute(
          name: 'profile',
          path: '/profile',
          builder: (context, params) => const ProfileWidget(),
        ),
        FFRoute(
          name: 'editprofile',
          path: '/editprofile',
          builder: (context, params) => const EditprofileWidget(),
        ),
        FFRoute(
          name: 'history',
          path: '/history',
          builder: (context, params) => const HistoryWidget(),
        ),
        FFRoute(
          name: 'changepassword',
          path: '/changepassword',
          builder: (context, params) => const ChangepasswordWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, [
    bool isList = false,
    List<String>? collectionNamePath,
  ]) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) {
    return GoRoute(
      name: name,
      path: path,
      redirect: (context, state) {
        if (appStateNotifier.showSplashImage ||
            (requireAuth && !context.mounted)) {
          return null;
        }

        return null;
      },
      pageBuilder: (context, state) {
        fixStatusBarOniOS16AndBelow(context);
        final ffParams = FFParameters(state, asyncParams);
        final page = ffParams.hasFutures
            ? FutureBuilder(
                future: ffParams.completeFutures(),
                builder: (context, _) => builder(context, ffParams),
              )
            : builder(context, ffParams);
        final child = page;

        final transitionInfo = state.transitionInfo;
        return transitionInfo.hasTransition
            ? CustomTransitionPage(
                key: state.pageKey,
                child: child,
                transitionDuration: transitionInfo.duration,
                transitionsBuilder: (context, animation, _, __) =>
                    transitionInfo.transition(animation, child),
              )
            : MaterialPage(key: state.pageKey, child: child);
      },
      routes: routes,
    );
  }
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => const TransitionInfo(hasTransition: false);

  Widget transition(Animation<double> animation, Widget child) {
    final reverseAnimation = Tween(begin: 1.0, end: 0.0).animate(animation);
    switch (transitionType) {
      case PageTransitionType.fade:
        return FadeTransition(opacity: animation, child: child);
      case PageTransitionType.scale:
        return ScaleTransition(alignment: alignment ?? Alignment.center, scale: animation, child: child);
      case PageTransitionType.size:
        return SizeTransition(sizeFactor: animation, child: child);
      case PageTransitionType.rightToLeft:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
          ),
          child: child,
        );
      case PageTransitionType.leftToRight:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero),
          ),
          child: child,
        );
      case PageTransitionType.topToBottom:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, -1.0), end: Offset.zero),
          ),
          child: child,
        );
      case PageTransitionType.bottomToTop:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
          ),
          child: child,
        );
      case PageTransitionType.rightToLeftWithFade:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      case PageTransitionType.leftToRightWithFade:
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      case PageTransitionType.rightToLeftJoined:
        return Stack(
          children: <Widget>[
            SlideTransition(
              position: reverseAnimation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(-1.0, 0.0)),
              ),
              child: child,
            ),
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.leftToRightJoined:
        return Stack(
          children: <Widget>[
            SlideTransition(
              position: reverseAnimation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(1.0, 0.0)),
              ),
              child: child,
            ),
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.topToBottomJoined:
        return Stack(
          children: <Widget>[
            SlideTransition(
              position: reverseAnimation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(0.0, 1.0)),
              ),
              child: child,
            ),
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, -1.0), end: Offset.zero),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.bottomToTopJoined:
        return Stack(
          children: <Widget>[
            SlideTransition(
              position: reverseAnimation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(0.0, -1.0)),
              ),
              child: child,
            ),
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 1.0), end: Offset.zero),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.rightToLeftPop:
        return Stack(
          children: <Widget>[
            child,
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(-1.0, 0.0)),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.leftToRightPop:
        return Stack(
          children: <Widget>[
            child,
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(1.0, 0.0)),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.topToBottomPop:
        return Stack(
          children: <Widget>[
            child,
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(0.0, 1.0)),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.bottomToTopPop:
        return Stack(
          children: <Widget>[
            child,
            SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.0), end: const Offset(0.0, -1.0)),
              ),
              child: child,
            )
          ],
        );
      case PageTransitionType.theme:
        return FadeTransition(opacity: animation, child: child);
      case PageTransitionType.rotate:
        return RotationTransition(turns: animation, child: child);
    }
  }
}

class CustomTransitionPage<T> extends Page<T> {
  const CustomTransitionPage({
    required this.child,
    required this.transitionDuration,
    required this.transitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final Duration transitionDuration;
  final RouteTransitionsBuilder transitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) =>
      PageRouteBuilder<T>(
        settings: this,
        pageBuilder: (context, animation, __) => child,
        transitionDuration: transitionDuration,
        transitionsBuilder: transitionsBuilder,
      );
} 