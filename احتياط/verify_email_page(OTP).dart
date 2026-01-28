import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nekhlawi_app/pages/reset_password_page.dart';
import '../core/widgets/header_background.dart';
import '../core/widgets/primary_button.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // الخلفية
            Container(color: Colors.white),

            // الهيدر (السهم على اليمين تلقائيًا مع RTL)
            const HeaderBackground(
              title: 'تأكيد الإيميل',
              showBack: true,
            ),

            // المحتوى
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),

                              const Text(
                                'نسيت كلمة المرور؟',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'الآن شيّك إيميلك، بنشوف رمز مكوّن من 4 أرقام',
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 50),

                              // ===== OTP =====
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  4,
                                  (index) => _OtpBox(),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: إعادة إرسال الرمز
                                  },
                                  child: const Text(
                                    'ما وصلك الرمز؟ أعد الإرسال',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              PrimaryButton(
                                title: 'تأكيد',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ResetPasswordPage(),
                                    ),
                                  );
                                },
                              ),

                              const Spacer(),

                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    '©️ 2025 - 2026',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مربع OTP واحد
class _OtpBox extends StatefulWidget {
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const _OtpBox({
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            widget.onChanged?.call(value);
          }
        },
        onSubmitted: (value) {
          widget.onSubmitted?.call(value);
        },
      ),
    );
  }
}