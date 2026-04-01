import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AiConsultationDetailsPage extends StatefulWidget {
  final String title;
  const AiConsultationDetailsPage({super.key, required this.title});

  @override
  State<AiConsultationDetailsPage> createState() => _AiConsultationDetailsPageState();
}

class _AiConsultationDetailsPageState extends State<AiConsultationDetailsPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isCameraInitialized = false;

  // تعريف عميل سوبابيس للتعامل مع قاعدة البيانات والتخزين
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initCamera();

    // إظهار نافذة التعليمات تلقائياً عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsDialog(context);
    });
  }

  // تهيئة الكاميرا داخلياً
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

  // الدالة الأساسية: التحقق من المستخدم، إنشاء الجلسة، ورفع الصورة
  Future<void> _processAndSaveImage(File imageFile) async {
    // 1. التحقق من وجود مستخدم مسجل قبل البدء
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('انتهت جلستك، يرجى تسجيل الدخول مجدداً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // إظهار مؤشر تحميل (Loading)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF43321A)),
        ),
      );

      // 2. إنشاء جلسة جديدة (AISession) مرتبطة باليوزر الحالي
      final sessionResponse = await supabase
          .from('AISession')
          .insert({
        'UserID': user.id, // التأكد من مطابقة اسم الحقل في سوبابيس
        'created_at': DateTime.now().toIso8601String(),
      })
          .select('AISessionID')
          .single();

      final String realSessionId = sessionResponse['AISessionID'];

      // 3. معالجة أبعاد الصورة
      final decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      final int width = decodedImage.width;
      final int height = decodedImage.height;

      // 4. رفع الصورة إلى بكت pic
      final String fileName = 'palm_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage
          .from('pic')
          .upload(fileName, imageFile);

      // 5. الحصول على الرابط العام (FileURL)
      final String publicUrl = supabase.storage.from('pic').getPublicUrl(fileName);

      // 6. حفظ البيانات في جدول AISessionPicture
      await supabase.from('AISessionPicture').insert({
        'AISessionID': realSessionId,
        'FileURL': publicUrl,
        'Width': width,
        'Height': height,
        'EXIFJson': {},
      });

      if (mounted) {
        Navigator.pop(context); // إغلاق الـ Loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الصورة وحفظ الاستشارة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // إغلاق الـ Loading في حال الخطأ
      debugPrint("خطأ سوبابيس: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // فتح الألبوم واختيار صورة
  Future<void> _openGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      _processAndSaveImage(File(image.path));
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
            // عرض الكاميرا الحية في الخلفية
            Positioned.fill(
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : Container(
                color: primaryColor.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: darkColor)),
              ),
            ),

            // الشريط العلوي (تصميم العودة والفلاش)
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'العودة',
                      style: TextStyle(color: darkColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: darkColor, shape: BoxShape.circle),
                      child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // أزرار التحكم السفلية (المعرض والتصوير)
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _openGallery,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: darkColor, width: 2),
                      ),
                      child: const Icon(Icons.photo_library_outlined, color: darkColor, size: 32),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_isCameraInitialized) {
                        try {
                          final image = await _cameraController!.takePicture();
                          _processAndSaveImage(File(image.path));
                        } catch (e) {
                          debugPrint("خطأ عند التصوير: $e");
                        }
                      }
                    },
                    child: Container(
                      height: 85, width: 85,
                      decoration: BoxDecoration(
                        color: darkColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة التعليمات المنبثقة (Pop-up)
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
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
                const Text(
                  "تعليمات الصورة",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.error, color: Colors.red, size: 70),
                const SizedBox(height: 20),
                const Text(
                  "قبل ما ترفع الصورة.. تأكد إنها منورة وواضحة، وحجمها أقل من 10 ميجابايت. وتذكر أننا نستقبل صور فقط.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E8449),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("فهمت", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}