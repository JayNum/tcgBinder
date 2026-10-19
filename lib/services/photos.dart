import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Asks where the photo should come from: camera or gallery.
Future<ImageSource?> askPhotoSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

/// Picks a photo and saves a resized copy at [targetPath].
/// Returns the path, or null if the user cancelled.
Future<String?> pickAndSavePhoto({
  required ImageSource source,
  required String targetPath,
  double maxWidth = 1200,
}) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth,
    imageQuality: 88,
  );
  if (picked == null) return null;
  await File(picked.path).copy(targetPath);
  return targetPath;
}

/// Which part of the photo to keep, as fractions of its width and height.
class CropRect {
  const CropRect(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

class _CropJob {
  const _CropJob(this.source, this.target, this.rect);
  final String source;
  final String target;
  final CropRect rect;
}

/// Crops a camera photo to the card frame and saves it as a JPEG.
/// Runs in a background isolate so the camera stays smooth.
Future<String> cropAndSave({
  required String sourcePath,
  required String targetPath,
  required CropRect rect,
}) {
  return compute(_cropJob, _CropJob(sourcePath, targetPath, rect));
}

Future<String> _cropJob(_CropJob job) async {
  final Uint8List bytes = await File(job.source).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    await File(job.source).copy(job.target);
    return job.target;
  }
  // Turn the pixels the way the phone was held.
  final image = img.bakeOrientation(decoded);
  final x = (job.rect.left * image.width).round().clamp(0, image.width - 1);
  final y = (job.rect.top * image.height).round().clamp(0, image.height - 1);
  final w = (job.rect.width * image.width).round().clamp(1, image.width - x);
  final h = (job.rect.height * image.height).round().clamp(1, image.height - y);
  var card = img.copyCrop(image, x: x, y: y, width: w, height: h);
  if (card.width > 900) card = img.copyResize(card, width: 900);
  await File(job.target).writeAsBytes(img.encodeJpg(card, quality: 88));
  return job.target;
}
