import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ReceiptService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickReceipt(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile == null) {
        return null;
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String receiptsDirPath = path.join(appDir.path, 'receipts');
      final Directory receiptsDir = Directory(receiptsDirPath);

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(pickedFile.path);
      final String newFileName = 'receipt_$timestamp$extension';
      final String newPath = path.join(receiptsDirPath, newFileName);

      await File(pickedFile.path).copy(newPath);

      return newPath;
    } catch (e) {
      // Handle errors or rethrow
      print('Error picking receipt: $e');
      return null;
    }
  }
}
