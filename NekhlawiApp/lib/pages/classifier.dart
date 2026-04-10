import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  // المسارات (تأكدي من مطابقة حالة الأحرف في مجلد Assets)
  static const String _modelFile = 'assets/AIModel/palm_model.tflite';

  Interpreter? _interpreter;

  // ترتيب التصنيفات بناءً على كلامك
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

  // تحميل الموديل في الإصدار الجديد 0.12.0
  Future<void> _loadModel() async {
    try {
      // تم تحديث طريقة التحميل هنا لتناسب الإصدار الجديد
      _interpreter = await Interpreter.fromAsset(_modelFile);
      print('✅ تم تحميل موديل نخلاوي بنجاح (إصدار 0.12.0)');
    } catch (e) {
      print('❌ خطأ في تحميل الموديل: $e');
    }
  }

  Future<String> predict(File imageFile) async {
    if (_interpreter == null) return "المحلل غير جاهز بعد...";

    try {
      // 1. معالجة الصورة (تغيير الحجم لـ 240)
      final imageBytes = imageFile.readAsBytesSync();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return "فشل في قراءة الصورة";

      final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);

      // 2. تحويل الصورة إلى مصفوفة بيانات Float32
      var input = _imageToByteListFloat32(resizedImage, inputSize);

      // 3. تجهيز مكان النتيجة (4 تصنيفات)
      // ملاحظة: الإصدار الجديد يفضل استخدام Float32List للمخرجات أيضاً
      var output = List.filled(1 * 4, 0.0).reshape([1, 4]);

      // 4. تشغيل التنبؤ
      _interpreter!.run(input, output);

      // 5. استخراج النتيجة الأعلى
      List<double> results = List<double>.from(output[0]);
      double maxScore = -1.0;
      int maxIndex = 0;

      for (int i = 0; i < results.length; i++) {
        if (results[i] > maxScore) {
          maxScore = results[i];
          maxIndex = i;
        }
      }

      return _labels[maxIndex];

    } catch (e) {
      return "حدث خطأ أثناء التحليل: $e";
    }
  }

  Uint8List _imageToByteListFloat32(img.Image image, int size) {
    var convertedBytes = Float32List(1 * size * size * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        var pixel = image.getPixel(j, i);

        // استخدام الطريقة الجديدة المتوافقة مع مكتبة image 4.0+
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}