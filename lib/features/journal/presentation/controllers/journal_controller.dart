import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/presentation/providers/auth_providers.dart';
import 'package:kairos/features/journal/domain/usecases/create_text_entry_usecase.dart';

sealed class JournalState {}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalSuccess extends JournalState {}

class JournalError extends JournalState {
  JournalError(this.message);
  final String message;
}

class JournalController extends StateNotifier<JournalState> {
  JournalController({
    required this.createTextEntryUseCase,
    required this.ref,
  }) : super(JournalInitial());

  final CreateTextEntryUseCase createTextEntryUseCase;
  final Ref ref;

  String? get _currentUserId {
    final authState = ref.read(authStateProvider);
    return authState.valueOrNull?.id;
  }

  Future<void> createTextEntry(String content) async {
    final userId = _currentUserId;
    if (userId == null) {
      state = JournalError('User not authenticated');
      return;
    }

    state = JournalLoading();

    try {
      final params = CreateTextEntryParams(
        userId: userId,
        textContent: content,
      );

      final result = await createTextEntryUseCase.call(params);

      result.when(
        success: (_) {
          state = JournalSuccess();
        },
        error: (failure) {
          state = JournalError(_getErrorMessage(failure));
        },
      );
    } catch (e) {
      state = JournalError('An unexpected error occurred: $e');
    }
  }

  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure() => failure.message,
      NetworkFailure() => 'Network error: ${failure.message}',
      _ => 'An error occurred: ${failure.message}',
    };
  }

  void reset() {
    state = JournalInitial();
  }
}
