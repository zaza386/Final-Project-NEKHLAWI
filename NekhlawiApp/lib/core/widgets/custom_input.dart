import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final bool showError;
  final Function(String)? onChanged;
  final Function(bool)? onValidationChanged;

  const CustomInput({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.showError = false,
    this.onChanged,
    this.onValidationChanged,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isPasswordVisible = false;
  bool _isValid = true;

  bool get _isEmail =>
      widget.icon == Icons.email_outlined;

  bool _validatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasNumber = password.contains(RegExp(r'\d'));
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasSymbol =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasMinLength && hasNumber && hasUpperCase && hasSymbol;
  }

  bool _validateEmail(String email) {
    final regex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool _validateInput(String value) {
    if (widget.isPassword) {
      return _validatePassword(value);
    }
    if (_isEmail) {
      return _validateEmail(value);
    }
    return true;
  }

  bool get _hasError {
    if (widget.showError && widget.controller.text.isEmpty) return true;
    if (!_isValid) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword && !_isPasswordVisible,
      textDirection: TextDirection.rtl,
      onChanged: (value) {
        widget.onChanged?.call(value);

        final valid = _validateInput(value);
        if (_isValid != valid) {
          setState(() => _isValid = valid);
          widget.onValidationChanged?.call(valid);
        }
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon),

        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: _hasError ? Colors.red : Colors.grey.shade400,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: _hasError ? Colors.red : Colors.grey,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}