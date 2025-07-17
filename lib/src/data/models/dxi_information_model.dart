import 'package:freezed_annotation/freezed_annotation.dart';

part 'dxi_information_model.freezed.dart';
part 'dxi_information_model.g.dart';

@Freezed(toJson: true)
abstract class DxiInformationModel with _$DxiInformationModel {
  const factory DxiInformationModel({
    @JsonKey(name: "dxi_module_ver") required String dxiModuleVer,
    @JsonKey(name: "prddesc_ver") required String prddescVer,
    @JsonKey(name: "thinq_model") required String thinqModel,
    @JsonKey(name: "dev_id") required String devID,
  }) = _DxiInformationModel;
}
