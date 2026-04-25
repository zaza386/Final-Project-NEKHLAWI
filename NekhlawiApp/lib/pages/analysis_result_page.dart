import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'booking_experts_page.dart';
import 'package:exif/exif.dart';
import 'dart:convert'; // ضروري لتحويل البيانات لـ JSON

class AnalysisResultPage extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final String aiLabel;
  final double confidence;
  final Map<String, dynamic>? diseaseInfo;
  final Map<String, dynamic>? treatmentInfo;
  final String sessionId;

  const AnalysisResultPage({
    super.key,
    this.imageFile,
    this.imageUrl,
    required this.aiLabel,
    required this.confidence,
    required this.sessionId,
    this.diseaseInfo,
    this.treatmentInfo,
  });

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.imageFile != null && widget.imageUrl != null) {
      _saveAllDataToDatabase();
    }
  }

  Future<void> _saveAllDataToDatabase() async {
    try {
      // 1. حفظ بيانات التشخيص
      if (widget.diseaseInfo != null) {
        await supabase.from('AIDiagnosis Table').upsert({
          'AISessionID': widget.sessionId,
          'DiseaseID': widget.diseaseInfo!['DiseaseID'],
          'Confidence': "${widget.confidence.toStringAsFixed(0)}%",
        });
      }

      // 2. حفظ بيانات الصورة مع الـ EXIF والأبعاد
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        int? width;
        int? height;
        Map<String, String> exifData = {};

        if (widget.imageFile != null) {
          final bytes = await widget.imageFile!.readAsBytes();

          // استخراج أبعاد الصورة
          final decodedImage = await decodeImageFromList(bytes);
          width = decodedImage.width;
          height = decodedImage.height;

          // استخراج بيانات الـ EXIF
          final tags = await readExifFromBytes(bytes);
          if (tags.isNotEmpty) {
            tags.forEach((key, value) {
              // تحويل البيانات لنصوص لتخزينها في JSON
              exifData[key] = value.toString();
            });
          }
        }

        await supabase.from('AISessionPicture').insert({
          'AISessionID': widget.sessionId,
          'FileURL': widget.imageUrl,
          'Width': width ?? 0,
          'Height': height ?? 0,
          // تحويل الماب إلى JSON String ليتم حفظه في حقل الـ json الخاص بـ Supabase
          'EXIFJson': exifData.isNotEmpty ? exifData : null,
        });

        print("✅ تم حفظ جميع البيانات (الأبعاد + EXIF) بنجاح");
      }
    } catch (e) {
      debugPrint("❌ خطأ أثناء الحفظ: $e");
    }
  }

  // ميثود توليد وحفظ ملف الـ PDF باستخدام خط من الإنترنت لتجنب مشاكل الـ Assets
  Future<void> _generatePDF() async {
    try {
      final pdf = pw.Document();

      // 💡 التعديل هنا: سحب الخط من الإنترنت مباشرة عشان يشتغل معك الحين بدون ما تلمسين الـ Assets
      final fontData = await NetworkAssetBundle(Uri.parse('https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf')).load("");
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(child: pw.Text("تقرير تشخيص نخلاوي", style: pw.TextStyle(font: ttf, fontSize: 26, fontWeight: pw.FontWeight.bold))),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.SizedBox(height: 20),
                    pw.Text("الحالة المكتشفة: ${widget.aiLabel}", style: pw.TextStyle(font: ttf, fontSize: 18)),
                    pw.Text("نسبة الثقة: ${widget.confidence.toStringAsFixed(0)}%", style: pw.TextStyle(font: ttf, fontSize: 18)),
                    pw.SizedBox(height: 20),
                    pw.Text("الأعراض:", style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.Text(widget.diseaseInfo?['Symptoms'] ?? "لا توجد تفاصيل", style: pw.TextStyle(font: ttf, fontSize: 14)),
                    pw.SizedBox(height: 20),
                    pw.Text("خطة العلاج:", style: pw.TextStyle(font: ttf, fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.Text(widget.treatmentInfo?['Steps'] ?? "لا توجد تفاصيل", style: pw.TextStyle(font: ttf, fontSize: 14)),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // يفتح صفحة الحفظ والمشاركة فوراً
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      debugPrint("خطأ في الـ PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF43321A);
    const Color lightBeige = Color(0xFFD9E0B3);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: lightBeige,
        appBar: AppBar(
          title: const Text("نتائج التحليل", style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share, size: 26, color: darkBrown),
              onPressed: _generatePDF,
              tooltip: "حفظ كـ PDF",
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: widget.imageFile != null
                    ? Image.file(widget.imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover)
                    : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ? Image.network(widget.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 180, color: Colors.grey[300], child: const Icon(Icons.image)),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      _buildResultCard(widget.aiLabel, widget.confidence),
                      const SizedBox(height: 30),
                      _buildSection("الأعراض:", widget.diseaseInfo?['Symptoms'] ?? "لا توجد تفاصيل."),
                      _buildSection("العلاج:", widget.treatmentInfo?['Steps'] ?? "لا يتوفر علاج حالياً."),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingExpertsPage())),
                        child: Column(
                          children: [
                            const Text("بستشير خبيراً", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBrown)),
                            Container(margin: const EdgeInsets.only(top: 2), height: 1.5, width: 100, color: darkBrown),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
        const Divider(height: 35),
      ],
    );
  }

  Widget _buildResultCard(String label, double conf) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFD9E0B3).withOpacity(0.3), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          CircularProgressIndicator(value: conf / 100, color: const Color(0xFF7B8646), strokeWidth: 6),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF43321A))),
              Text("الدقة: ${conf.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }
}