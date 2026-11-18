import 'package:flutter/material.dart';

class AiConsentDialog extends StatelessWidget {
  const AiConsentDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const AiConsentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFFBF8F3),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD49B28).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFFD49B28),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Photo Privacy & Consent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1A15),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SLOT AI Style Studio uses a FREE open-weight neural inpainting model running locally on the private system.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A443B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildPoint(
              Icons.lock_outline,
              'Zero Third-Party APIs',
              'Your photo is never sent to paid hosted model APIs (no OpenAI, no Replicate, no cloud subscription).',
            ),
            const SizedBox(height: 12),
            _buildPoint(
              Icons.face,
              'Facial Identity Preservation',
              'Only the hair and beard regions are edited. Your eyes, nose, and facial structure remain unmasked.',
            ),
            const SizedBox(height: 12),
            _buildPoint(
              Icons.delete_outline,
              'Complete Control & Deletion',
              'You can permanently delete any saved looks and associated photos at any time from your profile.',
            ),
            const SizedBox(height: 16),
            const Text(
              'By checking consent, you authorize SLOT to generate hairstyle and beard previews for your personal styling.',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A7265)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF7A7265)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD49B28),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I Agree & Consent'),
        ),
      ],
    );
  }

  Widget _buildPoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD49B28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1A15),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5245)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
