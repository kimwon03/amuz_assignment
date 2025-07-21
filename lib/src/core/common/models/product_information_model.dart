import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_information_model.freezed.dart';
part 'product_information_model.g.dart';

@freezed
abstract class ProductInformationModel with _$ProductInformationModel {
  const factory ProductInformationModel({
    @JsonKey(name: "dxi_module_ver") required String dxiModuleVer,
    @JsonKey(name: "prddesc_ver") required String prddescVer,
    @JsonKey(name: "thinq_model") required String thinqModel,
    @JsonKey(name: "dev_id") required String devID,
  }) = _ProductInformationModel;

  factory ProductInformationModel.fromJson(Map<String, Object?> json) => _$ProductInformationModelFromJson(json); 
}
