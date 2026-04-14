import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  // تأكدي أن المسار يطابق مجلدات مشروعك بالضبط (حساس لحالة الأحرف)
  static const String _modelFile = 'assets/AIModel/palm_model.tflite';

  Interpreter? _interpreter;

  // التصنيفات الأربعة كما حددتيها
  final List<String> _labels = [
    'الورقة سليمة',
    'مصابة بالحشرة العسلية',
    'مصابة بالبقع البنية',
    'مصابة بالحشرة البيضاء'
  ];

  static const int inputSize = 240; // الحجم المطلوب للموديل

  Classifier() {
    _loadModel();
  }

  // تحميل الموديل
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelFile);
      print('✅ تم تحميل موديل نخلاوي بنجاح (إصدار 0.12.0)');
    } catch (e) {
      print('❌ خطأ في تحميل الموديل: $e');
    }
  }

  // الدالة الأساسية للتنبؤ
  Future<String> predict(File imageFile) async {
    if (_interpreter == null) {
      // محاولة تحميل الموديل إذا لم يكن جاهزاً
      await _loadModel();
      if (_interpreter == null) return "المحلل غير جاهز بعد...";
    }

    try {
      // 1. معالجة الصورة وقراءتها
      final imageBytes = imageFile.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return "فشل في قراءة الصورة";

      // 2. تغيير الحجم إلى 240x240
      final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);

      // 3. تحويل الصورة إلى مصفوفة رباعية الأبعاد [1, 240, 240, 3]
      // هذا التعديل يحل مشكلة failed precondition
      var input = _imageToBuffer(resizedImage);

      // 4. تجهيز مصفوفة المخرجات لـ 4 تصنيفات [1, 4]
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);

      // 5. تشغيل الموديل
      _interpreter!.run(input, output);

      // 6. الحصول على النتيجة الأعلى
      List<double> results = List<double>.from(output[0]);
      double maxScore = -1.0;
      int maxIndex = 0;

      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      print("توقع الموديل: ${_labels[maxIndex]} بنسبة ثقة: ${results[maxIndex]}");
      return _labels[maxIndex];

    } catch (e) {
      print("خطأ أثناء التحليل: $e");
      return "حدث خطأ أثناء التحليل: $e";
    }
  }

  // دالة تحويل الصورة إلى مصفوفة بيانات منظمة (Normalization)
  List<List<List<List<double>>>> _imageToBuffer(img.Image image) {
    // بناء مصفوفة [1, 240, 240, 3]
    return List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) {
            var pixel = image.getPixel(x, y);
            // تقسيم القيم على 255 لتحويلها لنطاق 0-1 (Float32)
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
  }
}