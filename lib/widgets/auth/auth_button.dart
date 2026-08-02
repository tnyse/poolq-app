import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';

/// Enhanced authentication button with Material Design 3 styling
class AuthButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final AuthButtonType type;
  final IconData? icon;
  final bool fullWidth;

  const AuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AuthButtonType.primary,
    this.icon,
    this.fullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = _buildButtonContent();
    
    switch (type) {
      case AuthButtonType.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: AppTheme.primaryButtonStyle,
            child: buttonChild,
          ),
        );
      
      case AuthButtonType.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: AppTheme.secondaryButtonStyle,
            child: buttonChild,
          ),
        );
      
      case AuthButtonType.outline:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: AppTheme.outlineButtonStyle,
            child: buttonChild,
          ),
        );
      
      case AuthButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

/// Button type variants for different use cases
enum AuthButtonType {
  primary,
  secondary,
  outline,
  text,
} 