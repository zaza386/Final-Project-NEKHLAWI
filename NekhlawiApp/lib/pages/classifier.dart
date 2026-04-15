import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  static const String _modelFile = 'assets/AIModel/palm_model.tflite';
  Interpreter? _interpreter;

  // تأكدي من مطابقة هذه الأسماء لجدول Disease في السوبابيس تماماً
  final List<String> _labels = [
    'البقع البنية',
    'حشرة دباس النخيل',
    'ورقة سليمة',
    'الحشرة القشرية البيضاء'
  ];

  static const int inputSize = 240;

  Classifier() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelFile);
      print('✅ تم تحميل موديل نخلاوي بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل الموديل: $e');
    }
  }

  // الدالة الآن تعيد Map بدلاً من String
  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) {
      await _loadModel();
      if (_interpreter == null) return {"label": "غير جاهز", "confidence": 0.0};
    }

    try {
      final imageBytes = imageFile.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return {"label": "خطأ صورة", "confidence": 0.0};

      final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);
      var input = _imageToBuffer(resizedImage);
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);

      _interpreter!.run(input, output);

      List<double> results = List<double>.from(output[0]);
      double maxScore = -1.0;
      int maxIndex = 0;

      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      // حساب النسبة المئوية وتحويلها لـ double
      double confidence = results[maxIndex] * 100;

      return {
        "label": _labels[maxIndex],
        "confidence": confidence,
      };

    } catch (e) {
      print("خطأ أثناء التحليل: $e");
      return {"label": "خطأ برمجى", "confidence": 0.0};
    }
  }

  List<List<List<List<double>>>> _imageToBuffer(img.Image image) {
    return List.generate(1, (_) => List.generate(inputSize, (y) => List.generate(inputSize, (x) {
      var pixel = image.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));
  }
}