import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/providers/core_providers.dart';

/// Sync Coordinator
/// 
/// Manages the connectivity state and triggers a sync signal when the device comes back online.
/// This decouples the connectivity monitoring logic from the UI.
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(ref);
});

/// Stream provider that emits events when a sync should occur
final syncTriggerProvider = StreamProvider<void>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.onSyncTriggered;
});

class SyncCoordinator {

  SyncCoordinator(this._ref) {
    _initializeListener();
  }
  final Ref _ref;
  bool _wasOffline = false;
  Timer? _debounceTimer;

  // Stream controller to emit sync triggers
  final _onSyncTriggeredController = StreamController<void>.broadcast();
  
  /// Stream that emits when a sync should be performed (e.g. after reconnecting)
  Stream<void> get onSyncTriggered => _onSyncTriggeredController.stream;

  void _initializeListener() {
    _ref.listen<AsyncValue<bool>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((isOnline) {
          // Detect transition from offline to online
          if (_wasOffline && isOnline) {
            logger.i('🌐 Device reconnected (Coordinator) - scheduling sync trigger');
            
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 2), () {
               logger.i('🔄 Triggering auto-sync via Coordinator');
              _onSyncTriggeredController.add(null);
            });
          }
          _wasOffline = !isOnline;
        });
      },
      onError: (err, stack) => logger.e('Connectivity stream error', error: err, stackTrace: stack),
    );
  }
  
  void dispose() {
    _debounceTimer?.cancel();
    _onSyncTriggeredController.close();
  }
}
