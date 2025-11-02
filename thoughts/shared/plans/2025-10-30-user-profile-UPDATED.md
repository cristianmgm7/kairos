# User Profile Creation Flow - UPDATED APPROACH

## Overview

This document reflects the **revised implementation plan** after discovering Datum-Isar incompatibility. We've pivoted to a classic repository pattern with dual data sources (local + remote) while retaining sync fields for future incremental sync implementation.

**Last Updated**: October 30, 2025 (Implementation Complete)
**Status**: All Phases Complete ✅

---

## ⚠️ Key Changes from Original Plan

### ❌ **REMOVED: Datum Integration**

**Reason**: Fundamental incompatibility between:
- **Datum**: Requires entities to extend `DatumEntity` (which extends `Equatable`)
- **Isar**: Code generator cannot process classes with Equatable's `props` getter

**What was removed**:
- ❌ `datum: ^0.0.9` package dependency
- ❌ `DatumEntity`, `LocalAdapter`, `RemoteAdapter` abstractions
- ❌ `datum_provider.dart` and related infrastructure
- ❌ `PendingOperationModel` and `SyncMetadataModel` collections

### ✅ **NEW APPROACH: Classic Repository with Dual Data Sources**

**Architecture**:
```
┌─────────────────────────────────────────────────────────┐
│         Presentation Layer (UI + Controllers)            │
│  - Profile Creation Screen                              │
│  - Profile Controller (Riverpod StateNotifier)          │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│    Domain Layer (Use Cases + Repository Interface)      │
│  - CreateUserProfileUseCase                             │
│  - UserProfileRepository (interface)                     │
└───────────────────────────┬─────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│         Data Layer (Repository Implementation)           │
│  - UserProfileRepositoryImpl                            │
│  - Offline-first logic                                   │
│  - Connectivity checking                                 │
│  - Error handling with Result<T>                        │
└──────────────┬──────────────────────────┬───────────────┘
               ↓                          ↓
┌──────────────────────────┐  ┌──────────────────────────┐
│  Local Data Source        │  │  Remote Data Source      │
│  (Isar)                   │  │  (Firestore)             │
│  - Offline storage        │  │  - Cloud sync            │
│  - Immediate writes       │  │  - Source of truth       │
│  - Reactive streams       │  │  - Cross-device sync     │
└──────────────────────────┘  └──────────────────────────┘
```

**Key Implementation Details**:
1. **Repository Pattern**: Single repository coordinates two data sources
2. **Connectivity-Aware**: Checks network before attempting remote operations
3. **Error Propagation**: Uses `Result<T>` type throughout the stack
4. **Sync Fields Retained**: Keeps `version`, `isDeleted`, `modifiedAtMillis`, `createdAtMillis` for future manual sync
5. **Offline-First**: Always writes to Isar first, then syncs to Firestore in background
6. **Graceful Degradation**: Falls back to local data if remote operations fail

---

## Implementation Phases

### Phase 1: ✅ Foundation Setup (COMPLETED)

**Status**: ✅ **DONE** - All foundation work complete

#### Changes Completed:
- [x] Removed `datum: ^0.0.9` from [pubspec.yaml](pubspec.yaml)
- [x] Kept Isar, Firebase, image handling dependencies
- [x] Created Isar provider ([database_provider.dart](lib/core/providers/database_provider.dart))
- [x] Generated Isar schemas with build_runner
- [x] Removed Datum initialization from [main.dart](lib/main.dart)
- [x] Added `firestoreProvider` to [core_providers.dart](lib/core/providers/core_providers.dart)
- [x] Deleted Datum-related files (adapters, datum_provider, sync models)

#### Verification:
- [x] `flutter pub get` succeeds
- [x] `flutter analyze` shows **0 errors, 0 warnings**
- [x] App compiles without errors
- [x] Isar initializes successfully

---

### Phase 2: ✅ Data Layer Architecture (COMPLETED)

**Status**: ✅ **DONE** - All data sources and repository implemented

#### 2.1 ✅ Local Data Source (COMPLETED)
**File**: [user_profile_local_datasource.dart](lib/features/profile/data/datasources/user_profile_local_datasource.dart)

**Implemented Features**:
- [x] Abstract interface: `UserProfileLocalDataSource`
- [x] Concrete implementation: `UserProfileLocalDataSourceImpl`
- [x] CRUD operations (create, read, update, soft delete)
- [x] Query by userId and profileId
- [x] Reactive streams (`watchProfileByUserId`)
- [x] Version incrementing on updates
- [x] Soft delete with `isDeleted` flag

**Key Methods**:
- `saveProfile()` - Write to Isar
- `getProfileByUserId()` - Query by userId with isDeleted filter
- `updateProfile()` - Increment version, update modifiedAt
- `deleteProfile()` - Soft delete (set isDeleted=true)
- `watchProfileByUserId()` - Reactive stream for UI

#### 2.2 ✅ Remote Data Source (COMPLETED)
**File**: [user_profile_remote_datasource.dart](lib/features/profile/data/datasources/user_profile_remote_datasource.dart)

**Implemented Features**:
- [x] Abstract interface: `UserProfileRemoteDataSource`
- [x] Concrete implementation: `UserProfileRemoteDataSourceImpl`
- [x] Firestore collection: `userProfiles`
- [x] CRUD operations to Firestore
- [x] Query by userId with filters
- [x] Incremental sync support (`getProfilesModifiedAfter`)
- [x] Soft delete propagation to cloud

**Key Methods**:
- `saveProfile()` - Save to Firestore
- `getProfileByUserId()` - Query Firestore by userId
- `updateProfile()` - Update Firestore document
- `deleteProfile()` - Soft delete in Firestore
- `getProfilesModifiedAfter()` - For incremental sync

#### 2.3 ✅ Repository Implementation (COMPLETED)
**File**: [user_profile_repository_impl.dart](lib/features/profile/data/repositories/user_profile_repository_impl.dart)

**Implemented Features**:
- [x] Offline-first approach (write local first, sync remote)
- [x] Connectivity checking before remote operations
- [x] Graceful degradation (falls back to local on remote errors)
- [x] Error handling with `Result<T>` type
- [x] Last-write-wins conflict resolution
- [x] Background sync method
- [x] Reactive profile streams

**Key Behaviors**:
```dart
// CREATE: Local first, then remote
createProfile() →
  1. Save to Isar (always succeeds)
  2. If online: try sync to Firestore (don't fail if this fails)

// READ: Remote first with local fallback
getProfileByUserId() →
  1. If online: try fetch from Firestore → cache to Isar
  2. If offline or remote fails: return from Isar

// UPDATE: Local first, then remote
updateProfile() →
  1. Update in Isar (increment version)
  2. If online: sync to Firestore

// WATCH: Always from local (reactive)
watchProfileByUserId() → Stream from Isar
```

#### 2.4 ✅ Providers Setup (COMPLETED)
**File**: [user_profile_providers.dart](lib/features/profile/presentation/providers/user_profile_providers.dart)

**Implemented Providers**:
- [x] `connectivityProvider` - Connectivity instance
- [x] `userProfileLocalDataSourceProvider` - Isar data source
- [x] `userProfileRemoteDataSourceProvider` - Firestore data source
- [x] `userProfileRepositoryProvider` - Repository with DI
- [x] `currentUserProfileProvider` - Stream of current user's profile
- [x] `hasCompletedProfileProvider` - Boolean check for profile existence

---

### Phase 3: ✅ Domain Layer - Use Cases (COMPLETED)

**Status**: ✅ **DONE** - All use cases implemented

#### 3.1 Create User Profile Use Case
**File**: [lib/features/profile/domain/usecases/create_user_profile_usecase.dart](lib/features/profile/domain/usecases/create_user_profile_usecase.dart)

**Requirements**:
- [x] Create `CreateUserProfileUseCase` class
- [x] Accept `CreateUserProfileParams` (userId, name, dateOfBirth, etc.)
- [x] Validate required fields (name must not be empty)
- [x] Generate UUID for profile ID
- [x] Call repository.createProfile()
- [x] Return `Result<UserProfileEntity>`

#### 3.2 Get User Profile Use Case
**File**: [lib/features/profile/domain/usecases/get_user_profile_usecase.dart](lib/features/profile/domain/usecases/get_user_profile_usecase.dart)

**Requirements**:
- [x] Create `GetUserProfileUseCase` class
- [x] Accept userId parameter
- [x] Call repository.getProfileByUserId()
- [x] Return `Result<UserProfileEntity?>`

---

### Phase 4: ✅ Firebase Storage Service (COMPLETED)

**Status**: ✅ **DONE** - All storage services implemented

#### 4.1 Image Upload Service
**File**: [lib/core/services/firebase_storage_service.dart](lib/core/services/firebase_storage_service.dart)

**Requirements**:
- [x] Create `FirebaseStorageService` class
- [x] Implement `uploadProfileAvatar(File image, String userId)` method
- [x] Resize image before upload (e.g., 512x512)
- [x] Generate unique filename (userId + timestamp)
- [x] Upload to `profile_avatars/{userId}/avatar.jpg`
- [x] Return download URL
- [x] Handle upload errors with Result type

#### 4.2 Image Picker Service
**File**: [lib/core/services/image_picker_service.dart](lib/core/services/image_picker_service.dart)

**Requirements**:
- [x] Wrap `image_picker` package
- [x] `pickImageFromGallery()` method
- [x] `pickImageFromCamera()` method (optional)
- [x] Return `Result<File>`
- [x] Handle permission errors

---

### Phase 5: ✅ Presentation Layer - Profile UI (COMPLETED)

**Status**: ✅ **DONE** - All UI screens and controllers implemented

#### 5.1 Profile Creation Screen
**File**: [lib/features/profile/presentation/screens/create_profile_screen.dart](lib/features/profile/presentation/screens/create_profile_screen.dart)

**Requirements**:
- [x] Form with fields: name, dateOfBirth, country, gender, avatar
- [x] Name field (required, TextFormField)
- [x] Date of birth picker (optional)
- [x] Country dropdown or text field (optional)
- [x] Gender selection (optional)
- [x] Avatar picker (image from gallery or Google photo)
- [x] Submit button with loading state
- [x] Form validation
- [x] Error display

#### 5.2 Profile Controller
**File**: [lib/features/profile/presentation/controllers/profile_controller.dart](lib/features/profile/presentation/controllers/profile_controller.dart)

**Requirements**:
- [x] Create `ProfileController` as `StateNotifier<ProfileState>`
- [x] `ProfileState` with loading, success, error states
- [x] `createProfile()` method
- [x] `pickAvatar()` method
- [x] `uploadAvatar()` method
- [x] Coordinate use cases (create profile, upload image)
- [x] Handle errors and update state

**State Structure**:
```dart
sealed class ProfileState {}
class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileSuccess extends ProfileState {}
class ProfileError extends ProfileState {
  final String message;
}
```

---

### Phase 6: ✅ Router Integration (COMPLETED)

**Status**: ✅ **DONE** - Router updated with profile completion checks

#### 6.1 Update Router for Profile Check
**File**: [lib/core/routing/router_provider.dart](lib/core/routing/router_provider.dart)

**Requirements**:
- [x] Add redirect logic after authentication
- [x] Check `hasCompletedProfileProvider`
- [x] If authenticated but no profile → redirect to `/create-profile`
- [x] If authenticated with profile → allow access to `/dashboard`
- [x] Add `/create-profile` route

---

## Retained Sync Fields for Future Incremental Sync

The following fields are kept in `UserProfileModel` and `UserProfileEntity` for future manual incremental sync implementation:

| Field | Type | Purpose |
|-------|------|---------|
| **`version`** | `int` | Optimistic locking version number |
| **`isDeleted`** | `bool` | Soft delete flag for sync |
| **`createdAtMillis`** | `int` | Creation timestamp (milliseconds) |
| **`modifiedAtMillis`** | `int` | Last modification timestamp |

These fields enable:
- ✅ **Conflict detection**: Compare versions between local and remote
- ✅ **Incremental sync**: Fetch only profiles modified after last sync
- ✅ **Soft deletes**: Propagate deletions across devices
- ✅ **Conflict resolution**: Last-write-wins or custom strategies

**Future Sync Implementation**:
```dart
// Example: Incremental sync from remote
Future<void> syncFromRemote() async {
  final lastSyncTime = await getLastSyncTime();
  final modifiedProfiles = await remoteDataSource
      .getProfilesModifiedAfter(userId, lastSyncTime);

  for (final profile in modifiedProfiles) {
    await localDataSource.updateProfile(profile);
  }

  await saveLastSyncTime(DateTime.now());
}
```

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
| **Dependencies** | `datum: ^0.0.9` | ❌ **REMOVED** |

---

## Current Progress

### ✅ Completed (All Phases 1-6)
- Foundation setup (dependencies, Isar, providers)
- Data layer (local data source, remote data source, repository)
- Provider wiring
- Domain layer (use cases for create/get profile)
- Services (Firebase Storage for avatar uploads, Image Picker)
- Presentation layer (Profile UI screens and controllers)
- Router integration (profile completion checks and redirects)
- All analysis passing (0 errors, 0 warnings)

---

## Next Steps

**Implementation Complete** ✅

All planned features have been implemented:

1. ✅ **Domain Layer**: Use cases with validation and repository integration
2. ✅ **Services**: Firebase Storage service for avatar uploads and Image Picker service
3. ✅ **Presentation Layer**: Complete profile creation screen with form validation, avatar picker, and state management
4. ✅ **Router Integration**: Profile completion checks with automatic redirects

**Ready for Testing**

The user profile creation flow is now ready for end-to-end testing. New users will be automatically redirected to create their profile after authentication, and existing users with profiles will proceed directly to the dashboard.

---

## Testing Strategy

### Unit Tests
- [ ] Test `UserProfileLocalDataSource` CRUD operations
- [ ] Test `UserProfileRemoteDataSource` Firestore operations
- [ ] Test `UserProfileRepositoryImpl` offline/online scenarios
- [ ] Test `CreateUserProfileUseCase` validation logic

### Integration Tests
- [ ] Test profile creation flow end-to-end
- [ ] Test offline profile creation → sync when online
- [ ] Test avatar upload flow
- [ ] Test router redirects based on profile completion

### Manual Testing
- [ ] Create profile as new user
- [ ] Verify profile saves locally (Isar Inspector)
- [ ] Verify profile syncs to Firestore
- [ ] Test offline mode (airplane mode)
- [ ] Test avatar upload from gallery
- [ ] Test Google photo pre-population

---

**Last Updated**: October 30, 2025
**Next Phase**: Phase 3 - Domain Layer Use Cases
