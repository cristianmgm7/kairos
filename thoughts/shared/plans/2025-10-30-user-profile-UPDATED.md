# User Profile Creation Flow - UPDATED APPROACH

## Key Changes from Original Plan

### ❌ **REMOVED: Datum Integration**
**Reason**: Incompatibility between Datum (requires `DatumEntity` extending `Equatable`) and Isar (code generator cannot handle Equatable's `props` getter).

**Impact**:
- No Datum package dependency
- No DatumEntity, LocalAdapter, or RemoteAdapter abstractions
- Manual sync implementation using classic repository pattern

### ✅ **NEW APPROACH: Classic Repository with Dual Data Sources**

**Architecture**:
```
Presentation Layer (UI + Controllers)
         ↓
   Domain Layer (Use Cases + Repository Interface)
         ↓
   Data Layer (Repository Implementation)
         ↓
    ┌────────┴────────┐
    ↓                 ↓
Local Data Source   Remote Data Source
(Isar)              (Firestore)
```

**Key Implementation Details**:
1. **Repository Pattern**: Single repository with two data sources
2. **Connectivity-Aware**: Repository checks connectivity before remote operations
3. **Error Propagation**: Use `Result<T>` type for all data operations
4. **Sync Fields Retained**: Keep `version`, `isDeleted`, `modifiedAt`, `lastSyncTime` for future incremental sync
5. **Offline-First**: Always write to Isar first, then sync to Firestore in background

---

## Updated Implementation Phases

### Phase 1: ✅ Foundation Setup (COMPLETED)
- [x] Installed Isar, image handling, caching dependencies
- [x] Created Isar provider and initialized database
- [x] Created connectivity checker utility
- [x] Generated Isar schemas with build_runner

**Status**: Foundation is ready. Datum removed from dependencies (will do cleanup).

---

### Phase 2: Data Layer Architecture (CURRENT)

#### 2.1 Local Data Source
**File**: `lib/features/profile/data/datasources/user_profile_local_datasource.dart` (NEW)

```dart
/// Local data source using Isar for offline storage
abstract class UserProfileLocalDataSource {
  /// Save profile to local database
  Future<void> saveProfile(UserProfileModel profile);

  /// Get profile by user ID
  Future<UserProfileModel?> getProfileByUserId(String userId);

  /// Get profile by profile ID
  Future<UserProfileModel?> getProfileById(String profileId);

  /// Update existing profile
  Future<void> updateProfile(UserProfileModel profile);

  /// Delete profile (soft delete)
  Future<void> deleteProfile(String profileId);

  /// Watch profile changes for reactive UI
  Stream<UserProfileModel?> watchProfileByUserId(String userId);

  /// Get all profiles (for debugging/admin)
  Future<List<UserProfileModel>> getAllProfiles();
}

class UserProfileLocalDataSourceImpl implements UserProfileLocalDataSource {
  final Isar isar;

  UserProfileLocalDataSourceImpl(this.isar);

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await isar.writeTxn(() async {
      await isar.userProfileModels.put(profile);
    });
  }

  @override
  Future<UserProfileModel?> getProfileByUserId(String userId) async {
    return await isar.userProfileModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .findFirst();
  }

  @override
  Future<UserProfileModel?> getProfileById(String profileId) async {
    return await isar.userProfileModels
        .where()
        .idEqualTo(profileId)
        .findFirst();
  }

  @override
  Future<void> updateProfile(UserProfileModel profile) async {
    final updated = profile.copyWith(
      modifiedAtMillis: DateTime.now().millisecondsSinceEpoch,
      version: profile.version + 1,
    );

    await isar.writeTxn(() async {
      await isar.userProfileModels.put(updated);
    });
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    final profile = await getProfileById(profileId);
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
  Stream<UserProfileModel?> watchProfileByUserId(String userId) {
    return isar.userProfileModels
        .filter()
        .userIdEqualTo(userId)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((profiles) => profiles.isNotEmpty ? profiles.first : null);
  }

  @override
  Future<List<UserProfileModel>> getAllProfiles() async {
    return await isar.userProfileModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }
}
```

#### 2.2 Remote Data Source
**File**: `lib/features/profile/data/datasources/user_profile_remote_datasource.dart` (NEW)

```dart
/// Remote data source using Firestore
abstract class UserProfileRemoteDataSource {
  /// Save profile to Firestore
  Future<void> saveProfile(UserProfileModel profile);

  /// Get profile by user ID from Firestore
  Future<UserProfileModel?> getProfileByUserId(String userId);

  /// Get profile by profile ID from Firestore
  Future<UserProfileModel?> getProfileById(String profileId);

  /// Update profile in Firestore
  Future<void> updateProfile(UserProfileModel profile);

  /// Delete profile from Firestore (soft delete)
  Future<void> deleteProfile(String profileId);

  /// Get profiles modified after a timestamp (for incremental sync)
  Future<List<UserProfileModel>> getProfilesModifiedAfter(
    String userId,
    DateTime timestamp,
  );
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  UserProfileRemoteDataSourceImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('userProfiles');

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await _collection.doc(profile.id).set(profile.toFirestoreMap());
  }

  @override
  Future<UserProfileModel?> getProfileByUserId(String userId) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return UserProfileModel.fromMap(querySnapshot.docs.first.data());
  }

  @override
  Future<UserProfileModel?> getProfileById(String profileId) async {
    final doc = await _collection.doc(profileId).get();
    if (!doc.exists) return null;

    return UserProfileModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateProfile(UserProfileModel profile) async {
    await _collection.doc(profile.id).update(profile.toFirestoreMap());
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await _collection.doc(profileId).update({
      'isDeleted': true,
      'modifiedAtMillis': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<UserProfileModel>> getProfilesModifiedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    final querySnapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('modifiedAtMillis', isGreaterThan: timestamp.millisecondsSinceEpoch)
        .get();

    return querySnapshot.docs
        .map((doc) => UserProfileModel.fromMap(doc.data()))
        .toList();
  }
}
```

#### 2.3 Repository Implementation
**File**: `lib/features/profile/data/repositories/user_profile_repository_impl.dart` (REWRITE)

```dart
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileLocalDataSource localDataSource;
  final UserProfileRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  UserProfileRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  /// Check if device is online
  Future<bool> get _isOnline async {
    final results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Future<Result<UserProfileEntity>> createProfile(
    UserProfileEntity profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);

      // 1. Save locally first (offline-first approach)
      await localDataSource.saveProfile(model);

      // 2. Try to sync to remote if online
      if (await _isOnline) {
        try {
          await remoteDataSource.saveProfile(model);
        } catch (remoteError) {
          // Log error but don't fail - profile is saved locally
          debugPrint('Failed to sync profile to remote: $remoteError');
          // Could add to sync queue here for retry later
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to create profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity?>> getProfileByUserId(String userId) async {
    try {
      // 1. Try to fetch from remote if online
      if (await _isOnline) {
        try {
          final remoteProfile = await remoteDataSource.getProfileByUserId(userId);
          if (remoteProfile != null) {
            // Save to local cache
            await localDataSource.saveProfile(remoteProfile);
            return Success(remoteProfile.toEntity());
          }
        } catch (remoteError) {
          debugPrint('Failed to fetch from remote, falling back to local: $remoteError');
        }
      }

      // 2. Fallback to local
      final localProfile = await localDataSource.getProfileByUserId(userId);
      return Success(localProfile?.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to get profile: $e'));
    }
  }

  @override
  Future<Result<UserProfileEntity>> updateProfile(
    UserProfileEntity profile,
  ) async {
    try {
      final model = UserProfileModel.fromEntity(profile);

      // 1. Update locally
      await localDataSource.updateProfile(model);

      // 2. Sync to remote if online
      if (await _isOnline) {
        try {
          await remoteDataSource.updateProfile(model);
        } catch (remoteError) {
          debugPrint('Failed to sync update to remote: $remoteError');
        }
      }

      return Success(model.toEntity());
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to update profile: $e'));
    }
  }

  @override
  Stream<UserProfileEntity?> watchProfileByUserId(String userId) {
    return localDataSource
        .watchProfileByUserId(userId)
        .map((model) => model?.toEntity());
  }

  @override
  Future<Result<void>> syncProfile(String userId) async {
    try {
      if (!await _isOnline) {
        return const Error(
          UnknownFailure(message: 'Cannot sync: device is offline'),
        );
      }

      final localProfile = await localDataSource.getProfileByUserId(userId);
      if (localProfile == null) {
        return const Success(null);
      }

      // Fetch remote version
      final remoteProfile = await remoteDataSource.getProfileByUserId(userId);

      if (remoteProfile == null) {
        // No remote version, push local to remote
        await remoteDataSource.saveProfile(localProfile);
      } else {
        // Both exist - use simple last-write-wins strategy
        if (localProfile.modifiedAtMillis > remoteProfile.modifiedAtMillis) {
          // Local is newer, push to remote
          await remoteDataSource.updateProfile(localProfile);
        } else if (remoteProfile.modifiedAtMillis > localProfile.modifiedAtMillis) {
          // Remote is newer, pull to local
          await localDataSource.updateProfile(remoteProfile);
        }
        // If equal, they're in sync - do nothing
      }

      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure(message: 'Failed to sync profile: $e'));
    }
  }
}
```

---

### Phase 3: Domain Layer (Use Cases)

**File**: `lib/features/profile/domain/usecases/create_user_profile_usecase.dart`

```dart
class CreateUserProfileUseCase {
  final UserProfileRepository repository;

  CreateUserProfileUseCase(this.repository);

  Future<Result<UserProfileEntity>> call(CreateUserProfileParams params) async {
    // Validate inputs
    if (params.name.trim().isEmpty) {
      return const Error(
        ValidationFailure(message: 'Name cannot be empty'),
      );
    }

    final profile = UserProfileEntity(
      id: const Uuid().v4(),
      userId: params.userId,
      name: params.name,
      dateOfBirth: params.dateOfBirth,
      country: params.country,
      gender: params.gender,
      avatarUrl: params.avatarUrl,
      mainGoal: params.mainGoal,
      experienceLevel: params.experienceLevel,
      interests: params.interests,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await repository.createProfile(profile);
  }
}

class CreateUserProfileParams {
  final String userId;
  final String name;
  final DateTime? dateOfBirth;
  final String? country;
  final String? gender;
  final String? avatarUrl;
  final String? mainGoal;
  final String? experienceLevel;
  final List<String>? interests;

  CreateUserProfileParams({
    required this.userId,
    required this.name,
    this.dateOfBirth,
    this.country,
    this.gender,
    this.avatarUrl,
    this.mainGoal,
    this.experienceLevel,
    this.interests,
  });
}
```

---

### Phase 4: Presentation Layer

Controllers, UI screens, and form validation (to be implemented next).

---

## Retained Sync Fields for Future Incremental Sync

The following fields are kept in `UserProfileModel` and `UserProfileEntity` for future manual incremental sync implementation:

1. **`version`** (int): Optimistic locking version number
2. **`isDeleted`** (bool): Soft delete flag for sync
3. **`createdAtMillis`** / **`createdAt`**: Creation timestamp
4. **`modifiedAtMillis`** / **`modifiedAt`**: Last modification timestamp

These fields enable:
- **Conflict detection**: Compare versions between local and remote
- **Incremental sync**: Fetch only profiles modified after last sync
- **Soft deletes**: Propagate deletions across devices
- **Conflict resolution**: Last-write-wins or custom strategies

---

## Summary of Changes

| **Component** | **Original Plan** | **Updated Approach** |
|---------------|-------------------|----------------------|
| **Sync Framework** | Datum | None (manual implementation) |
| **Data Sources** | LocalAdapter + RemoteAdapter | LocalDataSource + RemoteDataSource |
| **Repository** | Thin wrapper over DatumManager | Full repository with sync logic |
| **Entity** | Extends DatumEntity | Plain class with sync fields |
| **Model** | Extends DatumEntity | Isar @collection model |
| **Conflict Resolution** | Datum's built-in | Last-write-wins (manual) |
| **Dependencies** | datum: ^0.0.9 | ❌ REMOVED |

---

## Next Steps

1. Remove Datum dependencies from pubspec.yaml
2. Delete Datum-related files (adapters, datum_provider)
3. Implement LocalDataSource
4. Implement RemoteDataSource
5. Rewrite Repository
6. Continue with Use Cases and UI as planned
