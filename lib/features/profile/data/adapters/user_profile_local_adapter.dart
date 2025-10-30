import 'dart:convert';

import 'package:blueprint_app/core/data/models/pending_operation_model.dart';
import 'package:blueprint_app/core/data/models/sync_metadata_model.dart';
import 'package:blueprint_app/features/profile/data/models/user_profile_model.dart';
import 'package:datum/datum.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

class UserProfileLocalAdapter extends LocalAdapter<UserProfileModel> {
  final Isar isar;

  UserProfileLocalAdapter(this.isar);

  @override
  Future<void> initialize() async {
    // Isar already initialized in main.dart
    // No additional setup needed
  }

  @override
  UserProfileModel get sampleInstance => UserProfileModel.create(
        userId: '',
        name: '',
      );

  @override
  Future<UserProfileModel?> create(UserProfileModel entity) async {
    await isar.writeTxn(() async {
      await isar.userProfileModels.put(entity);
    });
    return entity;
  }

  @override
  Future<UserProfileModel?> read(String id) async {
    return await isar.userProfileModels
        .where()
        .idEqualTo(id)
        .findFirst();
  }

  @override
  Future<List<UserProfileModel>> readAll({String? userId}) async {
    var query = isar.userProfileModels.where();

    if (userId != null) {
      query = query.filter().userIdEqualTo(userId).and().isDeletedEqualTo(false);
    } else {
      query = query.filter().isDeletedEqualTo(false);
    }

    return await query.findAll();
  }

  @override
  Future<UserProfileModel?> update(UserProfileModel entity) async {
    final updated = entity.copyWith(
      modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      version: entity.version + 1,
    );

    await isar.writeTxn(() async {
      await isar.userProfileModels.put(updated);
    });

    return updated;
  }

  @override
  Future<void> delete(String id) async {
    // Soft delete
    final profile = await read(id);
    if (profile != null) {
      final deleted = profile.copyWith(
        isDeleted: true,
        modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      );
      await isar.writeTxn(() async {
        await isar.userProfileModels.put(deleted);
      });
    }
  }

  @override
  Future<void> addPendingOperation(
    String userId,
    DatumSyncOperation<UserProfileModel> operation,
  ) async {
    final pendingOp = PendingOperationModel(
      id: const Uuid().v4(),
      userId: userId,
      entityType: 'UserProfile',
      operationType: operation.type.name,
      entityId: operation.entity.id,
      dataJson: jsonEncode(operation.entity.toDatumMap()),
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
    );

    await isar.writeTxn(() async {
      await isar.pendingOperationModels.put(pendingOp);
    });
  }

  @override
  Future<List<DatumSyncOperation<UserProfileModel>>> getPendingOperations(
    String userId,
  ) async {
    final ops = await isar.pendingOperationModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .entityTypeEqualTo('UserProfile')
        .and()
        .isProcessedEqualTo(false)
        .findAll();

    return ops.map((op) {
      final data = jsonDecode(op.dataJson) as Map<String, dynamic>;
      return DatumSyncOperation<UserProfileModel>(
        type: DatumOperationType.values.byName(op.operationType),
        entity: UserProfileModel.fromMap(data),
        timestamp: op.timestamp,
      );
    }).toList();
  }

  @override
  Future<void> clearPendingOperations(String userId) async {
    final ops = await isar.pendingOperationModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .entityTypeEqualTo('UserProfile')
        .findAll();

    await isar.writeTxn(() async {
      for (final op in ops) {
        if (op.isarId != null) {
          await isar.pendingOperationModels.delete(op.isarId!);
        }
      }
    });
  }

  @override
  Stream<DatumChangeDetail<UserProfileModel>>? changeStream() {
    return isar.userProfileModels.watchLazy().map((_) {
      return DatumChangeDetail<UserProfileModel>(
        entityType: UserProfileModel,
        timestamp: DateTime.now(),
      );
    });
  }

  @override
  Future<void> updateSyncMetadata(
    String userId,
    DatumSyncMetadata metadata,
  ) async {
    final syncMeta = SyncMetadataModel(
      userId: userId,
      lastSyncTimeMillis: metadata.lastSyncTime.millisecondsSinceEpoch,
      dataHash: metadata.dataHash,
      itemCount: metadata.itemCount,
      version: metadata.version,
    );

    await isar.writeTxn(() async {
      await isar.syncMetadataModels.put(syncMeta);
    });
  }

  @override
  Future<DatumSyncMetadata?> getSyncMetadata(String userId) async {
    final meta = await isar.syncMetadataModels
        .filter()
        .userIdEqualTo(userId)
        .findFirst();

    if (meta == null) return null;

    return DatumSyncMetadata(
      lastSyncTime: meta.lastSyncTime,
      dataHash: meta.dataHash,
      itemCount: meta.itemCount,
      version: meta.version,
    );
  }

  @override
  Stream<UserProfileModel?> watchById(String id) {
    return isar.userProfileModels
        .where()
        .idEqualTo(id)
        .watch(fireImmediately: true)
        .map((profiles) => profiles.isNotEmpty ? profiles.first : null);
  }

  @override
  Stream<List<UserProfileModel>> watchAll({String? userId}) {
    if (userId != null) {
      return isar.userProfileModels
          .filter()
          .userIdEqualTo(userId)
          .and()
          .isDeletedEqualTo(false)
          .watch(fireImmediately: true);
    }
    return isar.userProfileModels
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }
}

