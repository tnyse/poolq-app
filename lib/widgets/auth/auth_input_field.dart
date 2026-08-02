import 'package:flutter/material.dart';
import 'package:poolqapp/constants/app_theme.dart';

/// Enhanced authentication input field with Material Design 3 styling
class AuthInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChanged;
  final bool enabled;
  final int? maxLines;
  final String? helperText;
  final bool autofocus;

  const AuthInputField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.helperText,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.labelText != null) ...[
              Text(
                widget.labelText!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _isFocused ? AppTheme.primaryBlue : AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
                if (hasFocus) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              child: TextFormField(
                controller: widget.controller,
                obscureText: widget.isPassword ? _obscureText : false,
                validator: widget.validator,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onFieldSubmitted: widget.onFieldSubmitted,
                onChanged: widget.onChanged,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                autofocus: widget.autofocus,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  helperText: widget.helperText,
                  helperStyle: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                  prefixIcon: widget.prefixIcon != null 
                      ? Icon(
                          widget.prefixIcon,
                          color: _isFocused ? AppTheme.primaryBlue : AppTheme.onSurfaceVariant,
                          size: 20,
                        )
                      : null,
                  suffixIcon: _buildSuffixIcon(),
                  
                  // Enhanced visual feedback
                  filled: true,
                  fillColor: _isFocused 
                      ? AppTheme.primaryBlue.withOpacity(0.05)
                      : AppTheme.surfaceVariant,
                  
                  // Semantic labels for accessibility
                  semanticCounterText: widget.isPassword ? 'Password field' : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            key: ValueKey(_obscureText),
            color: _isFocused ? AppTheme.primaryBlue : AppTheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        tooltip: _obscureText ? 'Show password' : 'Hide password',
        splashRadius: 20,
      );
    }
    
    return widget.suffixIcon;
  }
} 