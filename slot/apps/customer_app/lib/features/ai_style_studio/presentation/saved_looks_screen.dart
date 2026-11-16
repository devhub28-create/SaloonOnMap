import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import '../cubit/ai_style_cubit.dart';
import '../cubit/ai_style_state.dart';
import 'look_detail_sheet.dart';

class SavedLooksScreen extends StatefulWidget {
  const SavedLooksScreen({super.key});

  @override
  State<SavedLooksScreen> createState() => _SavedLooksScreenState();
}

class _SavedLooksScreenState extends State<SavedLooksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AiStyleCubit>().loadSavedLooks();
  }

  Future<void> _shareLook(BuildContext context, AiSavedLookItem look) async {
    final shareRes = await context.read<AiStyleCubit>().shareSavedLook(look.id);
    final summary = StringBuffer()
      ..writeln('✂️ SLOT SAVED BARBER LOOK: ${look.title}')
      ..writeln('• Hair Length: ${look.hairLengthCm ?? look.hairStyle ?? "Custom taper"}')
      ..writeln('• Beard Style: ${look.beardLengthMm ?? look.beardStyle ?? "Natural trim"}')
      ..writeln('• Maintenance: ${(look.maintenanceLevel ?? "Medium").toUpperCase()}')
      ..writeln('• Notes: ${look.notes ?? "Show portrait preview to barber"}');
    if (shareRes != null && shareRes['shareToken'] != null) {
      summary.writeln('• Share Reference ID: ${shareRes['shareToken']}');
    }
    await Clipboard.setData(ClipboardData(text: summary.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barber consultation card copied to clipboard!'),
        backgroundColor: Color(0xFF1F3D3A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      appBar: AppBar(
        title: const Text(
          'My Saved AI Looks',
          style: TextStyle(color: Color(0xFF1E1A15), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFBF8F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1A15)),
      ),
      body: BlocBuilder<AiStyleCubit, AiStyleState>(
        builder: (context, state) {
          if (state is AiSavedLooksLoadingState) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD49B28)),
            );
          }

          if (state is AiStyleErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(state.error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD49B28)),
                      onPressed: () => context.read<AiStyleCubit>().loadSavedLooks(),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AiEmptySavedLooksState ||
              state is! AiSavedLooksLoadedState ||
              state.looks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD49B28).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.style_outlined, size: 56, color: Color(0xFFD49B28)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Saved Looks Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1A15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate personalized hairstyle & beard suggestions in the AI Style Studio and bookmark your favorites here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF7A7265)),
                    ),
                  ],
                ),
              ),
            );
          }

          final looks = state.looks;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.70,
            ),
            itemCount: looks.length,
            itemBuilder: (context, idx) {
              final look = looks[idx];
              final imgUrl = ApiConfig.formatImageUrl(look.styledImageUrl);

              return GestureDetector(
                onTap: () {
                  LookDetailSheet.show(
                    context,
                    originalImageUrl: look.originalImageUrl,
                    variation: AiVariation(
                      id: look.id,
                      archetypeId: look.archetypeId,
                      optionNumber: look.optionNumber ?? 1,
                      imageUrl: look.styledImageUrl,
                      styleLabel: look.title,
                      hairStyle: look.hairStyle,
                      beardStyle: look.beardStyle,
                      hairLengthCm: look.hairLengthCm,
                      beardLengthMm: look.beardLengthMm,
                      whyItSuits: look.whyItSuits,
                      suitabilityScore: look.suitabilityScore ?? 92,
                      maintenanceLevel: look.maintenanceLevel,
                      stylingProducts: look.stylingProducts,
                      barberInstructions: look.barberInstructions,
                      lookDesc: look.notes,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              child: Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            if (look.suitabilityScore != null)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A5F).withOpacity(0.88),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Match ${look.suitabilityScore}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _shareLook(context, look),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.share_outlined, color: Colors.white, size: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(context, look.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              look.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1A15),
                              ),
                            ),
                            if (look.hairLengthCm != null && look.hairLengthCm!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                look.hairLengthCm!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF4A4238)),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${look.createdAt.day}/${look.createdAt.month}/${look.createdAt.year}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7A7265)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String lookId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Look?'),
        content: const Text('Are you sure you want to delete this saved AI style?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AiStyleCubit>().deleteSavedLook(lookId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
