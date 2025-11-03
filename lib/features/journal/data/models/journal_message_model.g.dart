// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_message_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetJournalMessageModelCollection on Isar {
  IsarCollection<JournalMessageModel> get journalMessageModels =>
      this.collection();
}

const JournalMessageModelSchema = CollectionSchema(
  name: r'JournalMessageModel',
  id: -564372045415598399,
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
    r'content': PropertySchema(
      id: 2,
      name: r'content',
      type: IsarType.string,
    ),
    r'createdAtMillis': PropertySchema(
      id: 3,
      name: r'createdAtMillis',
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
    r'messageType': PropertySchema(
      id: 9,
      name: r'messageType',
      type: IsarType.long,
    ),
    r'role': PropertySchema(
      id: 10,
      name: r'role',
      type: IsarType.long,
    ),
    r'storageUrl': PropertySchema(
      id: 11,
      name: r'storageUrl',
      type: IsarType.string,
    ),
    r'threadId': PropertySchema(
      id: 12,
      name: r'threadId',
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
  estimateSize: _journalMessageModelEstimateSize,
  serialize: _journalMessageModelSerialize,
  deserialize: _journalMessageModelDeserialize,
  deserializeProp: _journalMessageModelDeserializeProp,
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
    r'threadId': IndexSchema(
      id: -1397508362477071783,
      name: r'threadId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'threadId',
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
  getId: _journalMessageModelGetId,
  getLinks: _journalMessageModelGetLinks,
  attach: _journalMessageModelAttach,
  version: '3.1.0+1',
);

int _journalMessageModelEstimateSize(
  JournalMessageModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.content;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  bytesCount += 3 + object.threadId.length * 3;
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

void _journalMessageModelSerialize(
  JournalMessageModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.aiProcessingStatus);
  writer.writeLong(offsets[1], object.audioDurationSeconds);
  writer.writeString(offsets[2], object.content);
  writer.writeLong(offsets[3], object.createdAtMillis);
  writer.writeString(offsets[4], object.id);
  writer.writeBool(offsets[5], object.isDeleted);
  writer.writeLong(offsets[6], object.lastUploadAttemptMillis);
  writer.writeString(offsets[7], object.localFilePath);
  writer.writeString(offsets[8], object.localThumbnailPath);
  writer.writeLong(offsets[9], object.messageType);
  writer.writeLong(offsets[10], object.role);
  writer.writeString(offsets[11], object.storageUrl);
  writer.writeString(offsets[12], object.threadId);
  writer.writeString(offsets[13], object.thumbnailUrl);
  writer.writeString(offsets[14], object.transcription);
  writer.writeLong(offsets[15], object.uploadRetryCount);
  writer.writeLong(offsets[16], object.uploadStatus);
  writer.writeString(offsets[17], object.userId);
  writer.writeLong(offsets[18], object.version);
}

JournalMessageModel _journalMessageModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = JournalMessageModel(
    aiProcessingStatus: reader.readLongOrNull(offsets[0]) ?? 0,
    audioDurationSeconds: reader.readLongOrNull(offsets[1]),
    content: reader.readStringOrNull(offsets[2]),
    createdAtMillis: reader.readLong(offsets[3]),
    id: reader.readString(offsets[4]),
    isDeleted: reader.readBoolOrNull(offsets[5]) ?? false,
    lastUploadAttemptMillis: reader.readLongOrNull(offsets[6]),
    localFilePath: reader.readStringOrNull(offsets[7]),
    localThumbnailPath: reader.readStringOrNull(offsets[8]),
    messageType: reader.readLong(offsets[9]),
    role: reader.readLong(offsets[10]),
    storageUrl: reader.readStringOrNull(offsets[11]),
    threadId: reader.readString(offsets[12]),
    thumbnailUrl: reader.readStringOrNull(offsets[13]),
    transcription: reader.readStringOrNull(offsets[14]),
    uploadRetryCount: reader.readLongOrNull(offsets[15]) ?? 0,
    uploadStatus: reader.readLongOrNull(offsets[16]) ?? 0,
    userId: reader.readString(offsets[17]),
    version: reader.readLongOrNull(offsets[18]) ?? 1,
  );
  return object;
}

P _journalMessageModelDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
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
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
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

Id _journalMessageModelGetId(JournalMessageModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _journalMessageModelGetLinks(
    JournalMessageModel object) {
  return [];
}

void _journalMessageModelAttach(
    IsarCollection<dynamic> col, Id id, JournalMessageModel object) {}

extension JournalMessageModelByIndex on IsarCollection<JournalMessageModel> {
  Future<JournalMessageModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  JournalMessageModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<JournalMessageModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<JournalMessageModel?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(JournalMessageModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(JournalMessageModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<JournalMessageModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<JournalMessageModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension JournalMessageModelQueryWhereSort
    on QueryBuilder<JournalMessageModel, JournalMessageModel, QWhere> {
  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhere>
      anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension JournalMessageModelQueryWhere
    on QueryBuilder<JournalMessageModel, JournalMessageModel, QWhereClause> {
  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      isarIdEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      idEqualTo(String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      threadIdEqualTo(String threadId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'threadId',
        value: [threadId],
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      threadIdNotEqualTo(String threadId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'threadId',
              lower: [],
              upper: [threadId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'threadId',
              lower: [threadId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'threadId',
              lower: [threadId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'threadId',
              lower: [],
              upper: [threadId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterWhereClause>
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

extension JournalMessageModelQueryFilter on QueryBuilder<JournalMessageModel,
    JournalMessageModel, QFilterCondition> {
  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      aiProcessingStatusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiProcessingStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      audioDurationSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioDurationSeconds',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      audioDurationSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioDurationSeconds',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      audioDurationSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioDurationSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'content',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'content',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      createdAtMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      lastUploadAttemptMillisIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUploadAttemptMillis',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      lastUploadAttemptMillisIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUploadAttemptMillis',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      lastUploadAttemptMillisEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUploadAttemptMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localFilePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localFilePath',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localFilePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localFilePath',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localFilePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localThumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localThumbnailPath',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localThumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localThumbnailPath',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localThumbnailPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localThumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localThumbnailPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localThumbnailPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localThumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localThumbnailPath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      localThumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localThumbnailPath',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      messageTypeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageType',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      messageTypeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageType',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      messageTypeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageType',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      messageTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      roleEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      roleGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'role',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      roleLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'role',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      roleBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'role',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      storageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'storageUrl',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      storageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'storageUrl',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      storageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'storageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      storageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'storageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      storageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      storageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'storageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'threadId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'threadId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadId',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      threadIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'threadId',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailUrl',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      transcriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transcription',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      transcriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transcription',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      transcriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transcription',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      transcriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transcription',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      transcriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transcription',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      transcriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transcription',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      uploadRetryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadRetryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      uploadStatusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uploadStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterFilterCondition>
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

extension JournalMessageModelQueryObject on QueryBuilder<JournalMessageModel,
    JournalMessageModel, QFilterCondition> {}

extension JournalMessageModelQueryLinks on QueryBuilder<JournalMessageModel,
    JournalMessageModel, QFilterCondition> {}

extension JournalMessageModelQuerySortBy
    on QueryBuilder<JournalMessageModel, JournalMessageModel, QSortBy> {
  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByAiProcessingStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByAiProcessingStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByAudioDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByAudioDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByLastUploadAttemptMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByLastUploadAttemptMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByLocalFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByLocalFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByLocalThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByLocalThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByMessageTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByStorageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByStorageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByThreadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByThreadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByTranscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByTranscriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByUploadRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByUploadRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByUploadStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension JournalMessageModelQuerySortThenBy
    on QueryBuilder<JournalMessageModel, JournalMessageModel, QSortThenBy> {
  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByAiProcessingStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByAiProcessingStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aiProcessingStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByAudioDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByAudioDurationSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioDurationSeconds', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByLastUploadAttemptMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByLastUploadAttemptMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUploadAttemptMillis', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByLocalFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByLocalFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localFilePath', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByLocalThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByLocalThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localThumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByMessageTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageType', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByStorageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByStorageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storageUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByThreadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByThreadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByTranscription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByTranscriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transcription', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByUploadRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByUploadRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadRetryCount', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByUploadStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadStatus', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QAfterSortBy>
      thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension JournalMessageModelQueryWhereDistinct
    on QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct> {
  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByAiProcessingStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiProcessingStatus');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByAudioDurationSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioDurationSeconds');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByContent({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMillis');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByLastUploadAttemptMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUploadAttemptMillis');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByLocalFilePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localFilePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByLocalThumbnailPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localThumbnailPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByMessageType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageType');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByStorageUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByThreadId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threadId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByThumbnailUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByTranscription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transcription',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByUploadRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadRetryCount');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByUploadStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadStatus');
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<JournalMessageModel, JournalMessageModel, QDistinct>
      distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension JournalMessageModelQueryProperty
    on QueryBuilder<JournalMessageModel, JournalMessageModel, QQueryProperty> {
  QueryBuilder<JournalMessageModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations>
      aiProcessingStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiProcessingStatus');
    });
  }

  QueryBuilder<JournalMessageModel, int?, QQueryOperations>
      audioDurationSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioDurationSeconds');
    });
  }

  QueryBuilder<JournalMessageModel, String?, QQueryOperations>
      contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations>
      createdAtMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMillis');
    });
  }

  QueryBuilder<JournalMessageModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<JournalMessageModel, bool, QQueryOperations>
      isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<JournalMessageModel, int?, QQueryOperations>
      lastUploadAttemptMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUploadAttemptMillis');
    });
  }

  QueryBuilder<JournalMessageModel, String?, QQueryOperations>
      localFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localFilePath');
    });
  }

  QueryBuilder<JournalMessageModel, String?, QQueryOperations>
      localThumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localThumbnailPath');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations>
      messageTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageType');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<JournalMessageModel, String?, QQueryOperations>
      storageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storageUrl');
    });
  }

  QueryBuilder<JournalMessageModel, String, QQueryOperations>
      threadIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threadId');
    });
  }

  QueryBuilder<JournalMessageModel, String?, QQueryOperations>
      thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<JournalMessageModel, String?, QQueryOperations>
      transcriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transcription');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations>
      uploadRetryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadRetryCount');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations>
      uploadStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadStatus');
    });
  }

  QueryBuilder<JournalMessageModel, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<JournalMessageModel, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
