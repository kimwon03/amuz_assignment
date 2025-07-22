import 'package:freezed_annotation/freezed_annotation.dart';

part 'monitoring_parser_info.freezed.dart';
part 'monitoring_parser_info.g.dart';

@Freezed(fromJson: true)
abstract class MonitoringParserInfo with _$MonitoringParserInfo {
  const factory MonitoringParserInfo({
    required String name,
    required String length,
    required bool control,
    @Default('int') @JsonKey(includeIfNull: false) String type,
    required String desc,
    @Default(false) @JsonKey(includeIfNull: false) bool? signed,
    @JsonKey(includeIfNull: false) String? deco,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? map,
  }) = _MonitoringParserInfo;
}
