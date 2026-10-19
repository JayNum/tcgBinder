import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../catalog/catalog_scope.dart';
import '../catalog/games.dart';
import '../data/collection_store.dart';
import '../data/settings_store.dart';
import '../models/catalog.dart';
import '../scanner/card_matcher.dart';
import '../scanner/code_reader.dart';
import '../services/add_card.dart';
import '../services/photos.dart';
import '../theme/app_theme.dart';
import '../widgets/pocket.dart';
import 'game_screen.dart';

/// Point the camera at a card, tap the shutter: the app reads the card
/// number, finds the card and files the photo into the right binder.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _camera;
  String? _cameraError;
  bool _busy = false;
  String _gameId = games.first.id;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// The card frame, as fractions of the preview (also used for cropping).
  static const _frameWidth = 0.74;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final last = SettingsScope.of(context).lastScanGame;
    if (last != null && games.any((g) => g.id == last)) _gameId = last;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    _recognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive) {
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && camera == null) {
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      try {
        await controller.setFocusMode(FocusMode.auto);
        await controller.setFlashMode(FlashMode.off);
      } on CameraException catch (_) {
        // Not every camera supports these; fine.
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      setState(() {
        _cameraError = e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt'
            ? 'Camera access is off. Allow it for TCG Binder in your phone '
                'settings to scan cards.'
            : 'The camera could not start (${e.description ?? e.code}).';
      });
    }
  }

  /// The frame rectangle within a preview of [size].
  static Rect frameRect(Size size) {
    var w = size.width * _frameWidth;
    var h = w * 88 / 63;
    if (h > size.height * 0.86) {
      h = size.height * 0.86;
      w = h * 63 / 88;
    }
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _busy || !camera.value.isInitialized) return;
    setState(() => _busy = true);
    final store = CollectionScope.of(context);
    final catalog = CatalogScope.of(context);
    final gameId = _gameId;
    try {
      final shot = await camera.takePicture();

      // Read the text on the card.
      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(shot.path));
      final hints = readCardHints(gameId, recognized.text);

      // Crop the photo to the frame (a little extra so no edge is lost).
      // The upright preview is 1 wide and aspectRatio tall.
      final previewHeight = camera.value.aspectRatio;
      final frame = frameRect(Size(1, previewHeight));
      const margin = 0.015;
      final photoPath = await cropAndSave(
        sourcePath: shot.path,
        targetPath: store.newPhotoPath(),
        rect: CropRect(
          (frame.left - margin).clamp(0.0, 1.0).toDouble(),
          (frame.top / previewHeight - margin).clamp(0.0, 1.0).toDouble(),
          (frame.width + 2 * margin).clamp(0.0, 1.0).toDouble(),
          (frame.height / previewHeight + 2 * margin).clamp(0.0, 1.0).toDouble(),
        ),
      );
      _deleteQuietly(shot.path);

      List<CatalogCard> matches;
      String? lookupError;
      try {
        matches = await CardMatcher(
          catalog,
          startedSets: store.startedSets(gameId: gameId),
        ).find(gameId, hints, recognized.text);
      } on Object catch (e) {
        matches = const [];
        lookupError = '$e';
      }
      if (!mounted) return;

      final result = await showModalBottomSheet<Object>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _ResultSheet(
          photoPath: photoPath,
          matches: matches,
          readCodes: hints.map(_hintLabel).toList(),
          lookupError: lookupError,
        ),
      );
      if (!mounted) return;
      if (result is! CatalogCard) {
        _deleteQuietly(photoPath);
        if (result == _ResultSheet.findManually) {
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => GameScreen(game: gameById(gameId)),
          ));
        }
        return;
      }
      final chosen = result;
      addCardToCollection(context, chosen, photoPath: photoPath);
      final set = catalog.setById(chosen.setId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Added ${chosen.name} to ${set?.name ?? 'your binder'}',
        ),
      ));
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _hintLabel(CardHint hint) => switch (hint) {
        CodeHint h => h.code,
        NumberHint h => h.total == null ? h.number : '${h.number}/${h.total}',
        SetNumberHint h => '${h.setCode} ${h.number}',
      };

  void _deleteQuietly(String path) {
    try {
      File(path).deleteSync();
    } on Object catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan cards'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (final game in games)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(game.name),
                        selected: game.id == _gameId,
                        onSelected: (_) {
                          setState(() => _gameId = game.id);
                          SettingsScope.of(context).lastScanGame = game.id;
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _cameraError != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _cameraError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : camera == null || !camera.value.isInitialized
                        ? const CircularProgressIndicator()
                        : AspectRatio(
                            // The preview is landscape-oriented; show it
                            // upright without cropping, so the frame maps
                            // exactly onto the photo.
                            aspectRatio: 1 / camera.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(camera),
                                const IgnorePointer(
                                  child: CustomPaint(painter: _FramePainter()),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Text(
                'Fit the card in the frame. Keep the number at the bottom '
                'sharp and avoid glare.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              child: SizedBox(
                width: 76,
                height: 76,
                child: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Material(
                        color: Colors.white,
                        shape: const CircleBorder(
                          side: BorderSide(color: Colors.white54, width: 4),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: camera == null ? null : _capture,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                            size: 32,
                            semanticLabel: 'Scan card',
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frame = _ScanScreenState.frameRect(size);
    final rrect = RRect.fromRectAndRadius(frame, const Radius.circular(14));
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = Colors.black.withValues(alpha: 0.45));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// After a scan: the photo, the matching card(s), and Add / Retake.
class _ResultSheet extends StatefulWidget {
  const _ResultSheet({
    required this.photoPath,
    required this.matches,
    required this.readCodes,
    this.lookupError,
  });

  final String photoPath;
  final List<CatalogCard> matches;
  final List<String> readCodes;
  final String? lookupError;

  /// Returned when the user wants to look the card up in the binders.
  static const findManually = 'find-manually';

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  CatalogCard? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.matches.isNotEmpty) _selected = widget.matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    final catalog = CatalogScope.of(context);
    final store = CollectionScope.of(context);
    final matches = widget.matches;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 84,
                    child: AspectRatio(
                      aspectRatio: 63 / 88,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(widget.photoPath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matches.isEmpty
                              ? 'Card not found'
                              : matches.length == 1
                                  ? 'Found it'
                                  : 'Which version is it?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          matches.isEmpty
                              ? (widget.readCodes.isEmpty
                                  ? 'No card number could be read. Try again '
                                      'closer, with less glare.'
                                  : 'Read ${widget.readCodes.join(', ')}, '
                                      'but no card with that number was found'
                                      '${widget.lookupError == null ? '' : ' (${widget.lookupError})'}.')
                              : 'Read ${widget.readCodes.join(', ')}',
                          style: TextStyle(color: tokens.muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (matches.isNotEmpty)
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final card in matches)
                        _MatchTile(
                          card: card,
                          set: catalog.setById(card.setId),
                          owned: store.entryFor(card.id)?.quantity ?? 0,
                          selected: _selected?.id == card.id,
                          onTap: () => setState(() => _selected = card),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: matches.isEmpty
                        ? FilledButton(
                            onPressed: () => Navigator.pop(
                              context,
                              _ResultSheet.findManually,
                            ),
                            child: const Text('Find it myself'),
                          )
                        : FilledButton(
                            onPressed: _selected == null
                                ? null
                                : () => Navigator.pop(context, _selected),
                            child: const Text('Add to binder'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.card,
    required this.set,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final CatalogCard card;
  final CardSet? set;
  final int owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.binder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? tokens.accentSoft : tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? context.accent : tokens.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? context.accent : tokens.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.code,
                              style: numberStyle(color: tokens.text, size: 13),
                            ),
                          ),
                          if (card.variant != null) ...[
                            const SizedBox(width: 6),
                            VariantTag(label: card.variant!, large: true),
                          ],
                        ],
                      ),
                      Text(
                        card.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          if (set != null) set!.name,
                          if (card.rarity.isNotEmpty) card.rarity,
                          if (owned > 0) 'you have $owned',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: tokens.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
