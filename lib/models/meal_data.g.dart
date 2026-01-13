// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_data.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNutritionLogCollection on Isar {
  IsarCollection<NutritionLog> get nutritionLogs => this.collection();
}

const NutritionLogSchema = CollectionSchema(
  name: r'NutritionLog',
  id: -2651811333627064168,
  properties: {
    r'aiGeneratedMeals': PropertySchema(
      id: 0,
      name: r'aiGeneratedMeals',
      type: IsarType.objectList,
      target: r'Meal',
    ),
    r'date': PropertySchema(
      id: 1,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'hungerRating': PropertySchema(
      id: 2,
      name: r'hungerRating',
      type: IsarType.long,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'isDirty': PropertySchema(
      id: 4,
      name: r'isDirty',
      type: IsarType.bool,
    ),
    r'isLowCarbDay': PropertySchema(
      id: 5,
      name: r'isLowCarbDay',
      type: IsarType.bool,
    ),
    r'lastSynced': PropertySchema(
      id: 6,
      name: r'lastSynced',
      type: IsarType.dateTime,
    ),
    r'meals': PropertySchema(
      id: 7,
      name: r'meals',
      type: IsarType.objectList,
      target: r'MealSlot',
    ),
    r'totalCalories': PropertySchema(
      id: 8,
      name: r'totalCalories',
      type: IsarType.double,
    ),
    r'totalMacros': PropertySchema(
      id: 9,
      name: r'totalMacros',
      type: IsarType.object,
      target: r'MacroData',
    ),
    r'waterIntake': PropertySchema(
      id: 10,
      name: r'waterIntake',
      type: IsarType.double,
    )
  },
  estimateSize: _nutritionLogEstimateSize,
  serialize: _nutritionLogSerialize,
  deserialize: _nutritionLogDeserialize,
  deserializeProp: _nutritionLogDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'id': IndexSchema(
      id: -3268401673993471357,
      name: r'id',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'id',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'MealSlot': MealSlotSchema,
    r'FoodItem': FoodItemSchema,
    r'Meal': MealSchema,
    r'MacroData': MacroDataSchema
  },
  getId: _nutritionLogGetId,
  getLinks: _nutritionLogGetLinks,
  attach: _nutritionLogAttach,
  version: '3.1.0+1',
);

int _nutritionLogEstimateSize(
  NutritionLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.aiGeneratedMeals.length * 3;
  {
    final offsets = allOffsets[Meal]!;
    for (var i = 0; i < object.aiGeneratedMeals.length; i++) {
      final value = object.aiGeneratedMeals[i];
      bytesCount += MealSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.meals.length * 3;
  {
    final offsets = allOffsets[MealSlot]!;
    for (var i = 0; i < object.meals.length; i++) {
      final value = object.meals[i];
      bytesCount += MealSlotSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.totalMacros;
    if (value != null) {
      bytesCount += 3 +
          MacroDataSchema.estimateSize(
              value, allOffsets[MacroData]!, allOffsets);
    }
  }
  return bytesCount;
}

void _nutritionLogSerialize(
  NutritionLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<Meal>(
    offsets[0],
    allOffsets,
    MealSchema.serialize,
    object.aiGeneratedMeals,
  );
  writer.writeDateTime(offsets[1], object.date);
  writer.writeLong(offsets[2], object.hungerRating);
  writer.writeString(offsets[3], object.id);
  writer.writeBool(offsets[4], object.isDirty);
  writer.writeBool(offsets[5], object.isLowCarbDay);
  writer.writeDateTime(offsets[6], object.lastSynced);
  writer.writeObjectList<MealSlot>(
    offsets[7],
    allOffsets,
    MealSlotSchema.serialize,
    object.meals,
  );
  writer.writeDouble(offsets[8], object.totalCalories);
  writer.writeObject<MacroData>(
    offsets[9],
    allOffsets,
    MacroDataSchema.serialize,
    object.totalMacros,
  );
  writer.writeDouble(offsets[10], object.waterIntake);
}

NutritionLog _nutritionLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NutritionLog(
    aiGeneratedMeals: reader.readObjectList<Meal>(
          offsets[0],
          MealSchema.deserialize,
          allOffsets,
          Meal(),
        ) ??
        const [],
    date: reader.readDateTime(offsets[1]),
    hungerRating: reader.readLongOrNull(offsets[2]),
    id: reader.readString(offsets[3]),
    isDirty: reader.readBoolOrNull(offsets[4]) ?? false,
    isLowCarbDay: reader.readBoolOrNull(offsets[5]) ?? false,
    lastSynced: reader.readDateTimeOrNull(offsets[6]),
    meals: reader.readObjectList<MealSlot>(
          offsets[7],
          MealSlotSchema.deserialize,
          allOffsets,
          MealSlot(),
        ) ??
        [],
    totalCalories: reader.readDouble(offsets[8]),
    totalMacros: reader.readObjectOrNull<MacroData>(
      offsets[9],
      MacroDataSchema.deserialize,
      allOffsets,
    ),
    waterIntake: reader.readDouble(offsets[10]),
  );
  object.isarId = id;
  return object;
}

P _nutritionLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<Meal>(
            offset,
            MealSchema.deserialize,
            allOffsets,
            Meal(),
          ) ??
          const []) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readObjectList<MealSlot>(
            offset,
            MealSlotSchema.deserialize,
            allOffsets,
            MealSlot(),
          ) ??
          []) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readObjectOrNull<MacroData>(
        offset,
        MacroDataSchema.deserialize,
        allOffsets,
      )) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _nutritionLogGetId(NutritionLog object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _nutritionLogGetLinks(NutritionLog object) {
  return [];
}

void _nutritionLogAttach(
    IsarCollection<dynamic> col, Id id, NutritionLog object) {
  object.isarId = id;
}

extension NutritionLogByIndex on IsarCollection<NutritionLog> {
  Future<NutritionLog?> getById(String id) {
    return getByIndex(r'id', [id]);
  }

  NutritionLog? getByIdSync(String id) {
    return getByIndexSync(r'id', [id]);
  }

  Future<bool> deleteById(String id) {
    return deleteByIndex(r'id', [id]);
  }

  bool deleteByIdSync(String id) {
    return deleteByIndexSync(r'id', [id]);
  }

  Future<List<NutritionLog?>> getAllById(List<String> idValues) {
    final values = idValues.map((e) => [e]).toList();
    return getAllByIndex(r'id', values);
  }

  List<NutritionLog?> getAllByIdSync(List<String> idValues) {
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

  Future<Id> putById(NutritionLog object) {
    return putByIndex(r'id', object);
  }

  Id putByIdSync(NutritionLog object, {bool saveLinks = true}) {
    return putByIndexSync(r'id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllById(List<NutritionLog> objects) {
    return putAllByIndex(r'id', objects);
  }

  List<Id> putAllByIdSync(List<NutritionLog> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'id', objects, saveLinks: saveLinks);
  }
}

extension NutritionLogQueryWhereSort
    on QueryBuilder<NutritionLog, NutritionLog, QWhere> {
  QueryBuilder<NutritionLog, NutritionLog, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension NutritionLogQueryWhere
    on QueryBuilder<NutritionLog, NutritionLog, QWhereClause> {
  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> isarIdNotEqualTo(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> isarIdBetween(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> idEqualTo(
      String id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'id',
        value: [id],
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterWhereClause> idNotEqualTo(
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
}

extension NutritionLogQueryFilter
    on QueryBuilder<NutritionLog, NutritionLog, QFilterCondition> {
  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiGeneratedMeals',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiGeneratedMeals',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiGeneratedMeals',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiGeneratedMeals',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiGeneratedMeals',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'aiGeneratedMeals',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      hungerRatingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hungerRating',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      hungerRatingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hungerRating',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      hungerRatingEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hungerRating',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      hungerRatingGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hungerRating',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      hungerRatingLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hungerRating',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      hungerRatingBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hungerRating',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idStartsWith(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idContains(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idMatches(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      isDirtyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDirty',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      isLowCarbDayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLowCarbDay',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> isarIdBetween(
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

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      lastSyncedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSynced',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      lastSyncedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSynced',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      lastSyncedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      lastSyncedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      lastSyncedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      lastSyncedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSynced',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      mealsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      mealsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      mealsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      mealsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      mealsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      mealsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'meals',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      totalCaloriesEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalCalories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      totalCaloriesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalCalories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      totalCaloriesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalCalories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      totalCaloriesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalCalories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      totalMacrosIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'totalMacros',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      totalMacrosIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'totalMacros',
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      waterIntakeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waterIntake',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      waterIntakeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waterIntake',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      waterIntakeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waterIntake',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      waterIntakeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waterIntake',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension NutritionLogQueryObject
    on QueryBuilder<NutritionLog, NutritionLog, QFilterCondition> {
  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition>
      aiGeneratedMealsElement(FilterQuery<Meal> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'aiGeneratedMeals');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> mealsElement(
      FilterQuery<MealSlot> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'meals');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterFilterCondition> totalMacros(
      FilterQuery<MacroData> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'totalMacros');
    });
  }
}

extension NutritionLogQueryLinks
    on QueryBuilder<NutritionLog, NutritionLog, QFilterCondition> {}

extension NutritionLogQuerySortBy
    on QueryBuilder<NutritionLog, NutritionLog, QSortBy> {
  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByHungerRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerRating', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      sortByHungerRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerRating', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByIsLowCarbDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLowCarbDay', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      sortByIsLowCarbDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLowCarbDay', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByLastSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      sortByLastSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      sortByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> sortByWaterIntake() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterIntake', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      sortByWaterIntakeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterIntake', Sort.desc);
    });
  }
}

extension NutritionLogQuerySortThenBy
    on QueryBuilder<NutritionLog, NutritionLog, QSortThenBy> {
  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByHungerRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerRating', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      thenByHungerRatingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hungerRating', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByIsLowCarbDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLowCarbDay', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      thenByIsLowCarbDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLowCarbDay', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByLastSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      thenByLastSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSynced', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      thenByTotalCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalCalories', Sort.desc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy> thenByWaterIntake() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterIntake', Sort.asc);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QAfterSortBy>
      thenByWaterIntakeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'waterIntake', Sort.desc);
    });
  }
}

extension NutritionLogQueryWhereDistinct
    on QueryBuilder<NutritionLog, NutritionLog, QDistinct> {
  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctByHungerRating() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hungerRating');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDirty');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctByIsLowCarbDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLowCarbDay');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctByLastSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSynced');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct>
      distinctByTotalCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalCalories');
    });
  }

  QueryBuilder<NutritionLog, NutritionLog, QDistinct> distinctByWaterIntake() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'waterIntake');
    });
  }
}

extension NutritionLogQueryProperty
    on QueryBuilder<NutritionLog, NutritionLog, QQueryProperty> {
  QueryBuilder<NutritionLog, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<NutritionLog, List<Meal>, QQueryOperations>
      aiGeneratedMealsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiGeneratedMeals');
    });
  }

  QueryBuilder<NutritionLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<NutritionLog, int?, QQueryOperations> hungerRatingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hungerRating');
    });
  }

  QueryBuilder<NutritionLog, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NutritionLog, bool, QQueryOperations> isDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDirty');
    });
  }

  QueryBuilder<NutritionLog, bool, QQueryOperations> isLowCarbDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLowCarbDay');
    });
  }

  QueryBuilder<NutritionLog, DateTime?, QQueryOperations> lastSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSynced');
    });
  }

  QueryBuilder<NutritionLog, List<MealSlot>, QQueryOperations> mealsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'meals');
    });
  }

  QueryBuilder<NutritionLog, double, QQueryOperations> totalCaloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalCalories');
    });
  }

  QueryBuilder<NutritionLog, MacroData?, QQueryOperations>
      totalMacrosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalMacros');
    });
  }

  QueryBuilder<NutritionLog, double, QQueryOperations> waterIntakeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'waterIntake');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const FoodItemSchema = Schema(
  name: r'FoodItem',
  id: 8311037358550475404,
  properties: {
    r'calories': PropertySchema(
      id: 0,
      name: r'calories',
      type: IsarType.double,
    ),
    r'carbs': PropertySchema(
      id: 1,
      name: r'carbs',
      type: IsarType.double,
    ),
    r'fat': PropertySchema(
      id: 2,
      name: r'fat',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 4,
      name: r'notes',
      type: IsarType.string,
    ),
    r'protein': PropertySchema(
      id: 5,
      name: r'protein',
      type: IsarType.double,
    )
  },
  estimateSize: _foodItemEstimateSize,
  serialize: _foodItemSerialize,
  deserialize: _foodItemDeserialize,
  deserializeProp: _foodItemDeserializeProp,
);

int _foodItemEstimateSize(
  FoodItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _foodItemSerialize(
  FoodItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.calories);
  writer.writeDouble(offsets[1], object.carbs);
  writer.writeDouble(offsets[2], object.fat);
  writer.writeString(offsets[3], object.name);
  writer.writeString(offsets[4], object.notes);
  writer.writeDouble(offsets[5], object.protein);
}

FoodItem _foodItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FoodItem(
    calories: reader.readDoubleOrNull(offsets[0]),
    carbs: reader.readDoubleOrNull(offsets[1]),
    fat: reader.readDoubleOrNull(offsets[2]),
    name: reader.readStringOrNull(offsets[3]),
    notes: reader.readStringOrNull(offsets[4]),
    protein: reader.readDoubleOrNull(offsets[5]),
  );
  return object;
}

P _foodItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension FoodItemQueryFilter
    on QueryBuilder<FoodItem, FoodItem, QFilterCondition> {
  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> caloriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calories',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> caloriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calories',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> caloriesEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> caloriesGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> caloriesLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> caloriesBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> carbsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'carbs',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> carbsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'carbs',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> carbsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> carbsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> carbsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> carbsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> fatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fat',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> fatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fat',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> fatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> fatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> fatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> fatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> proteinIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'protein',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> proteinIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'protein',
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> proteinEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> proteinGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> proteinLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodItem, FoodItem, QAfterFilterCondition> proteinBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension FoodItemQueryObject
    on QueryBuilder<FoodItem, FoodItem, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MealSchema = Schema(
  name: r'Meal',
  id: 2462895270179255875,
  properties: {
    r'aiInsight': PropertySchema(
      id: 0,
      name: r'aiInsight',
      type: IsarType.string,
    ),
    r'calories': PropertySchema(
      id: 1,
      name: r'calories',
      type: IsarType.double,
    ),
    r'carbs': PropertySchema(
      id: 2,
      name: r'carbs',
      type: IsarType.double,
    ),
    r'fat': PropertySchema(
      id: 3,
      name: r'fat',
      type: IsarType.double,
    ),
    r'foods': PropertySchema(
      id: 4,
      name: r'foods',
      type: IsarType.objectList,
      target: r'FoodItem',
    ),
    r'mealName': PropertySchema(
      id: 5,
      name: r'mealName',
      type: IsarType.string,
    ),
    r'protein': PropertySchema(
      id: 6,
      name: r'protein',
      type: IsarType.double,
    )
  },
  estimateSize: _mealEstimateSize,
  serialize: _mealSerialize,
  deserialize: _mealDeserialize,
  deserializeProp: _mealDeserializeProp,
);

int _mealEstimateSize(
  Meal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aiInsight;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.foods;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[FoodItem]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += FoodItemSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.mealName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mealSerialize(
  Meal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.aiInsight);
  writer.writeDouble(offsets[1], object.calories);
  writer.writeDouble(offsets[2], object.carbs);
  writer.writeDouble(offsets[3], object.fat);
  writer.writeObjectList<FoodItem>(
    offsets[4],
    allOffsets,
    FoodItemSchema.serialize,
    object.foods,
  );
  writer.writeString(offsets[5], object.mealName);
  writer.writeDouble(offsets[6], object.protein);
}

Meal _mealDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Meal(
    aiInsight: reader.readStringOrNull(offsets[0]),
    calories: reader.readDoubleOrNull(offsets[1]),
    carbs: reader.readDoubleOrNull(offsets[2]),
    fat: reader.readDoubleOrNull(offsets[3]),
    foods: reader.readObjectList<FoodItem>(
      offsets[4],
      FoodItemSchema.deserialize,
      allOffsets,
      FoodItem(),
    ),
    mealName: reader.readStringOrNull(offsets[5]),
    protein: reader.readDoubleOrNull(offsets[6]),
  );
  return object;
}

P _mealDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readObjectList<FoodItem>(
        offset,
        FoodItemSchema.deserialize,
        allOffsets,
        FoodItem(),
      )) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MealQueryFilter on QueryBuilder<Meal, Meal, QFilterCondition> {
  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiInsight',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiInsight',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aiInsight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'aiInsight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'aiInsight',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aiInsight',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> aiInsightIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'aiInsight',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calories',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calories',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> caloriesBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> carbsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'carbs',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> carbsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'carbs',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> carbsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> carbsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> carbsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> carbsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> fatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fat',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> fatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fat',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> fatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> fatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> fatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> fatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'foods',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'foods',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foods',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foods',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foods',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foods',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foods',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'foods',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mealName',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mealName',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mealName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mealName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mealName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mealName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealName',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> mealNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mealName',
        value: '',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> proteinIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'protein',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> proteinIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'protein',
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> proteinEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> proteinGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> proteinLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Meal, Meal, QAfterFilterCondition> proteinBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension MealQueryObject on QueryBuilder<Meal, Meal, QFilterCondition> {
  QueryBuilder<Meal, Meal, QAfterFilterCondition> foodsElement(
      FilterQuery<FoodItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'foods');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MacroDataSchema = Schema(
  name: r'MacroData',
  id: 2989017472935850073,
  properties: {
    r'carbs': PropertySchema(
      id: 0,
      name: r'carbs',
      type: IsarType.double,
    ),
    r'fat': PropertySchema(
      id: 1,
      name: r'fat',
      type: IsarType.double,
    ),
    r'protein': PropertySchema(
      id: 2,
      name: r'protein',
      type: IsarType.double,
    )
  },
  estimateSize: _macroDataEstimateSize,
  serialize: _macroDataSerialize,
  deserialize: _macroDataDeserialize,
  deserializeProp: _macroDataDeserializeProp,
);

int _macroDataEstimateSize(
  MacroData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _macroDataSerialize(
  MacroData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.carbs);
  writer.writeDouble(offsets[1], object.fat);
  writer.writeDouble(offsets[2], object.protein);
}

MacroData _macroDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MacroData();
  object.carbs = reader.readDouble(offsets[0]);
  object.fat = reader.readDouble(offsets[1]);
  object.protein = reader.readDouble(offsets[2]);
  return object;
}

P _macroDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MacroDataQueryFilter
    on QueryBuilder<MacroData, MacroData, QFilterCondition> {
  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> carbsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> carbsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> carbsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> carbsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> fatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> fatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> fatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> fatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> proteinEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> proteinGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> proteinLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MacroData, MacroData, QAfterFilterCondition> proteinBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension MacroDataQueryObject
    on QueryBuilder<MacroData, MacroData, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MealSlotSchema = Schema(
  name: r'MealSlot',
  id: -3265427123325135810,
  properties: {
    r'items': PropertySchema(
      id: 0,
      name: r'items',
      type: IsarType.objectList,
      target: r'FoodItem',
    ),
    r'slotName': PropertySchema(
      id: 1,
      name: r'slotName',
      type: IsarType.string,
    )
  },
  estimateSize: _mealSlotEstimateSize,
  serialize: _mealSlotSerialize,
  deserialize: _mealSlotDeserialize,
  deserializeProp: _mealSlotDeserializeProp,
);

int _mealSlotEstimateSize(
  MealSlot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.items;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[FoodItem]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += FoodItemSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.slotName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mealSlotSerialize(
  MealSlot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<FoodItem>(
    offsets[0],
    allOffsets,
    FoodItemSchema.serialize,
    object.items,
  );
  writer.writeString(offsets[1], object.slotName);
}

MealSlot _mealSlotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MealSlot();
  object.items = reader.readObjectList<FoodItem>(
    offsets[0],
    FoodItemSchema.deserialize,
    allOffsets,
    FoodItem(),
  );
  object.slotName = reader.readStringOrNull(offsets[1]);
  return object;
}

P _mealSlotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<FoodItem>(
        offset,
        FoodItemSchema.deserialize,
        allOffsets,
        FoodItem(),
      )) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MealSlotQueryFilter
    on QueryBuilder<MealSlot, MealSlot, QFilterCondition> {
  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'items',
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'items',
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition>
      itemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'slotName',
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'slotName',
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slotName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slotName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slotName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slotName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slotName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slotName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slotName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slotName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slotName',
        value: '',
      ));
    });
  }

  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> slotNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slotName',
        value: '',
      ));
    });
  }
}

extension MealSlotQueryObject
    on QueryBuilder<MealSlot, MealSlot, QFilterCondition> {
  QueryBuilder<MealSlot, MealSlot, QAfterFilterCondition> itemsElement(
      FilterQuery<FoodItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}
