# Generator coverage map (ClickHouseSqlGenerator.pqm)

Legend: FOLDED = generated SQL verified in system.query_log · VALUES = results verified only
· NONE = no test · BLOCKED = external blocker.

## Type system
| Functionality | Test(s) | Level |
|---|---|---|
| SqlGetTypeInfo catalog | all + Sanity/ColumnTypes | FOLDED (indirect) |
| Decimal(38,10) row / emitted casts | KnownIssues/DecimalDivision, Functions/SumPrecisionDecimal | FOLDED |
| SupportedConversions | indirect | VALUES |
| SqlTypesCategories | DAX-path manual only | NONE |
| DefaultTypes (literals) | all filter tests | FOLDED |

## Helpers
| Helper | Test(s) | Level |
|---|---|---|
| MatchInvocation / DistinctCols | GroupDistinctCount, ApproxDistinct, DistinctCountListShape | FOLDED |
| ValueFunctions(+ArgumentsVisitor) | Arithmetic, DecimalDivision | FOLDED (int+int engine-cast quirk documented) |
| NumericFromHelper | Functions/NumericFrom, PrecisionArithmetic | FOLDED (Decimal operands cast to DOUBLE; floating/unknown pass through) |
| ValueAsAndReplaceType | Functions/ValueAsFold | FOLDED (pure passthrough) |
| MinMaxHelper | Aggregates, MinMaxDatesText | FOLDED |
| Date helpers ×3 | DateFunctions, DateCoverage | FOLDED |

## FunctionOverrides
| Override | Test(s) | Level |
|---|---|---|
| List.Contains → IN/= (null member → isNull branch) | MultiValueFilter, NullSemantics | FOLDED |
| List.Sum / Average / Min / Max | FilterRangeGroupBy, Aggregates, AverageTypes, MinMaxDatesText | FOLDED |
| List.Count plain / distinct spelling (null-preserving) | Aggregates, FilterRangeGroupBy / DistinctCountListShape, NullSemantics | FOLDED |
| Table.RowCount plain + distinct (null-preserving) | FilterRangeGroupBy, GroupDistinctCount, NullSemantics | FOLDED |
| Table.ApproximateRowCount | ApproxDistinct | FOLDED |
| Outer joins (folding disabled: join_use_nulls = 0 breaks null semantics) | OuterJoinNulls | LOCAL by design |
| Value.Add/Subtract/Multiply | Arithmetic | FOLDED (explicit/default precision honored) |
| Value.Divide | DecimalDivision, PrecisionArithmetic | FOLDED (Precision.Double → DOUBLE casts; Precision.Decimal → Decimal(38,10) dividend) |
| Value.As / ReplaceType | Functions/ValueAsFold | FOLDED (pure passthrough) |
| Double.From / Number.From | NumericFrom, PrecisionArithmetic | FOLDED (real conversion on Decimal) |
| Value.Compare | ValueCompare | FOLDED (overflow case documented, untested by design) |
| Date parts / StartOf* / Add* | DateCoverage, DateFunctions | FOLDED |
| Date.StartOfDay (datetime branch) | — | BLOCKED (server emits plain DateTime as Arrow uint32) |
| MapClickHouseType plain-DateTime mitigation (epoch Int64) | KnownIssues/PlainDateTime | FOLDED-adjacent (load path) |
| Text.PositionOf (found + absent, character-aware) | TextFolding, TextUnicode | FOLDED (positionUTF8) |
| Text.Contains/StartsWith/EndsWith | TextPredicates, TextFolding | FOLDED |
| Base text (Upper/Lower/Length/Start/End/Replace) | TextFolding, TextUnicode | FOLDED (*UTF8 family; ICU-less servers fall back to local eval) |
| Text.TrimStart / TrimEnd | — | LOCAL by design (CH trims ASCII space only; M trims all whitespace) |
| Text.BeforeDelimiter | — | BLOCKED (engine never routes; workaround documented) |

## Override record
| Piece | Test(s) | Level |
|---|---|---|
| ImplicitTypeConversions | FilterEquals, FilterRangeGroupBy | FOLDED (cast-free filters) |
| Value.NativeQuery (OnNativeQuery handler) | Functions/NativeQuery | VALUES (raw SQL incl. SETTINGS) |
| SqlCapabilities.LimitClauseKind | SortFirstN | FOLDED |
| Binary/UnaryOperatorOverrides | empty — pending MS documentation | n/a |
