import 'package:flutter/cupertino.dart';

import '../core/extensions/workspace.dart';

void navigateToScreen(BuildContext context, Widget Function() screenBuilder,
    {RouteTransitionsBuilder? transitionsBuilder,
    Duration duration = const Duration(milliseconds: 1)}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screenBuilder(),
      transitionsBuilder: transitionsBuilder ??
          (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
      transitionDuration: duration,
    ),
  );
}

void goToWithReplacement(Widget screen) {
  navigatorKey.currentState!.pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}
void goTo(Widget screen) {
  navigatorKey.currentState!.push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}
void goToWithClear(Widget screen) {
  navigatorKey.currentState!.pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    ),
        (route) => false, // Clear all previous routes
  );
}