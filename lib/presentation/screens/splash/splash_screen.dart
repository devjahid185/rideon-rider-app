import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/core/extensions/helper/push_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import '../../../core/utils/common_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double opacity = 0.0;
  AnimationController? controller;

  @override
  void initState() {
    super.initState();
    _loadLocalUserAndSyncFcm();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    controller?.forward();
  }

  Future<void> _loadLocalUserAndSyncFcm() async {
    await getUserDataLocallyToHandleTheState(context);
    await syncPendingFcmTokenIfAny(forceSync: true);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: controller!,
                    reverseCurve: Curves.bounceInOut,
                    curve: Curves.easeInCubic,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    commonlyUserLogo(),
                    Text("WGN Move Rider",style: heading1(context).copyWith(color: Colors.black,fontSize: 25),)
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: SvgPicture.asset("assets/images/vector_bottom.svg"),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SvgPicture.asset("assets/images/vector_top.svg"),
        )
      ],
    );
    // );
  }
}


