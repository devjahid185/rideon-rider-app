

import 'package:flutter/material.dart';
 import 'package:ride_on/app/route_settings.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/widgets/review_widget.dart';
import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../screens/Home/item_home_screen.dart';

class ThankuScreen extends StatefulWidget {
  final int rating;
  final String msg;
  const ThankuScreen({super.key,required this.msg,required this.rating});

  @override
  State<ThankuScreen> createState() => _ThankuScreenState();
}

class _ThankuScreenState extends State<ThankuScreen> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();



    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {

      _animationController.forward();
    });
  }

  @override
  void dispose() {

    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decoration with subtle pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  themeColor.withValues(alpha:0.08),
                  Colors.white.withValues(alpha:0.3),
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 0.8],
              ),
            ),
            child: CustomPaint(
              painter: _DotsPainter(color: themeColor.withValues(alpha:0.05)),
            ),
          ),




          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Main celebration icon with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeColor.withValues(alpha:0.15),
                            themeColor.withValues(alpha:0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha:0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 100,
                            color: themeColor,
                            shadows: [
                              Shadow(
                                color: themeColor.withValues(alpha:0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: themeColor.withValues(alpha:0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.celebration_rounded,
                                color: themeColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Success title with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          "${"Ride Completed".translate(context)}! ðŸŽ‰",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[900],
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha:0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Success message card with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - _fadeAnimation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildMessageCard(),
                  ),

                  const SizedBox(height: 32),

                  // Rating card with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - _fadeAnimation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildRatingCard(),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom button with safe area
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha:0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: CustomsButtons(
                    textColor: whiteColor,
                    text: "Go to Home".translate(context).toUpperCase(),
                    backgroundColor: themeColor,
                    onPressed: () {
                      clearAllRiderData(context);
                      goToWithClear(const ItemHomeScreen());
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_rounded,
              size: 32,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Thank You for Riding With Us!".translate(context),
            style: heading2Grey1(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Your trip has been completed successfully. We hope you enjoyed your journey and look forward to serving you again soon.".translate(context),
            style: regular2(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            "You Rated This Ride".translate(context),
            style: heading3Grey1(context),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              bool isColored = index < widget.rating;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.star_rounded,
                  color: isColored
                      ? themeColor // Use your theme color for rated stars
                      : Colors.grey[300], // Grey for unrated stars
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            widget.msg,
            style: heading3(context).copyWith(color: themeColor),
          ),
          const SizedBox(height: 8),
          Text(
            "Thank you for your feedback".translate(context),
            style: regular(context),
          ),
        ],
      ),
    );
  }
}

// Custom painter for background dots pattern
class _DotsPainter extends CustomPainter {
  final Color color;

  _DotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotRadius = 2.0;
    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if ((x / spacing + y / spacing) % 2 == 0) {
          canvas.drawCircle(Offset(x, y), dotRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


