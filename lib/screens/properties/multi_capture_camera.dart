import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';

/// Full-screen, in-app camera with multi-capture, native lens switching
/// (0.6x ultrawide / 1x / 2x / 3x — whichever the device exposes), digital
/// zoom and flash. Photos accumulate; the user taps Done to review and
/// confirm before the queue is returned.
class MultiCaptureCamera extends StatefulWidget {
  const MultiCaptureCamera({super.key});

  static Future<List<File>> open(BuildContext context) async {
    final result = await Navigator.of(context).push<List<File>>(
      MaterialPageRoute(builder: (_) => const MultiCaptureCamera()),
    );
    return result ?? [];
  }

  @override
  State<MultiCaptureCamera> createState() => _MultiCaptureCameraState();
}

class _LensPreset {
  final CameraDescription camera;
  final double minZoom;
  final double maxZoom;
  String label;
  _LensPreset({
    required this.camera,
    required this.minZoom,
    required this.maxZoom,
  }) : label = '1x';
}

class _MultiCaptureCameraState extends State<MultiCaptureCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initializing = true;
  String? _error;
  bool _capturing = false;

  final List<File> _captured = [];
  bool _reviewing = false;

  // Digital zoom on the active controller.
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  FlashMode _flash = FlashMode.off;

  // Physical lens presets — one per back-facing camera, labelled with its
  // effective zoom (e.g. 0.6x ultrawide, 1x wide, 2x tele).
  final List<_LensPreset> _lensPresets = [];
  int _activeLens = 0;
  bool _onFront = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'No cameras found';
        });
        return;
      }

      // Build lens presets from every back-facing physical camera. We probe
      // each by briefly initialising it so we can read its real zoom range
      // — that's how we discover an ultrawide (min < 1.0) when the OS
      // reports it as a separate CameraDescription rather than as sub-1.0
      // zoom on a logical camera.
      // Strict back-facing first. Only fall back to non-front cameras if
      // none are explicitly tagged `back`.
      var back = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      if (back.isEmpty) {
        back = _cameras
            .where((c) => c.lensDirection != CameraLensDirection.front)
            .toList();
      }
      if (back.isEmpty) back = List.of(_cameras);

      // Build lens presets from name heuristics — no pre-probing. Probing
      // each camera with init/dispose can leave the camera stack in a state
      // that causes the next CameraController to attach to the wrong lens
      // (e.g. the front camera) on some devices. Min/max zoom is fetched
      // lazily per lens after we actually start it.
      _lensPresets.clear();
      for (final cam in back) {
        final n = cam.name.toLowerCase();
        double assumedMin;
        double assumedMax;
        if (n.contains('ultra')) {
          assumedMin = 0.5;
          assumedMax = 1.0;
        } else if (n.contains('tele')) {
          assumedMin = 1.0;
          assumedMax = 3.0;
        } else {
          assumedMin = 1.0;
          assumedMax = 1.0;
        }
        _lensPresets.add(_LensPreset(
          camera: cam,
          minZoom: assumedMin,
          maxZoom: assumedMax,
        ));
      }
      _assignLensLabels();

      // Always start on the first back lens labelled "1x" if present;
      // otherwise the first entry (which is guaranteed back-facing).
      final wideIdx = _lensPresets.indexWhere((p) => p.label == '1x');
      _activeLens = wideIdx >= 0 ? wideIdx : 0;
      await _startLens(_activeLens);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Camera error: $e';
      });
    }
  }

  void _assignLensLabels() {
    if (_lensPresets.isEmpty) return;
    final sorted = [..._lensPresets]
      ..sort((a, b) => a.minZoom.compareTo(b.minZoom));
    bool wideAssigned = false;
    for (final p in sorted) {
      if (p.minZoom < 0.95) {
        p.label = '${p.minZoom.toStringAsFixed(1)}x';
      } else if (!wideAssigned) {
        p.label = '1x';
        wideAssigned = true;
      } else {
        final z = p.maxZoom >= 2.0 ? p.maxZoom : 2.0;
        p.label = '${z.toInt()}x';
      }
    }
  }

  Future<void> _startLens(int index) async {
    final preset = _lensPresets[index];
    _controller?.dispose();
    final ctrl =
        CameraController(preset.camera, ResolutionPreset.high, enableAudio: false);
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted) return;
      final minZ = await ctrl.getMinZoomLevel();
      final maxZ = await ctrl.getMaxZoomLevel();
      final restZoom =
          preset.minZoom < 0.95 ? minZ : 1.0.clamp(minZ, maxZ).toDouble();

      try {
        await ctrl.setFlashMode(_flash);
      } catch (_) {}

      setState(() {
        _activeLens = index;
        _onFront = false;
        _initializing = false;
        _error = null;
        _minZoom = minZ;
        _maxZoom = maxZ;
        _currentZoom = restZoom;
      });
      await ctrl.setZoomLevel(restZoom);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Could not start camera';
      });
    }
  }

  Future<void> _setLens(int index) async {
    if (!_onFront && index == _activeLens) return;
    if (_initializing) return;
    setState(() => _initializing = true);
    await _startLens(index);
  }

  Future<void> _switchCamera() async {
    final front = _cameras
        .where((c) => c.lensDirection == CameraLensDirection.front)
        .toList();
    if (front.isEmpty) return;
    setState(() => _initializing = true);
    if (!_onFront) {
      _controller?.dispose();
      final ctrl =
          CameraController(front.first, ResolutionPreset.high, enableAudio: false);
      _controller = ctrl;
      try {
        await ctrl.initialize();
        final minZ = await ctrl.getMinZoomLevel();
        final maxZ = await ctrl.getMaxZoomLevel();
        if (!mounted) return;
        setState(() {
          _onFront = true;
          _initializing = false;
          _minZoom = minZ;
          _maxZoom = maxZ;
          _currentZoom = 1.0.clamp(minZ, maxZ).toDouble();
        });
        await ctrl.setZoomLevel(_currentZoom);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _error = 'Could not start front camera';
        });
      }
    } else {
      await _startLens(_activeLens);
    }
  }

  Future<void> _cycleFlash() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };
    try {
      await ctrl.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flash = next);
    } catch (_) {}
  }

  IconData _flashIcon() => switch (_flash) {
        FlashMode.off => Icons.flash_off_rounded,
        FlashMode.auto => Icons.flash_auto_rounded,
        FlashMode.always => Icons.flash_on_rounded,
        FlashMode.torch => Icons.highlight_rounded,
      };

  void _onScaleStart(ScaleStartDetails _) {
    _baseZoom = _currentZoom;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final newZoom =
        (_baseZoom * details.scale).clamp(_minZoom, _maxZoom).toDouble();
    if (newZoom == _currentZoom) return;
    setState(() => _currentZoom = newZoom);
    await ctrl.setZoomLevel(newZoom);
  }

  Future<void> _takePicture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final xFile = await ctrl.takePicture();
      if (!mounted) return;
      setState(() {
        _captured.add(File(xFile.path));
        _capturing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
    }
  }

  void _removeAt(int index) {
    setState(() => _captured.removeAt(index));
    if (_captured.isEmpty) {
      setState(() => _reviewing = false);
    }
  }

  void _confirm() => Navigator.of(context).pop(_captured);
  void _cancel() => Navigator.of(context).pop(<File>[]);

  @override
  Widget build(BuildContext context) {
    if (_reviewing) return _buildReview();
    return _buildCamera();
  }

  Widget _buildCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _cancel,
                  ),
                  IconButton(
                    icon: Icon(_flashIcon(), color: Colors.white),
                    onPressed: _cycleFlash,
                    tooltip: 'Flash',
                  ),
                  const Spacer(),
                  if (_captured.isNotEmpty)
                    Text(
                      '${_captured.length} taken',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  const Spacer(),
                  if (_cameras.any(
                      (c) => c.lensDirection == CameraLensDirection.front))
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white),
                      onPressed: _switchCamera,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _initializing
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white))
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.white70)))
                      : GestureDetector(
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!
                                          .value.previewSize!.height,
                                      height: _controller!
                                          .value.previewSize!.width,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_currentZoom > _minZoom + 0.05 &&
                                        _maxZoom > _minZoom + 0.05)
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${_currentZoom.toStringAsFixed(1)}x',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    if (!_onFront && _lensPresets.length > 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(28),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                            _lensPresets.length,
                                            (i) {
                                              final p = _lensPresets[i];
                                              final active = i == _activeLens;
                                              return GestureDetector(
                                                onTap: () => _setLens(i),
                                                child: Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4),
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: active
                                                        ? AppTheme.brand
                                                        : Colors.black38,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    p.label,
                                                    style: TextStyle(
                                                      color: active
                                                          ? Colors.white
                                                          : Colors.white70,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: _captured.isNotEmpty
                        ? GestureDetector(
                            onTap: () => setState(() => _reviewing = true),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_captured.last,
                                  fit: BoxFit.cover),
                            ),
                          )
                        : null,
                  ),
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: _capturing ? 56 : 60,
                          height: _capturing ? 56 : 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: _captured.isNotEmpty
                        ? TextButton(
                            onPressed: () =>
                                setState(() => _reviewing = true),
                            child: const Text('Done',
                                style: TextStyle(
                                    color: AppTheme.brand,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _reviewing = false),
        ),
        title: Text(
            '${_captured.length} photo${_captured.length == 1 ? '' : 's'}'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Confirm',
                style: TextStyle(
                    color: AppTheme.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _captured.length,
        itemBuilder: (_, i) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: Image.file(_captured[i], fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeAt(i),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
