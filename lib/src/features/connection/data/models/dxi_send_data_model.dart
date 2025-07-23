import 'package:freezed_annotation/freezed_annotation.dart';

part 'dxi_send_data_model.freezed.dart';
part 'dxi_send_data_model.g.dart';

@Freezed(toJson: true)
abstract class DxiSendDataModel with _$DxiSendDataModel {
  const factory DxiSendDataModel({
    @JsonKey(includeIfNull: false) String? bytes,
    @JsonKey(includeIfNull: false) String? exitAP,
    @Default('Y') String constantConnect,
  }) = _DxiSendDataModel;
}
