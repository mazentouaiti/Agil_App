import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AgilLogo extends StatelessWidget {
  final double size;
  
  const AgilLogo({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.local_gas_station,
          size: size * 0.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
