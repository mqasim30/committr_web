// lib/widgets/loading_overlay.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'loading_indicator.dart';

class LoadingOverlay extends StatelessWidget {
  final int opacity; // Expected to be between 0 and 255
  final Color? overlayColor;
  final double indicatorSize;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    this.opacity = 255,
    this.overlayColor,
    this.indicatorSize = 50.0,
    this.indicatorColor,
  }) : assert(opacity >= 0 && opacity <= 255,
            'Opacity must be between 0 and 255');

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (overlayColor ?? AppColors.loadingOverlayColor).withAlpha(opacity),
      child: Center(
        child: LoadingIndicator(
          size: indicatorSize,
          color: indicatorColor ?? AppColors.loadingIndicatorColor,
        ),
      ),
    );
  }
}
