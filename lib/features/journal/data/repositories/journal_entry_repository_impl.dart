import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kairos/core/errors/failures.dart';
import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_local_datasource.dart';
import 'package:kairos/features/journal/data/datasources/journal_entry_remote_datasource.dart';
import 'package:kairos/features/journal/data/models/journal_entry_model.dart';
import 'package:kairos/features/journal/domain/entities/journal_entry_entity.dart';
import 'package:kairos/features/journal/domain/repositories/journal_entry_repository.dart';

class JournalEntryRepositoryImpl implements JournalEntryRepository {
  JournalEntryRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  final JournalEntryLocalDataSource localDataSource;
  final JournalEntryRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<JournalEntryEntity>> createEntry(
      JournalEntryEntity entry) async {
    try {
      final model = JournalEntryModel.fromEntity(entry);
      await localDataSource.saveEntry(model);

      if (await _isOnline && entry.entryType == JournalEntryType.text) {
        try {
          await remoteDataSource.saveEntry(model);
          final synced =
              model.copyWith(uploadStatus: UploadStatus.completed.index);
          await localDataSource.updateEntry(synced);
        } catch (e) {
          debugPrint('Failed to sync entry to remote: $e');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create entry: $e'));
    }
  }

  @override
  Future<Result<JournalEntryEntity?>> getEntryById(String entryId) async {
    try {
      if (await _isOnline) {
        try {
          final remoteEntry = await remoteDataSource.getEntryById(entryId);
          if (remoteEntry != null) {
            await localDataSource.saveEntry(remoteEntry);
            return Success(remoteEntry.toEntity());
          }
        } catch (e) {
          debugPrint('Failed to fetch from remote: $e');
        }
      }

      final localEntry = await localDataSource.getEntryById(entryId);
      return Success(localEntry?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get entry: $e'));
    }
  }

  @override
  Stream<List<JournalEntryEntity>> watchEntriesByUserId(String userId) {
    return localDataSource
        .watchEntriesByUserId(userId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<void>> syncPendingUploads(String userId) async {
    try {
      if (!await _isOnline) {
        return const Error(NetworkFailure(message: 'Device is offline'));
      }

      final pendingEntries = await localDataSource.getPendingUploads(userId);

      for (final entry in pendingEntries) {
        try {
          await remoteDataSource.saveEntry(entry);
          final synced =
              entry.copyWith(uploadStatus: UploadStatus.completed.index);
          await localDataSource.updateEntry(synced);
        } catch (e) {
          debugPrint('Failed to sync entry ${entry.id}: $e');
        }
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync: $e'));
    }
  }
}
