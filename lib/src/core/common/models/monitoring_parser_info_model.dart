import 'package:freezed_annotation/freezed_annotation.dart';

part 'monitoring_parser_info_model.freezed.dart';
part 'monitoring_parser_info_model.g.dart';

@freezed
abstract class MonitoringParserInfoModel with _$MonitoringParserInfoModel {
  const factory MonitoringParserInfoModel({
    required String name,
    required int length,
    required bool control,
    @Default('int') @JsonKey(includeIfNull: false) String type,
    @JsonKey(includeIfNull: false) String? desc,
    @Default(false) @JsonKey(includeIfNull: false) bool? sign,
    @JsonKey(includeIfNull: false) String? deco,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? map,
  }) = _MonitoringParserInfoModel;

  factory MonitoringParserInfoModel.fromJson(Map<String, Object?> json) =>
      _$MonitoringParserInfoModelFromJson(json);
}
