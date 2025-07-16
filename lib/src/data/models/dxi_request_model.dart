import 'package:freezed_annotation/freezed_annotation.dart';

part 'dxi_request_model.freezed.dart';
part 'dxi_request_model.g.dart';

@Freezed(toJson: true)
abstract class DxiRequestModel with _$DxiRequestModel {
  const factory DxiRequestModel({
    required String type,
    required String cmd,
    required Map<String, dynamic> data,
  }) = _DxiRequestModel;
}
