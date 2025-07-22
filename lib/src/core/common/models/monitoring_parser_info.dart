import 'package:freezed_annotation/freezed_annotation.dart';

part 'monitoring_parser_info.freezed.dart';

@freezed
abstract class MonitoringParserInfo with _$MonitoringParserInfo {
  const factory MonitoringParserInfo({
    required String name,
    required String type,
    required int length,
    required bool signed,
  }) = _MonitoringParserInfo;
}
