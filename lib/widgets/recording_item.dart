// lib/widgets/recording_item.dart
import 'package:flutter/material.dart';
import '../models/recording_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class RecordingItem extends StatelessWidget {
  final RecordingModel recording;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback? onPlayPause;
  final Function(double)? onSeek;
  final VoidCallback? onViewTranscript;
  final VoidCallback? onDelete;

  const RecordingItem({
    Key? key,
    required this.recording,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.onPlayPause,
    this.onSeek,
    this.onViewTranscript,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Play/Pause Button
                GestureDetector(
                  onTap: onPlayPause,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Recording Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Helpers.formatDateTime(recording.timestamp),
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recording.formattedDuration,
                        style: AppStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // More Options
                PopupMenuButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textPrimary,
                  ),
                  color: AppColors.surfaceVariant,
                  itemBuilder: (context) => [
                    if (recording.transcript != null &&
                        onViewTranscript != null)
                      const PopupMenuItem(
                        value: 'transcript',
                        child: Row(
                          children: [
                            Icon(Icons.subtitles, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text(
                              'View Transcript',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'transcript' && onViewTranscript != null) {
                      onViewTranscript!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
              ],
            ),
          ),

          // Progress Bar (shown when playing)
          if (isPlaying && onSeek != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceVariant,
                      thumbColor: AppColors.primary,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      trackHeight: 2,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: currentPosition.inSeconds.toDouble(),
                      max: totalDuration.inSeconds > 0
                          ? totalDuration.inSeconds.toDouble()
                          : 1.0,
                      onChanged: (value) => onSeek!(value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: AppStyles.bodySmall,
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: AppStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
