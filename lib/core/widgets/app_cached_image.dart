import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/api_endpoints.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  /// Normalizes image URLs to ensure direct static access.
  /// Converts legacy PHP streaming URLs (e.g. api.php?resource=uploads&file=...)
  /// into direct static URLs (e.g. uploads/...) served by LiteSpeed.
  static String normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    String trimmed = url.trim();

    // Replace PHP query resource URL with direct static uploads URL
    if (trimmed.contains('api.php?resource=uploads&file=')) {
      trimmed = trimmed.replaceAll('api.php?resource=uploads&file=', 'uploads/');
    } else if (trimmed.contains('resource=uploads&file=')) {
      trimmed = trimmed.replaceAll(RegExp(r'api\.php\?resource=uploads&file='), 'uploads/');
    }

    // Prepend base URL if relative uploads path
    if (trimmed.startsWith('uploads/')) {
      trimmed = '${ApiEndpoints.baseUrl}$trimmed';
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = normalizeImageUrl(imageUrl);
    if (cleanUrl.isEmpty) {
      return _buildFallback();
    }

    final isTest = !kIsWeb && (Platform.environment.containsKey('FLUTTER_TEST') || bool.hasEnvironment('FLUTTER_TEST'));
    if (isTest) {
      Widget testWidget = errorWidget ?? _buildFallback();
      if (borderRadius != null) {
        testWidget = ClipRRect(borderRadius: borderRadius!, child: testWidget);
      }
      return testWidget;
    }

    Widget imageWidget;

    if (kIsWeb) {
      // On Web, native Image.network is immune to CORS/XHR CanvasKit decoding failures
      imageWidget = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          final raw = imageUrl.trim();
          if (raw.isNotEmpty && raw != cleanUrl) {
            return Image.network(
              raw,
              width: width,
              height: height,
              fit: fit,
              loadingBuilder: (ctx, ch, prog) => prog == null ? ch : (placeholder ?? _buildPlaceholder()),
              errorBuilder: (ctx, err, st) => errorWidget ?? _buildFallback(),
            );
          }
          return errorWidget ?? _buildFallback();
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) {
          final raw = imageUrl.trim();
          if (raw.isNotEmpty && raw != cleanUrl) {
            return CachedNetworkImage(
              imageUrl: raw,
              width: width,
              height: height,
              fit: fit,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (ctx, u) => placeholder ?? _buildPlaceholder(),
              errorWidget: (ctx, u, err) => errorWidget ?? _buildFallback(),
            );
          }
          return errorWidget ?? _buildFallback();
        },
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    final isTest = !kIsWeb && (Platform.environment.containsKey('FLUTTER_TEST') || bool.hasEnvironment('FLUTTER_TEST'));
    if (isTest) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
      );
    }
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCBD5E1)),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.palette_outlined,
              color: Color(0xFF94A3B8),
              size: 30,
            ),
            SizedBox(height: 4),
            Text(
              'Artist Dubai',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
