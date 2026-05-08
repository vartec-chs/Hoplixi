import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class NoiseLayer extends StatefulWidget {
  final double opacity;

  const NoiseLayer({super.key, this.opacity = 0.05});

  @override
  State<NoiseLayer> createState() => _NoiseLayerState();
}

class _NoiseLayerState extends State<NoiseLayer> {
  ui.Image? _noiseImage;

  @override
  void initState() {
    super.initState();
    _generateNoise();
  }

  Future<void> _generateNoise() async {
    const int size = 128;
    final Uint8List pixels = Uint8List(size * size * 4);
    final Random random = Random();

    for (int i = 0; i < pixels.length; i += 4) {
      final int value = random.nextInt(256);
      pixels[i] = value;
      pixels[i + 1] = value;
      pixels[i + 2] = value;
      pixels[i + 3] = 255;
    }

    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      pixels,
    );
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: size,
      height: size,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    if (mounted) {
      setState(() {
        _noiseImage = frameInfo.image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_noiseImage == null) return const SizedBox.shrink();

    return Opacity(
      opacity: widget.opacity,
      child: RawImage(
        image: _noiseImage,
        repeat: ImageRepeat.repeat,
        fit: BoxFit.none,
        filterQuality: FilterQuality.low,
      ),
    );
  }
}
