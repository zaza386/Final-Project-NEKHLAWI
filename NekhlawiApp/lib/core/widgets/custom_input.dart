import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;

  /// للمقارنة (مثلاً تأكيد كلمة المرور)
  final TextEditingController? matchWith;

  /// هل نتحقق من شروط كلمة المرور؟
  final bool validateRules;

  final bool enabled;
  final bool showError;
  final TextInputType? keyboardType;

  final Function(String)? onChanged;
  final Function(bool)? onValidationChanged;

  const CustomInput({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.matchWith,
    this.validateRules = true,
    this.enabled = true,
    this.showError = false,
    this.keyboardType,
    this.onChanged,
    this.onValidationChanged,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isPasswordVisible = false;
  bool _isValid = true;

  bool get _isEmail => widget.icon == Icons.email_outlined;

  bool _validatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasNumber = password.contains(RegExp(r'\d'));
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasSymbol =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasMinLength &&
        hasNumber &&
        hasUpperCase &&
        hasLowerCase &&
        hasSymbol;
  }

  List<String> _unmetPasswordRules(String password) {
    final rules = <String, bool>{
      "على الأقل ٨ أحرف": password.length >= 8,
      "حرف كبير (A-Z)": RegExp(r"[A-Z]").hasMatch(password),
      "حرف صغير (a-z)": RegExp(r"[a-z]").hasMatch(password),
      "رقم (0-9)": RegExp(r"\d").hasMatch(password),
      "رمز خاص (!@#...)":
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
    };

    return rules.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();
  }

  bool _validateEmail(String email) {
    final regex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool _validateMatch() {
    if (widget.matchWith == null) return true;

    final a = widget.controller.text;
    final b = widget.matchWith!.text;

    if (a.isEmpty || b.isEmpty) return true;

    return a == b;
  }

  bool _validateInput(String value) {
    if (value.isEmpty) return true;

    if (widget.isPassword && widget.validateRules) {
      return _validatePassword(value);
    }

    if (_isEmail) {
      return _validateEmail(value);
    }

    return true;
  }

  void _revalidate() {
    final value = widget.controller.text;

    final validInput = _validateInput(value);
    final validMatch = _validateMatch();

    final next = validInput && validMatch;

    if (_isValid != next) {
      setState(() => _isValid = next);
      widget.onValidationChanged?.call(next);
    } else {
      setState(() {});
    }
  }

  void _matchListener() => _revalidate();

  @override
  void initState() {
    super.initState();
    widget.matchWith?.addListener(_matchListener);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _revalidate());
  }

  @override
  void didUpdateWidget(covariant CustomInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.matchWith != widget.matchWith) {
      oldWidget.matchWith?.removeListener(_matchListener);
      widget.matchWith?.addListener(_matchListener);
      _revalidate();
    }
  }

  @override
  void dispose() {
    widget.matchWith?.removeListener(_matchListener);
    super.dispose();
  }

  bool get _hasError {
    if (!widget.enabled) return false;

    if (widget.controller.text.isEmpty) return false;

    if (widget.showError &&
        widget.controller.text.isEmpty) return true;

    if (!_isValid) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    final unmet =
        (widget.isPassword && widget.validateRules)
            ? _unmetPasswordRules(text)
            : const <String>[];

    final showMatchWarning =
        widget.matchWith != null &&
            widget.controller.text.isNotEmpty &&
            widget.matchWith!.text.isNotEmpty &&
            widget.controller.text != widget.matchWith!.text;

    final showEmailWarning =
        _isEmail &&
            text.isNotEmpty &&
            !_validateEmail(text);

    final showPasswordRulesBox =
        widget.isPassword &&
            widget.validateRules &&
            widget.enabled &&
            text.isNotEmpty &&
            unmet.isNotEmpty;

    final showPasswordSuccess =
        widget.isPassword &&
            widget.enabled &&
            text.isNotEmpty &&
            unmet.isEmpty &&
            !showMatchWarning &&
            (widget.matchWith == null ||
                _validateMatch());

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText:
              widget.isPassword &&
                  !_isPasswordVisible,
          textDirection:
              TextDirection.rtl,
          keyboardType:
              widget.keyboardType,
          onChanged: (value) {
            widget.onChanged?.call(value);
            _revalidate();
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                Icon(widget.icon),
            suffixIcon:
                widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons
                                  .visibility
                              : Icons
                                  .visibility_off,
                        ),
                        onPressed: () =>
                            setState(() =>
                                _isPasswordVisible =
                                    !_isPasswordVisible),
                      )
                    : null,
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                      22),
              borderSide: BorderSide(
                color: _hasError
                    ? Colors.red
                    : Colors
                        .grey
                        .shade400,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                      22),
              borderSide:
                  BorderSide(
                color: _hasError
                    ? Colors.red
                    : Colors.grey,
                width: 1.5,
              ),
            ),
          ),
        ),

        // رسالة الإيميل
        if (widget.enabled &&
            showEmailWarning)
          _errorBox(
              "صيغة الإيميل غير صحيحة."),

        // شروط كلمة المرور
        if (showPasswordRulesBox)
          _rulesBox(unmet),

        // عدم التطابق (مستقلة)
        if (widget.enabled &&
            showMatchWarning)
          _errorBox(
              "تأكيد كلمة المرور غير مطابق."),

        // نجاح كلمة المرور
        if (showPasswordSuccess)
          _successBox(),
      ],
    );
  }

  Widget _rulesBox(
      List<String> unmet) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
              top: 8),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFFBEB),
        borderRadius:
            BorderRadius.circular(
                16),
        border: Border.all(
            color:
                const Color(
                    0xFFFFD4D4)),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            "شروط كلمة المرور (يختفي الشرط إذا تحقق):",
            style: TextStyle(
                fontWeight:
                    FontWeight.w900,
                color: Color(
                    0xFF92400E)),
          ),
          const SizedBox(height: 8),
          ...unmet.map(
            (r) => Padding(
              padding:
                  const EdgeInsets
                      .only(
                      bottom: 6),
              child: Text(
                r,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .w700,
                  color: Color(
                      0xFF92400E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(
      String message) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
              top: 8),
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF5F5),
        borderRadius:
            BorderRadius.circular(
                16),
        border: Border.all(
            color:
                const Color(
                    0xFFFFD4D4)),
      ),
      child: Row(
        children: [
          const Icon(
              Icons
                  .warning_amber_rounded,
              size: 18,
              color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w900,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBox() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
              top: 8),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            const Color(0xFFECFDF5),
        borderRadius:
            BorderRadius.circular(
                16),
        border: Border.all(
            color:
                const Color(
                    0xFFBBF7D0)),
      ),
      child: const Text(
        "✅ كلمة المرور ممتازة.",
        style: TextStyle(
            fontWeight:
                FontWeight.w800,
            color: Color(
                0xFF065F46)),
      ),
    );
  }
}