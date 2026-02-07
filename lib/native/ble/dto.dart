import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

// ============================================================================
// Advertisement & Scan
// ============================================================================

@JsonSerializable()
class AdvertisementDataDto {
  AdvertisementDataDto({
    required this.advName,
    this.txPowerLevel,
    this.appearance,
    required this.connectable,
    required this.manufacturerData,
    required this.serviceData,
    required this.serviceUuids,
  });

  factory AdvertisementDataDto.fromJson(Map<String, dynamic> json) =>
      _$AdvertisementDataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementDataDtoToJson(this);

  final String advName;
  final int? txPowerLevel;
  final int? appearance;
  final bool connectable;
  final Map<String, List<int>> manufacturerData;
  final Map<String, List<int>> serviceData;
  final List<String> serviceUuids;

  factory AdvertisementDataDto.fromFbp(fbp.AdvertisementData a) {
    return AdvertisementDataDto(
      advName: a.advName,
      txPowerLevel: a.txPowerLevel,
      appearance: a.appearance,
      connectable: a.connectable,
      manufacturerData: a.manufacturerData.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      serviceData: a.serviceData.map((k, v) => MapEntry(k.toString(), v)),
      serviceUuids: a.serviceUuids.map((u) => u.toString()).toList(),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ScanResultDto {
  ScanResultDto({
    required this.remoteId,
    required this.rssi,
    required this.advertisementData,
    required this.timestampMs,
  });

  factory ScanResultDto.fromJson(Map<String, dynamic> json) =>
      _$ScanResultDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ScanResultDtoToJson(this);

  final String remoteId;
  final int rssi;
  final AdvertisementDataDto advertisementData;
  @JsonKey(name: 'timestamp_ms')
  final int timestampMs;

  factory ScanResultDto.fromFbp(fbp.ScanResult r) {
    return ScanResultDto(
      remoteId: r.device.remoteId.str,
      rssi: r.rssi,
      advertisementData: AdvertisementDataDto.fromFbp(r.advertisementData),
      timestampMs: r.timeStamp.millisecondsSinceEpoch,
    );
  }
}

// ============================================================================
// Device & Connection
// ============================================================================

@JsonSerializable()
class BluetoothDeviceDto {
  BluetoothDeviceDto({
    required this.remoteId,
    required this.platformName,
    required this.advName,
    required this.isConnected,
    required this.mtuNow,
  });

  factory BluetoothDeviceDto.fromJson(Map<String, dynamic> json) =>
      _$BluetoothDeviceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothDeviceDtoToJson(this);

  final String remoteId;
  final String platformName;
  final String advName;
  final bool isConnected;
  final int mtuNow;

  factory BluetoothDeviceDto.fromFbp(fbp.BluetoothDevice d) {
    return BluetoothDeviceDto(
      remoteId: d.remoteId.str,
      platformName: d.platformName,
      advName: d.advName,
      isConnected: d.isConnected,
      mtuNow: d.mtuNow,
    );
  }
}

@JsonSerializable()
class DisconnectReasonDto {
  DisconnectReasonDto({required this.platform, this.code, this.description});

  factory DisconnectReasonDto.fromJson(Map<String, dynamic> json) =>
      _$DisconnectReasonDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DisconnectReasonDtoToJson(this);

  final String platform;
  final int? code;
  final String? description;

  factory DisconnectReasonDto.fromFbp(fbp.DisconnectReason r) {
    return DisconnectReasonDto(
      platform: r.platform.toString(),
      code: r.code,
      description: r.description,
    );
  }
}

// ============================================================================
// GATT: CharacteristicProperties, Descriptor, Characteristic, Service
// ============================================================================

@JsonSerializable()
class CharacteristicPropertiesDto {
  CharacteristicPropertiesDto({
    required this.broadcast,
    required this.read,
    required this.writeWithoutResponse,
    required this.write,
    required this.notify,
    required this.indicate,
    required this.authenticatedSignedWrites,
    required this.extendedProperties,
    required this.notifyEncryptionRequired,
    required this.indicateEncryptionRequired,
  });

  factory CharacteristicPropertiesDto.fromJson(Map<String, dynamic> json) =>
      _$CharacteristicPropertiesDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CharacteristicPropertiesDtoToJson(this);

  final bool broadcast;
  final bool read;
  final bool writeWithoutResponse;
  final bool write;
  final bool notify;
  final bool indicate;
  final bool authenticatedSignedWrites;
  final bool extendedProperties;
  final bool notifyEncryptionRequired;
  final bool indicateEncryptionRequired;

  factory CharacteristicPropertiesDto.fromFbp(fbp.CharacteristicProperties p) {
    return CharacteristicPropertiesDto(
      broadcast: p.broadcast,
      read: p.read,
      writeWithoutResponse: p.writeWithoutResponse,
      write: p.write,
      notify: p.notify,
      indicate: p.indicate,
      authenticatedSignedWrites: p.authenticatedSignedWrites,
      extendedProperties: p.extendedProperties,
      notifyEncryptionRequired: p.notifyEncryptionRequired,
      indicateEncryptionRequired: p.indicateEncryptionRequired,
    );
  }
}

@JsonSerializable()
class BluetoothDescriptorDto {
  BluetoothDescriptorDto({
    required this.uuid,
    required this.remoteId,
    required this.serviceUuid,
    required this.characteristicUuid,
    this.primaryServiceUuid,
    required this.lastValue,
  });

  factory BluetoothDescriptorDto.fromJson(Map<String, dynamic> json) =>
      _$BluetoothDescriptorDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothDescriptorDtoToJson(this);

  final String uuid;
  final String remoteId;
  final String serviceUuid;
  final String characteristicUuid;
  final String? primaryServiceUuid;
  final List<int> lastValue;

  factory BluetoothDescriptorDto.fromFbp(fbp.BluetoothDescriptor d) {
    return BluetoothDescriptorDto(
      uuid: d.descriptorUuid.toString(),
      remoteId: d.remoteId.str,
      serviceUuid: d.serviceUuid.toString(),
      characteristicUuid: d.characteristicUuid.toString(),
      primaryServiceUuid: d.primaryServiceUuid?.toString(),
      lastValue: d.lastValue,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BluetoothCharacteristicDto {
  BluetoothCharacteristicDto({
    required this.uuid,
    required this.remoteId,
    required this.serviceUuid,
    required this.properties,
    required this.descriptors,
    required this.isNotifying,
    required this.lastValue,
  });

  factory BluetoothCharacteristicDto.fromJson(Map<String, dynamic> json) =>
      _$BluetoothCharacteristicDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothCharacteristicDtoToJson(this);

  final String uuid;
  final String remoteId;
  final String serviceUuid;
  final CharacteristicPropertiesDto properties;
  final List<BluetoothDescriptorDto> descriptors;
  final bool isNotifying;
  final List<int> lastValue;

  factory BluetoothCharacteristicDto.fromFbp(fbp.BluetoothCharacteristic c) {
    return BluetoothCharacteristicDto(
      uuid: c.uuid.toString(),
      remoteId: c.remoteId.str,
      serviceUuid: c.serviceUuid.toString(),
      properties: CharacteristicPropertiesDto.fromFbp(c.properties),
      descriptors: c.descriptors.map(BluetoothDescriptorDto.fromFbp).toList(),
      isNotifying: c.isNotifying,
      lastValue: c.lastValue,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BluetoothServiceDto {
  BluetoothServiceDto({
    required this.uuid,
    required this.remoteId,
    this.primaryServiceUuid,
    required this.characteristics,
  });

  factory BluetoothServiceDto.fromJson(Map<String, dynamic> json) =>
      _$BluetoothServiceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$BluetoothServiceDtoToJson(this);

  final String uuid;
  final String remoteId;
  final String? primaryServiceUuid;
  final List<BluetoothCharacteristicDto> characteristics;

  factory BluetoothServiceDto.fromFbp(fbp.BluetoothService s) {
    return BluetoothServiceDto(
      uuid: s.serviceUuid.toString(),
      remoteId: s.remoteId.str,
      primaryServiceUuid: s.primaryServiceUuid?.toString(),
      characteristics: s.characteristics
          .map(BluetoothCharacteristicDto.fromFbp)
          .toList(),
    );
  }
}
