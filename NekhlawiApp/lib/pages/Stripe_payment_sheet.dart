import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STRIPE PAYMENT SHEET
// ─────────────────────────────────────────────────────────────────────────────
// USAGE:
//   final success = await StripePaymentSheet.show(context, booking: myBooking);
//   Returns true on success, false/null if cancelled.
// ─────────────────────────────────────────────────────────────────────────────

class BookingSummary {
  final String expertName;
  final String expertTitle;
  final String date;
  final String time;
  final int amountSAR;

  const BookingSummary({
    required this.expertName,
    required this.expertTitle,
    required this.date,
    required this.time,
    required this.amountSAR,
  });
}

class StripePaymentSheet {
  static Future<bool?> show(
    BuildContext context, {
    required BookingSummary booking,
  }) async {
    final supabase = Supabase.instance.client;

    // ── Show booking summary bottom sheet first ───────────────────────────────
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingSummarySheet(booking: booking),
    );

    if (confirmed != true || !context.mounted) return false;

    // ── Call Supabase Edge Function to create PaymentIntent ───────────────────
    try {
      final response = await supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': booking.amountSAR * 100, // SAR → halalas
          'currency': 'sar',
        },
      );

      if (response.data == null || response.data['clientSecret'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في إنشاء عملية الدفع. حاول مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }

      final String clientSecret = response.data['clientSecret'];

      // ── Initialize Stripe native sheet ────────────────────────────────────
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'نخلاوي',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF797F3D),
            ),
          ),
        ),
      );

      // ── Present Stripe native sheet ───────────────────────────────────────
      await Stripe.instance.presentPaymentSheet();

      // ── Payment succeeded ─────────────────────────────────────────────────
      return true;
    } on StripeException catch (e) {
      // User cancelled or card declined — do nothing, return false
      if (e.error.code != FailureCode.Canceled && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.error.localizedMessage ?? 'فشل الدفع، حاول مرة أخرى.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING SUMMARY BOTTOM SHEET
// Shows expert info + price before opening Stripe native sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingSummarySheet extends StatelessWidget {
  final BookingSummary booking;

  const _BookingSummarySheet({required this.booking});

  static const Color kPrimary = Color(0xFF797F3D);
  static const Color kDarkBrown = Color(0xFF43321A);
  static const Color kBeige = Color(0xFFF2F0E8);
  static const Color kBorder = Color(0xFFE0DDD6);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kBeige,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدفع الآمن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kDarkBrown,
                      ),
                    ),
                    Text(
                      'بيانات بطاقتك محمية بالكامل',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF635BFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Stripe',
                    style: TextStyle(
                      color: Color(0xFF635BFF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // booking summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBeige,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin_outlined,
                          color: kPrimary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        booking.expertName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kDarkBrown,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        booking.expertTitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _chip(Icons.calendar_today_outlined, booking.date),
                      _chip(Icons.access_time_outlined, booking.time),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${booking.amountSAR} ر.س',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // pay button → opens Stripe native sheet
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'ادفع ${booking.amountSAR} ريال',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'مشفر بـ SSL 256-bit',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 13, color: kDarkBrown)),
      ],
    );
  }
}