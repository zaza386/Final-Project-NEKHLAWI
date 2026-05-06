import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  static const String _modelFile = 'assets/AIModel/palm_model.tflite';
  Interpreter? _interpreter;

  final List<String> _labels = [
    'البقع البنية',
    'حشرة دباس النخيل',
    'ورقة سليمة',
    'الحشرة القشرية البيضاء',
  ];

  static const int inputSize = 240;

  Classifier() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(_modelFile, options: options);
      print('✅ تم تحميل موديل EfficientNet بنجاح');
    } catch (e) {
      print('❌ خطأ في تحميل الموديل: $e');
    }
  }

  bool _isValidPalmColor(img.Image image) {
    int totalR = 0, totalG = 0, totalB = 0;
    int samplingStep = 10;
    int count = 0;

    for (int y = 0; y < image.height; y += samplingStep) {
      for (int x = 0; x < image.width; x += samplingStep) {
        var pixel = image.getPixel(x, y);
        totalR += pixel.r.toInt();
        totalG += pixel.g.toInt();
        totalB += pixel.b.toInt();
        count++;
      }
    }

    double avgR = totalR / count;
    double avgG = totalG / count;
    double avgB = totalB / count;

    // --- 1. استبعاد الألوان الفاقعة وغير الطبيعية ---
    if (avgG > 200 && avgR < 120)
      return false; // أخضر فاقع جداً (أشجار زينة صناعية)
    if (avgB > avgG && avgB > avgR) return false; // سماء أو ملابس زرقاء
    if (avgR > 240 && avgG > 240 && avgB > 240)
      return false; // بياض فاقع جداً (إضاءة شمس قوية أو جدار أبيض)

    // --- 2. استبعاد اللون الأسود أو الظلام الدامس ---
    // إذا كانت كل الألوان منخفضة جداً (الصورة مظلمة أو مصور خلفية سوداء)
    if (avgR < 30 && avgG < 30 && avgB < 30) return false;

    // --- 3. استبعاد ألوان بشرة الإنسان (Skin Tones) ---
    // درجات البشرة عادة تكون فيها الأحمر (R) أعلى من الأخضر (G) وبينهما فرق معين
    // واللون الأزرق (B) يكون الأقل دائماً
    if (avgR > avgG && avgG > avgB) {
      double rgDiff = avgR - avgG;
      // إذا كان الفرق بين الأحمر والأخضر كبير (سمات لون البشرة)
      if (rgDiff > 20 && rgDiff < 70 && avgR > 100) return false;
    }

    // --- 4. استبعاد الألوان الصناعية الصارخة (مثل الأحمر أو الفوشي) ---
    if (avgR > 180 && avgG < 100 && avgB < 100) return false; // أحمر فاقع

    // --- 5. القاعدة الذهبية للنخيل (أخضر داكن، زيتوني، أو بني جاف) ---
    // أوراق النخل الطبيعية دائماً يكون فيها الأخضر أو الأحمر (لليابس) أعلى من الأزرق
    bool isNaturalTone = (avgG > avgB || avgR > avgB);

    // تأكدي أن الصورة ليست رمادية تماماً (ألوان متساوية)
    bool isNotGrey = (avgR - avgG).abs() > 5 || (avgG - avgB).abs() > 5;

    return isNaturalTone && isNotGrey;
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    if (_interpreter == null) {
      await _loadModel();
      if (_interpreter == null)
        return {"label": "الموديل غير جاهز", "confidence": 0.0};
    }

    try {
      final imageBytes = imageFile.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null)
        return {"label": "خطأ في معالجة الصورة", "confidence": 0.0};

      // 💡 فحص الألوان قبل تشغيل الموديل
      if (!_isValidPalmColor(decodedImage)) {
        return {"label": "غير قادر على التحديد بدقة", "confidence": 0.0};
      }

      final resizedImage = img.copyResize(
        decodedImage,
        width: inputSize,
        height: inputSize,
      );
      var input = _imageToBuffer(resizedImage);
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);

      _interpreter!.run(input, output);
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

      // رفعنا حد الثقة لضمان أن الصورة المختارة تشبه النخيل فعلاً
      if (confidence < 85.0) {
        return {"label": "غير قادر على التحديد بدقة", "confidence": confidence};
      }

      return {"label": _labels[maxIndex], "confidence": confidence};
    } catch (e) {
      return {"label": "خطأ تقني", "confidence": 0.0};
    }
  }

  List<List<List<List<double>>>> _imageToBuffer(img.Image image) {
    return List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          var pixel = image.getPixel(x, y);
          return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
        }),
      ),
    );
  }
}
