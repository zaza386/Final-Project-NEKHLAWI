import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  static const String _modelFile = 'assets/AIModel/palm_model.tflite';
  Interpreter? _interpreter;

  // ⚠️ تنبيه: تأكدي أن الترتيب هنا يطابق تماماً ترتيب المجلدات أثناء التدريب
  final List<String> _labels = [
    'البقع البنية',
    'حشرة دباس النخيل',
    'ورقة سليمة',
    'الحشرة القشرية البيضاء'
  ];

  // EfficientNetB0 غالباً يستخدم 240 أو 224
  static const int inputSize = 240;

  Classifier() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // إعداد خيارات المترجم لتحسين الأداء
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(_modelFile, options: options);
      print('✅ تم تحميل موديل EfficientNet بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل الموديل: $e');
    }
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) {
      await _loadModel();
      if (_interpreter == null) return {"label": "الموديل غير جاهز", "confidence": 0.0};
    }

    try {
      // 1. قراءة وتحويل الصورة
      final imageBytes = imageFile.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return {"label": "خطأ في معالجة الصورة", "confidence": 0.0};

      // 2. تغيير الحجم ليناسب EfficientNet
      final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);

      // 3. تحويل الصورة إلى تنسيق يدعمه الموديل (Normalization)
      var input = _imageToBuffer(resizedImage);

      // 4. تجهيز مصفوفة المخرجات (لدينا 4 فئات)
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);

      // 5. تشغيل الموديل
      _interpreter!.run(input, output);

      // 6. استخراج النتائج
      List<double> results = List<double>.from(output[0]);

      int maxIndex = 0;
      double maxScore = results[0];

      for (int i = 1; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      double confidence = maxScore * 100;

      // 💡 منطق إضافي لتجنب انحياز "Healthy":
      // إذا كانت الثقة ضعيفة جداً، يفضل تنبيه المستخدم
      if (confidence < 40.0) {
        return {
          "label": "غير قادر على التحديد بدقة",
          "confidence": confidence,
        };
      }

      return {
        "label": _labels[maxIndex],
        "confidence": confidence,
      };

    } catch (e) {
      print("❌ خطأ أثناء التحليل: $e");
      return {"label": "خطأ تقني", "confidence": 0.0};
    }
  }

  // دالة تحويل الصورة إلى مصفوفة (Tensor)
  List<List<List<List<double>>>> _imageToBuffer(img.Image image) {
    return List.generate(1, (i) => List.generate(inputSize, (y) => List.generate(inputSize, (x) {
      var pixel = image.getPixel(x, y);
      return [
        pixel.r.toDouble(),
        pixel.g.toDouble(),
        pixel.b.toDouble()
      ];
    })));
  }
}