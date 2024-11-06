// lib/widgets/loading_overlay.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'loading_indicator.dart';

class LoadingOverlay extends StatelessWidget {
  final double opacity;
  final Color? overlayColor;
  final double indicatorSize;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    this.opacity = 255,
    this.overlayColor,
    this.indicatorSize = 50.0,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: overlayColor ?? AppColors.loadingOverlayColor,
      child: Center(
        child: LoadingIndicator(
          size: indicatorSize,
          color: indicatorColor ?? AppColors.loadingIndicatorColor,
        ),
      ),
    );
  }
}
