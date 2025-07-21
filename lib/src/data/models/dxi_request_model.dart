import 'package:amuz_assignment/src/data/models/dxi_send_data_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dxi_request_model.freezed.dart';
part 'dxi_request_model.g.dart';

@Freezed(toJson: true)
abstract class DxiRequestModel with _$DxiRequestModel {
  const factory DxiRequestModel({
    required String type,
    required String cmd,
    required DxiSendDataModel data,
  }) = _DxiRequestModel;
}
