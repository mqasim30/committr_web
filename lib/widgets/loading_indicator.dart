// lib/widgets/loading_indicator.dart

import 'package:flutter/material.dart';
import '../constants/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const LoadingIndicator({
    super.key,
    this.size = 50.0,
    this.color = AppColors.loadingIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 5.0,
      ),
    );
  }
}
