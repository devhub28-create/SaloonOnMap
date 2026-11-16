import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_client/api_client.dart';
import '../cubit/ai_style_state.dart';

class LookDetailSheet extends StatefulWidget {
  final String originalImageUrl;
  final AiVariation variation;
  final Future<void> Function(String title, String? notes)? onSave;

  const LookDetailSheet({
    super.key,
    required this.originalImageUrl,
    required this.variation,
    this.onSave,
  });

  static void show(
    BuildContext context, {
    required String originalImageUrl,
    required AiVariation variation,
    Future<void> Function(String title, String? notes)? onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LookDetailSheet(
        originalImageUrl: originalImageUrl,
        variation: variation,
        onSave: onSave,
      ),
    );
  }

  @override
  State<LookDetailSheet> createState() => _LookDetailSheetState();
}

class _LookDetailSheetState extends State<LookDetailSheet> {
  double _splitPosition = 0.5;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.variation.styleLabel;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _copyBarberCard() {
    final v = widget.variation;
    final buffer = StringBuffer()
      ..writeln('✂️ SLOT BARBER CONSULTATION CARD')
      ..writeln('Style: ${v.styleLabel} (Face Suitability: ${v.suitabilityScore}%)')
      ..writeln('• Top & Sides Length: ${v.hairLengthCm ?? v.hairDesc ?? "Balanced taper"}')
      ..writeln('• Facial Hair / Beard: ${v.beardLengthMm ?? v.beardDesc ?? "Natural trim"}')
      ..writeln('• Maintenance Level: ${(v.maintenanceLevel ?? "Medium").toUpperCase()}')
      ..writeln('• Styling Product: ${v.stylingProducts ?? "Matte styling clay"}');
    if (v.barberInstructions.isNotEmpty) {
      buffer.writeln('\nBarber Instructions:');
      for (final step in v.barberInstructions) {
        buffer.writeln('  - $step');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barber instructions copied! Ready to share with your stylist.'),
        backgroundColor: Color(0xFF1F3D3A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origUrl = ApiConfig.formatImageUrl(widget.originalImageUrl);
    final styledUrl = ApiConfig.formatImageUrl(widget.variation.imageUrl);
    final v = widget.variation;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (v.isRecommended)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD49B28),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TOP SUGGESTION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A5F).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Face Suitability ${v.suitabilityScore}%',
                              style: const TextStyle(
                                color: Color(0xFF1E3A5F),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.styleLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1A15),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interactive Before & After Split Comparison
                  SizedBox(
                    height: 330,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            styledUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                          ClipRect(
                            clipper: _SplitClipper(_splitPosition),
                            child: Image.network(
                              origUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (ctx, constraints) {
                                final lineX = constraints.maxWidth * _splitPosition;
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: lineX - 1.5,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(width: 3, color: Colors.white),
                                    ),
                                    Positioned(
                                      left: lineX - 16,
                                      top: constraints.maxHeight / 2 - 16,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD49B28),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black26, blurRadius: 4),
                                          ],
                                        ),
                                        child: const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) {
                                final RenderBox box = context.findRenderObject() as RenderBox;
                                final newSplit =
                                    (_splitPosition + details.delta.dx / box.size.width).clamp(0.0, 1.0);
                                setState(() {
                                  _splitPosition = newSplit;
                                });
                              },
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ORIGINAL',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD49B28).withOpacity(0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PERSONALIZED PREVIEW',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Slider control
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFD49B28),
                      inactiveTrackColor: Colors.black12,
                      thumbColor: const Color(0xFFD49B28),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _splitPosition,
                      onChanged: (val) => setState(() => _splitPosition = val),
                    ),
                  ),

                  // Honest Angle Availability Notice
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF1E3A5F)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.sideViewAvailable || v.backViewAvailable
                                ? 'Generated from your uploaded multi-angle photos.'
                                : 'Genuine front portrait transformation on your photo (no stock side/back templates used).',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E3A5F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Why It Suits You
                  if (v.whyItSuits != null && v.whyItSuits!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6C677)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.psychology_outlined, size: 18, color: Color(0xFFB37D14)),
                              SizedBox(width: 6),
                              Text(
                                'Why This Style Suits Your Face',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E1A15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            v.whyItSuits!,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A4238), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Barber Consultation Card (Screen E)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5DEC9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.content_cut, size: 18, color: Color(0xFF1E3A5F)),
                                SizedBox(width: 8),
                                Text(
                                  'Barber Specification Card',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E1A15),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _copyBarberCard,
                              icon: const Icon(Icons.copy_rounded, size: 15),
                              label: const Text('Copy Specs', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildSpecRow('Hair Length & Cut', v.hairLengthCm ?? v.hairDesc ?? 'Custom taper'),
                        const SizedBox(height: 8),
                        _buildSpecRow('Facial Hair / Beard', v.beardLengthMm ?? v.beardDesc ?? 'Groomed trim'),
                        if (v.lookDesc != null && v.lookDesc!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSpecRow('Styling Details', v.lookDesc!),
                        ],
                        const SizedBox(height: 8),
                        _buildSpecRow('Maintenance Level', (v.maintenanceLevel ?? 'Medium').toUpperCase()),
                        if (v.stylingProducts != null && v.stylingProducts!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSpecRow('Recommended Product', v.stylingProducts!),
                        ],
                        if (v.barberInstructions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'What to Tell Your Barber:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...v.barberInstructions.map(
                            (inst) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      inst,
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A352F), height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF1E3A5F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_outlined, color: Color(0xFF1E3A5F), size: 18),
                    label: const Text(
                      'Copy Barber Card',
                      style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
                    ),
                    onPressed: _copyBarberCard,
                  ),
                ),
                if (widget.onSave != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD49B28),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bookmark_add, color: Colors.white, size: 18),
                      label: const Text(
                        'Save Look',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : () => _showSaveDialog(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 135,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A7265), fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E1A15), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Personalized Look'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Look Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Personal Notes for Barber (Optional)',
                hintText: 'e.g., Keep sideburns slightly softer',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD49B28)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isSaving = true);
              await widget.onSave?.call(
                _titleController.text.trim(),
                _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              );
              if (mounted) {
                setState(() => _isSaving = false);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double splitRatio;
  _SplitClipper(this.splitRatio);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * splitRatio, size.height);
  }

  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) {
    return oldClipper.splitRatio != splitRatio;
  }
}
