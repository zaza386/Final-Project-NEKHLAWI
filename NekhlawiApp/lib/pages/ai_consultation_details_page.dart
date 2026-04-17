import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'analysis_indocator.dart';

class AiConsultationDetailsPage extends StatefulWidget {
  final String title;
  final String sessionId;

  const AiConsultationDetailsPage({
    super.key,
    required this.title,
    required this.sessionId,
  });

  @override
  State<AiConsultationDetailsPage> createState() => _AiConsultationDetailsPageState();
}

class _AiConsultationDetailsPageState extends State<AiConsultationDetailsPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();

    // إظهار التعليمات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog(context);
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
        _initializeControllerFuture = _cameraController!.initialize();
        await _initializeControllerFuture;
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في تهيئة الكاميرا: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // دالة للانتقال لصفحة "جاري التحليل" وتمرير ملف الصورة
  void _navigateToAnalysis(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingPage(
          imageFile: imageFile, // نرسل الصورة لصفحة المعالجة وهي تتولى الباقي
        ),
      ),
    );
  }

  Future<void> _openGallery() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      _navigateToAnalysis(File(image.path));
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      _navigateToAnalysis(File(image.path));
    } catch (e) {
      debugPrint("خطأ أثناء التقاط الصورة: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFC7C7A3);
    const Color darkColor = Color(0xFF43321A);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // عرض الكاميرا
            Positioned.fill(
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : Container(
                color: primaryColor.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: darkColor)),
              ),
            ),

            // شريط العنوان العلوي
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 15, left: 20, right: 20
                ),
                color: primaryColor,
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back, color: darkColor, size: 28),
                        onPressed: () => Navigator.pop(context)
                    ),
                    const Text(
                        'العودة',
                        style: TextStyle(color: darkColor, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const Spacer(),
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: darkColor, shape: BoxShape.circle),
                        child: const Icon(Icons.flash_on, color: Colors.white, size: 20)
                    ),
                  ],
                ),
              ),
            ),

            // أزرار التحكم السفلية
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر المعرض
                  GestureDetector(
                    onTap: _openGallery,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: darkColor, width: 2)
                      ),
                      child: const Icon(Icons.photo_library_outlined, color: darkColor, size: 32),
                    ),
                  ),

                  // زر التقاط الصورة الكبير
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 85, width: 85,
                      decoration: BoxDecoration(
                          color: darkColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                          ]
                      ),
                    ),
                  ),

                  // مساحة فارغة للتوازن البصري
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.grey))
                ),
                const Text(
                    "تعليمات الصورة",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))
                ),
                const SizedBox(height: 20),
                const Icon(Icons.error, color: Colors.red, size: 70),
                const SizedBox(height: 20),
                const Text(
                    "تأكد أن الصورة واضحة ومنورة عشان نعطيك افضل نتيجة.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.5)
                ),
                const SizedBox(height: 25),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7E8449),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("فهمت", style: TextStyle(color: Colors.white, fontSize: 18))
                    )
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}