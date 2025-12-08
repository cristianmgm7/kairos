import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/widgets/error_body.dart';
import 'package:kairos/core/widgets/loading_body.dart';
import 'package:kairos/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:kairos/features/streak/presentation/widgets/streak_preview_card.dart';

class StreakSection extends ConsumerWidget {
  const StreakSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const LoadingBody(
        height: 172,
        loadingMessage: 'Loading profile...',
      ),
      error: (_, __) => const ErrorBody(
        height: 172,
        description: 'Error loading profile',
      ),
      data: (profile) => const StreakPreviewCard(),
    );
  }
}
