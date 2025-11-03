// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJournalEntryModelCollection on Isar {
  IsarCollection<JournalEntryModel> get journalEntryModels => this.collection();
}

const JournalEntryModelSchema = CollectionSchema(
  name: r'JournalEntryModel',
  id: 3211955384174486103,
  properties: {
    r'aiProcessingStatus': PropertySchema(
      id: 0,
      name: r'aiProcessingStatus',
      type: IsarType.long,
    ),
    r'audioDurationSeconds': PropertySchema(
      id: 1,
      name: r'audioDurationSeconds',
      type: IsarType.long,
    ),
    r'createdAtMillis': PropertySchema(
      id: 2,
      name: r'createdAtMillis',
      type: IsarType.long,
    ),
    r'entryType': PropertySchema(
      id: 3,
      name: r'entryType',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 5,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'lastUploadAttemptMillis': PropertySchema(
      id: 6,
      name: r'lastUploadAttemptMillis',
      type: IsarType.long,
    ),
    r'localFilePath': PropertySchema(
      id: 7,
      name: r'localFilePath',
      type: IsarType.string,
    ),
    r'localThumbnailPath': PropertySchema(
      id: 8,
      name: r'localThumbnailPath',
      type: IsarType.string,
    ),
    r'modifiedAtMillis': PropertySchema(
      id: 9,
      name: r'modifiedAtMillis',
      type: IsarType.long,
    ),
    r'needsSync': PropertySchema(
      id: 10,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'storageUrl': PropertySchema(
      id: 11,
      name: r'storageUrl',
      type: IsarType.string,
    ),
    r'textContent': PropertySchema(
      id: 12,
      name: r'textContent',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 13,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'transcription': PropertySchema(
      id: 14,
      name: r'transcription',
      type: IsarType.string,
    ),
    r'uploadRetryCount': PropertySchema(
      id: 15,
      name: r'uploadRetryCount',
      type: IsarType.long,
    ),
    r'uploadStatus': PropertySchema(
      id: 16,
      name: r'uploadStatus',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 17,
      name: r'userId',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 18,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _journalEntryModelEstimateSize,
  serialize: _journalEntryModelSerialize,
  deserialize: _journalEntryModelDeserialize,
  deserializeProp: _journalEntryModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _journalEntryModelGetId,
  getLinks: _journalEntryModelGetLinks,
  attach: _journalEntryModelAttach,
  version: '3.1.0+1',
);

int _journalEntryModelEstimateSize(
  JournalEntryModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.localFilePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localThumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.storageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.textContent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.transcription;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _journalEntryModelSerialize(
  JournalEntryModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.aiProcessingStatus);
  writer.writeLong(offsets[1], object.audioDurationSeconds);
  writer.writeLong(offsets[2], object.createdAtMillis);
  writer.writeLong(offsets[3], object.entryType);
  writer.writeString(offsets[4], object.id);
  writer.writeBool(offsets[5], object.isDeleted);
  writer.writeLong(offsets[6], object.lastUploadAttemptMillis);
  writer.writeString(offsets[7], object.localFilePath);
  writer.writeString(offsets[8], object.localThumbnailPath);
  writer.writeLong(offsets[9], object.modifiedAtMillis);
  writer.writeBool(offsets[10], object.needsSync);
  writer.writeString(offsets[11], object.storageUrl);
  writer.writeString(offsets[12], object.textContent);
  writer.writeString(offsets[13], object.thumbnailUrl);
  writer.writeString(offsets[14], object.transcription);
  writer.writeLong(offsets[15], object.uploadRetryCount);
  writer.writeLong(offsets[16], object.uploadStatus);
  writer.writeString(offsets[17], object.userId);
  writer.writeLong(offsets[18], object.version);
}

JournalEntryModel _journalEntryModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JournalEntryModel(
    aiProcessingStatus: reader.readLongOrNull(offsets[0]) ?? 0,
    audioDurationSeconds: reader.readLongOrNull(offsets[1]),
    createdAtMillis: reader.readLong(offsets[2]),
    entryType: reader.readLong(offsets[3]),
    id: reader.readString(offsets[4]),
    isDeleted: reader.readBoolOrNull(offsets[5]) ?? false,
    lastUploadAttemptMillis: reader.readLongOrNull(offsets[6]),
    localFilePath: reader.readStringOrNull(offsets[7]),
    localThumbnailPath: reader.readStringOrNull(offsets[8]),
    modifiedAtMillis: reader.readLong(offsets[9]),
    needsSync: reader.readBoolOrNull(offsets[10]) ?? false,
    storageUrl: reader.readStringOrNull(offsets[11]),
    textContent: reader.readStringOrNull(offsets[12]),
    thumbnailUrl: reader.readStringOrNull(offsets[13]),
    transcription: reader.readStringOrNull(offsets[14]),
    uploadRetryCount: reader.readLongOrNull(offsets[15]) ?? 0,
    uploadStatus: reader.readLongOrNull(offsets[16]) ?? 0,
    userId: reader.readString(offsets[17]),
    version: reader.readLongOrNull(offsets[18]) ?? 1,
  );
  return object;
}

P _journalEntryModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 16:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _journalEntryModelGetId(JournalEntryModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _journalEntryModelGetLinks(
    JournalEntryModel object) {
  return [];
}

void _journalEntryModelAttach(
    IsarCollection<dynamic> col, Id id, JournalEntryModel object) {}

extension JournalEntryModelByIndex on IsarCollection<JournalEntryModel> {
  Future<JournalEntryModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  JournalEntryModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<JournalEntryModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<JournalEntryModel?> getAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'id', values);
  }

  Future<int> deleteAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'id', values);
  }

  int deleteAllByIdSync(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'id', values);
  }

  Future<Id> putById(JournalEntryModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(JournalEntryModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<JournalEntryModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<JournalEntryModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension JournalEntryModelQueryWhereSort
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QWhere> {
  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JournalEntryModelQueryWhere
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QWhereClause> {
  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      idNotEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [id],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'id',
              lower: [],
              upper: [id],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension JournalEntryModelQueryFilter
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QFilterCondition> {
  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      aiProcessingStatusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiProcessingStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      aiProcessingStatusGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiProcessingStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      aiProcessingStatusLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiProcessingStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      aiProcessingStatusBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiProcessingStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      audioDurationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioDurationSeconds',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      audioDurationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioDurationSeconds',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      audioDurationSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      audioDurationSecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      audioDurationSecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      audioDurationSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioDurationSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      createdAtMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      createdAtMillisGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      createdAtMillisLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      createdAtMillisBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAtMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      entryTypeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryType',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      entryTypeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entryType',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      entryTypeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entryType',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      entryTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entryType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      lastUploadAttemptMillisIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUploadAttemptMillis',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      lastUploadAttemptMillisIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUploadAttemptMillis',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      lastUploadAttemptMillisEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUploadAttemptMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      lastUploadAttemptMillisGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUploadAttemptMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      lastUploadAttemptMillisLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUploadAttemptMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      lastUploadAttemptMillisBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUploadAttemptMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localFilePath',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localFilePath',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localFilePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localFilePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localThumbnailPath',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localThumbnailPath',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localThumbnailPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localThumbnailPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localThumbnailPath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      localThumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localThumbnailPath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      modifiedAtMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'modifiedAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      modifiedAtMillisGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'modifiedAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      modifiedAtMillisLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'modifiedAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      modifiedAtMillisBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'modifiedAtMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'needsSync',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'storageUrl',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'storageUrl',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'storageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'storageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      storageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'storageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'textContent',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'textContent',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textContent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textContent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textContent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textContent',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      textContentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textContent',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transcription',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transcription',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transcription',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transcription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transcription',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      transcriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transcription',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadRetryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadRetryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadRetryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadRetryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadRetryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadRetryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadRetryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadRetryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadStatusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadStatusGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uploadStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadStatusLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uploadStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      uploadStatusBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uploadStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      versionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      versionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterFilterCondition>
      versionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension JournalEntryModelQueryObject
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QFilterCondition> {}

extension JournalEntryModelQueryLinks
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QFilterCondition> {}

extension JournalEntryModelQuerySortBy
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QSortBy> {
  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByAiProcessingStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByAiProcessingStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByAudioDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByAudioDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByEntryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByLastUploadAttemptMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByLastUploadAttemptMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByLocalFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByLocalFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByLocalThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByLocalThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByModifiedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedAtMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByModifiedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedAtMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByStorageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByStorageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByTextContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textContent', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByTextContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textContent', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByTranscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByTranscriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByUploadRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByUploadRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByUploadStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension JournalEntryModelQuerySortThenBy
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QSortThenBy> {
  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByAiProcessingStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByAiProcessingStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByAudioDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByAudioDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByEntryTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryType', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByLastUploadAttemptMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByLastUploadAttemptMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByLocalFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByLocalFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByLocalThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByLocalThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByModifiedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedAtMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByModifiedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedAtMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByStorageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByStorageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByTextContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textContent', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByTextContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textContent', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByTranscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByTranscriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByUploadRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByUploadRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByUploadStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension JournalEntryModelQueryWhereDistinct
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct> {
  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByAiProcessingStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiProcessingStatus');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByAudioDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioDurationSeconds');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMillis');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByEntryType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryType');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByLastUploadAttemptMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUploadAttemptMillis');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByLocalFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localFilePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByLocalThumbnailPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localThumbnailPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByModifiedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modifiedAtMillis');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByStorageUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByTextContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textContent', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByThumbnailUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByTranscription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transcription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByUploadRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadRetryCount');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadStatus');
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalEntryModel, JournalEntryModel, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension JournalEntryModelQueryProperty
    on QueryBuilder<JournalEntryModel, JournalEntryModel, QQueryProperty> {
  QueryBuilder<JournalEntryModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations>
      aiProcessingStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiProcessingStatus');
    });
  }

  QueryBuilder<JournalEntryModel, int?, QQueryOperations>
      audioDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioDurationSeconds');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations>
      createdAtMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMillis');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations> entryTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryType');
    });
  }

  QueryBuilder<JournalEntryModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JournalEntryModel, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<JournalEntryModel, int?, QQueryOperations>
      lastUploadAttemptMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUploadAttemptMillis');
    });
  }

  QueryBuilder<JournalEntryModel, String?, QQueryOperations>
      localFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localFilePath');
    });
  }

  QueryBuilder<JournalEntryModel, String?, QQueryOperations>
      localThumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localThumbnailPath');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations>
      modifiedAtMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modifiedAtMillis');
    });
  }

  QueryBuilder<JournalEntryModel, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<JournalEntryModel, String?, QQueryOperations>
      storageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storageUrl');
    });
  }

  QueryBuilder<JournalEntryModel, String?, QQueryOperations>
      textContentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textContent');
    });
  }

  QueryBuilder<JournalEntryModel, String?, QQueryOperations>
      thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<JournalEntryModel, String?, QQueryOperations>
      transcriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transcription');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations>
      uploadRetryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadRetryCount');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations>
      uploadStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadStatus');
    });
  }

  QueryBuilder<JournalEntryModel, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<JournalEntryModel, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
