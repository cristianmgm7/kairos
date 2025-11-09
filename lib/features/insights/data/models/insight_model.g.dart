// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInsightModelCollection on Isar {
  IsarCollection<InsightModel> get insightModels => this.collection();
}

const InsightModelSchema = CollectionSchema(
  name: r'InsightModel',
  id: -423129788428064119,
  properties: {
    r'actionPrompt': PropertySchema(
      id: 0,
      name: r'actionPrompt',
      type: IsarType.string,
    ),
    r'aiThemes': PropertySchema(
      id: 1,
      name: r'aiThemes',
      type: IsarType.stringList,
    ),
    r'createdAtMillis': PropertySchema(
      id: 2,
      name: r'createdAtMillis',
      type: IsarType.long,
    ),
    r'dominantEmotion': PropertySchema(
      id: 3,
      name: r'dominantEmotion',
      type: IsarType.long,
    ),
    r'guidanceSuggestion': PropertySchema(
      id: 4,
      name: r'guidanceSuggestion',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 5,
      name: r'id',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 6,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'keywords': PropertySchema(
      id: 7,
      name: r'keywords',
      type: IsarType.stringList,
    ),
    r'messageCount': PropertySchema(
      id: 8,
      name: r'messageCount',
      type: IsarType.long,
    ),
    r'moodScore': PropertySchema(
      id: 9,
      name: r'moodScore',
      type: IsarType.double,
    ),
    r'periodEndMillis': PropertySchema(
      id: 10,
      name: r'periodEndMillis',
      type: IsarType.long,
    ),
    r'periodStartMillis': PropertySchema(
      id: 11,
      name: r'periodStartMillis',
      type: IsarType.long,
    ),
    r'summary': PropertySchema(
      id: 12,
      name: r'summary',
      type: IsarType.string,
    ),
    r'threadId': PropertySchema(
      id: 13,
      name: r'threadId',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 14,
      name: r'type',
      type: IsarType.long,
    ),
    r'updatedAtMillis': PropertySchema(
      id: 15,
      name: r'updatedAtMillis',
      type: IsarType.long,
    ),
    r'userId': PropertySchema(
      id: 16,
      name: r'userId',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 17,
      name: r'version',
      type: IsarType.long,
    )
  },
  estimateSize: _insightModelEstimateSize,
  serialize: _insightModelSerialize,
  deserialize: _insightModelDeserialize,
  deserializeProp: _insightModelDeserializeProp,
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
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _insightModelGetId,
  getLinks: _insightModelGetLinks,
  attach: _insightModelAttach,
  version: '3.1.0+1',
);

int _insightModelEstimateSize(
  InsightModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.actionPrompt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.aiThemes.length * 3;
  {
    for (var i = 0; i < object.aiThemes.length; i++) {
      final value = object.aiThemes[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.guidanceSuggestion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.keywords.length * 3;
  {
    for (var i = 0; i < object.keywords.length; i++) {
      final value = object.keywords[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.summary.length * 3;
  {
    final value = object.threadId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _insightModelSerialize(
  InsightModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionPrompt);
  writer.writeStringList(offsets[1], object.aiThemes);
  writer.writeLong(offsets[2], object.createdAtMillis);
  writer.writeLong(offsets[3], object.dominantEmotion);
  writer.writeString(offsets[4], object.guidanceSuggestion);
  writer.writeString(offsets[5], object.id);
  writer.writeBool(offsets[6], object.isDeleted);
  writer.writeStringList(offsets[7], object.keywords);
  writer.writeLong(offsets[8], object.messageCount);
  writer.writeDouble(offsets[9], object.moodScore);
  writer.writeLong(offsets[10], object.periodEndMillis);
  writer.writeLong(offsets[11], object.periodStartMillis);
  writer.writeString(offsets[12], object.summary);
  writer.writeString(offsets[13], object.threadId);
  writer.writeLong(offsets[14], object.type);
  writer.writeLong(offsets[15], object.updatedAtMillis);
  writer.writeString(offsets[16], object.userId);
  writer.writeLong(offsets[17], object.version);
}

InsightModel _insightModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InsightModel(
    actionPrompt: reader.readStringOrNull(offsets[0]),
    aiThemes: reader.readStringList(offsets[1]) ?? [],
    createdAtMillis: reader.readLong(offsets[2]),
    dominantEmotion: reader.readLong(offsets[3]),
    guidanceSuggestion: reader.readStringOrNull(offsets[4]),
    id: reader.readString(offsets[5]),
    isDeleted: reader.readBoolOrNull(offsets[6]) ?? false,
    keywords: reader.readStringList(offsets[7]) ?? [],
    messageCount: reader.readLong(offsets[8]),
    moodScore: reader.readDouble(offsets[9]),
    periodEndMillis: reader.readLong(offsets[10]),
    periodStartMillis: reader.readLong(offsets[11]),
    summary: reader.readString(offsets[12]),
    threadId: reader.readStringOrNull(offsets[13]),
    type: reader.readLong(offsets[14]),
    updatedAtMillis: reader.readLong(offsets[15]),
    userId: reader.readString(offsets[16]),
    version: reader.readLongOrNull(offsets[17]) ?? 1,
  );
  return object;
}

P _insightModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _insightModelGetId(InsightModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _insightModelGetLinks(InsightModel object) {
  return [];
}

void _insightModelAttach(
    IsarCollection<dynamic> col, Id id, InsightModel object) {}

extension InsightModelByIndex on IsarCollection<InsightModel> {
  Future<InsightModel?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  InsightModel? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<InsightModel?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<InsightModel?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(InsightModel object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(InsightModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<InsightModel> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<InsightModel> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension InsightModelQueryWhereSort
    on QueryBuilder<InsightModel, InsightModel, QWhere> {
  QueryBuilder<InsightModel, InsightModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension InsightModelQueryWhere
    on QueryBuilder<InsightModel, InsightModel, QWhereClause> {
  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
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

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> idNotEqualTo(
      String id) {
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

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> userIdEqualTo(
      String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> userIdNotEqualTo(
      String userId) {
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

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> threadIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'threadId',
        value: [null],
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause>
      threadIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'threadId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause> threadIdEqualTo(
      String? threadId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'threadId',
        value: [threadId],
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterWhereClause>
      threadIdNotEqualTo(String? threadId) {
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
}

extension InsightModelQueryFilter
    on QueryBuilder<InsightModel, InsightModel, QFilterCondition> {
  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actionPrompt',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actionPrompt',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actionPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actionPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actionPrompt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'actionPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'actionPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'actionPrompt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'actionPrompt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionPrompt',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      actionPromptIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'actionPrompt',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiThemes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiThemes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiThemes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiThemes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiThemes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiThemes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiThemes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiThemes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiThemes',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiThemes',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiThemes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiThemes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiThemes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiThemes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiThemes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      aiThemesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiThemes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      createdAtMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      dominantEmotionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dominantEmotion',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      dominantEmotionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dominantEmotion',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      dominantEmotionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dominantEmotion',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      dominantEmotionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dominantEmotion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'guidanceSuggestion',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'guidanceSuggestion',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guidanceSuggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'guidanceSuggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'guidanceSuggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'guidanceSuggestion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'guidanceSuggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'guidanceSuggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'guidanceSuggestion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'guidanceSuggestion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'guidanceSuggestion',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      guidanceSuggestionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'guidanceSuggestion',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idStartsWith(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      isDeletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keywords',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keywords',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keywords',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keywords',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keywords',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      keywordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'keywords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      messageCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      messageCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      messageCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'messageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      messageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'messageCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      moodScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'moodScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      moodScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'moodScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      moodScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'moodScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      moodScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'moodScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodEndMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodEndMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodEndMillisGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodEndMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodEndMillisLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodEndMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodEndMillisBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodEndMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodStartMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodStartMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodStartMillisGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodStartMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodStartMillisLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodStartMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      periodStartMillisBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodStartMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'summary',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'summary',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'summary',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'summary',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      summaryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'summary',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'threadId',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'threadId',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdEqualTo(
    String? value, {
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdGreaterThan(
    String? value, {
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdLessThan(
    String? value, {
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'threadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'threadId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'threadId',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      threadIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'threadId',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> typeEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      typeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> typeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> typeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      updatedAtMillisEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      updatedAtMillisGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      updatedAtMillisLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAtMillis',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      updatedAtMillisBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAtMillis',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> userIdEqualTo(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> userIdBetween(
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition> userIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
      versionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
      ));
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

  QueryBuilder<InsightModel, InsightModel, QAfterFilterCondition>
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

extension InsightModelQueryObject
    on QueryBuilder<InsightModel, InsightModel, QFilterCondition> {}

extension InsightModelQueryLinks
    on QueryBuilder<InsightModel, InsightModel, QFilterCondition> {}

extension InsightModelQuerySortBy
    on QueryBuilder<InsightModel, InsightModel, QSortBy> {
  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByActionPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionPrompt', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByActionPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionPrompt', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByDominantEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantEmotion', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByDominantEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantEmotion', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByGuidanceSuggestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guidanceSuggestion', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByGuidanceSuggestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guidanceSuggestion', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByPeriodEndMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByPeriodEndMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByPeriodStartMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByPeriodStartMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortBySummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortBySummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByThreadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByThreadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByUpdatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      sortByUpdatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension InsightModelQuerySortThenBy
    on QueryBuilder<InsightModel, InsightModel, QSortThenBy> {
  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByActionPrompt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionPrompt', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByActionPromptDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionPrompt', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByCreatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAtMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByDominantEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantEmotion', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByDominantEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dominantEmotion', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByGuidanceSuggestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guidanceSuggestion', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByGuidanceSuggestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'guidanceSuggestion', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByMessageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'messageCount', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByMoodScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodScore', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByPeriodEndMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByPeriodEndMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodEndMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByPeriodStartMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByPeriodStartMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodStartMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenBySummary() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenBySummaryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'summary', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByThreadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByThreadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'threadId', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByUpdatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMillis', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy>
      thenByUpdatedAtMillisDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMillis', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension InsightModelQueryWhereDistinct
    on QueryBuilder<InsightModel, InsightModel, QDistinct> {
  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByActionPrompt(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionPrompt', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByAiThemes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aiThemes');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct>
      distinctByCreatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAtMillis');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct>
      distinctByDominantEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dominantEmotion');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct>
      distinctByGuidanceSuggestion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'guidanceSuggestion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByKeywords() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keywords');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByMessageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'messageCount');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByMoodScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodScore');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct>
      distinctByPeriodEndMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodEndMillis');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct>
      distinctByPeriodStartMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodStartMillis');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctBySummary(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'summary', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByThreadId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'threadId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct>
      distinctByUpdatedAtMillis() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMillis');
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InsightModel, InsightModel, QDistinct> distinctByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version');
    });
  }
}

extension InsightModelQueryProperty
    on QueryBuilder<InsightModel, InsightModel, QQueryProperty> {
  QueryBuilder<InsightModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<InsightModel, String?, QQueryOperations> actionPromptProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionPrompt');
    });
  }

  QueryBuilder<InsightModel, List<String>, QQueryOperations>
      aiThemesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiThemes');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> createdAtMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAtMillis');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> dominantEmotionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dominantEmotion');
    });
  }

  QueryBuilder<InsightModel, String?, QQueryOperations>
      guidanceSuggestionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'guidanceSuggestion');
    });
  }

  QueryBuilder<InsightModel, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InsightModel, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<InsightModel, List<String>, QQueryOperations>
      keywordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keywords');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> messageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'messageCount');
    });
  }

  QueryBuilder<InsightModel, double, QQueryOperations> moodScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodScore');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> periodEndMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodEndMillis');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations>
      periodStartMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodStartMillis');
    });
  }

  QueryBuilder<InsightModel, String, QQueryOperations> summaryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'summary');
    });
  }

  QueryBuilder<InsightModel, String?, QQueryOperations> threadIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'threadId');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> updatedAtMillisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMillis');
    });
  }

  QueryBuilder<InsightModel, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<InsightModel, int, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }
}
