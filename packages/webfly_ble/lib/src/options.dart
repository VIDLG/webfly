import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:json_annotation/json_annotation.dart';

part 'options.g.dart';

// ---------- JSON converters ----------
List<Guid> _guidListFromJson(List<dynamic>? list) =>
    (list ?? []).map((e) => Guid(e as String)).toList();
List<String> _guidListToJson(List<Guid> list) =>
    list.map((e) => e.toString()).toList();

String _guidToJson(Guid g) => g.toString();

Duration? _durationSecondsFromJson(dynamic v) =>
    v == null ? null : Duration(seconds: (v as num).toInt());
int? _durationSecondsToJson(Duration? d) => d?.inSeconds;

/// AndroidScanMode is not a Dart Enum (no .values/.name); it uses platform int (.value).
AndroidScanMode _androidScanModeFromJson(dynamic v) {
  if (v is! int) return AndroidScanMode.lowLatency;
  const modes = [
    AndroidScanMode.opportunistic,
    AndroidScanMode.lowPower,
    AndroidScanMode.balanced,
    AndroidScanMode.lowLatency,
  ];
  for (final m in modes) {
    if (m.value == v) return m;
  }
  return AndroidScanMode.lowLatency;
}

int _androidScanModeToJson(AndroidScanMode m) => m.value;

// ---------- MsdFilterOption & ServiceDataFilterOption (JSON-serializable options for ScanOptions) ----------

@JsonSerializable()
class MsdFilterOption {
  final int manufacturerId;
  final List<int> data;

  const MsdFilterOption({this.manufacturerId = 0, this.data = const []});

  factory MsdFilterOption.fromJson(Map<String, dynamic> json) =>
      _$MsdFilterOptionFromJson(json);
  Map<String, dynamic> toJson() => _$MsdFilterOptionToJson(this);

  MsdFilter toFbp() => MsdFilter(manufacturerId, data: data);
}

@JsonSerializable()
class ServiceDataFilterOption {
  @JsonKey(
    name: 'serviceUuid',
    fromJson: _serviceUuidFromJson,
    toJson: _guidToJson,
  )
  final Guid service;
  final List<int> data;

  ServiceDataFilterOption({Guid? service, this.data = const []})
    : service = service ?? Guid.empty();

  factory ServiceDataFilterOption.fromJson(Map<String, dynamic> json) =>
      _$ServiceDataFilterOptionFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceDataFilterOptionToJson(this);

  ServiceDataFilter toFbp() => ServiceDataFilter(service, data: data);
}

Guid _serviceUuidFromJson(dynamic v) =>
    v == null ? Guid.empty() : Guid(v as String);

// ---------- ScanOptions ----------

@JsonSerializable()
class ScanOptions {
  @JsonKey(fromJson: _guidListFromJson, toJson: _guidListToJson)
  final List<Guid> withServices;
  final List<String> withRemoteIds;
  final List<String> withNames;
  final List<String> withKeywords;
  final List<MsdFilterOption> withMsd;
  final List<ServiceDataFilterOption> withServiceData;
  @JsonKey(fromJson: _durationSecondsFromJson, toJson: _durationSecondsToJson)
  final Duration? timeout;
  @JsonKey(fromJson: _durationSecondsFromJson, toJson: _durationSecondsToJson)
  final Duration? removeIfGone;
  final bool continuousUpdates;
  final int continuousDivisor;
  final bool oneByOne;
  final bool androidLegacy;
  @JsonKey(fromJson: _androidScanModeFromJson, toJson: _androidScanModeToJson)
  final AndroidScanMode androidScanMode;
  final bool androidUsesFineLocation;
  final bool androidCheckLocationServices;
  @JsonKey(fromJson: _guidListFromJson, toJson: _guidListToJson)
  final List<Guid> webOptionalServices;

  const ScanOptions({
    this.withServices = const [],
    this.withRemoteIds = const [],
    this.withNames = const [],
    this.withKeywords = const [],
    this.withMsd = const [],
    this.withServiceData = const [],
    this.timeout,
    this.removeIfGone,
    this.continuousUpdates = false,
    this.continuousDivisor = 1,
    this.oneByOne = false,
    this.androidLegacy = false,
    this.androidScanMode = AndroidScanMode.lowLatency,
    this.androidUsesFineLocation = false,
    this.androidCheckLocationServices = true,
    this.webOptionalServices = const [],
  });

  factory ScanOptions.fromJson(Map<String, dynamic> json) =>
      _$ScanOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$ScanOptionsToJson(this);

  List<MsdFilter> get fbpWithMsd => withMsd.map((e) => e.toFbp()).toList();
  List<ServiceDataFilter> get fbpWithServiceData =>
      withServiceData.map((e) => e.toFbp()).toList();

  Map<Symbol, dynamic> toSymbolMap() {
    return {
      #withServices: withServices,
      #withRemoteIds: withRemoteIds,
      #withNames: withNames,
      #withKeywords: withKeywords,
      #withMsd: withMsd,
      #withServiceData: withServiceData,
      if (timeout != null) #timeout: timeout,
      if (removeIfGone != null) #removeIfGone: removeIfGone,
      #continuousUpdates: continuousUpdates,
      #continuousDivisor: continuousDivisor,
      #oneByOne: oneByOne,
      #androidLegacy: androidLegacy,
      #androidScanMode: androidScanMode,
      #androidUsesFineLocation: androidUsesFineLocation,
      #androidCheckLocationServices: androidCheckLocationServices,
      #webOptionalServices: webOptionalServices,
    };
  }
}

@JsonSerializable()
class SetOptions {
  final bool showPowerAlert;
  final bool restoreState;

  const SetOptions({this.showPowerAlert = true, this.restoreState = false});

  factory SetOptions.fromJson(Map<String, dynamic> json) =>
      _$SetOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$SetOptionsToJson(this);
}

License _licenseFromJson(dynamic v) =>
    v == 'commercial' ? License.commercial : License.free;
String _licenseToJson(License l) =>
    l == License.commercial ? 'commercial' : 'free';

Duration _connectTimeoutFromJson(dynamic v) => v == null
    ? const Duration(seconds: 35)
    : Duration(seconds: (v as num).toInt());

@JsonSerializable()
class ConnectOptions {
  @JsonKey(fromJson: _connectTimeoutFromJson, toJson: _durationSecondsToJson)
  final Duration timeout;
  final int mtu;
  final bool autoConnect;
  @JsonKey(fromJson: _licenseFromJson, toJson: _licenseToJson)
  final License license;

  const ConnectOptions({
    this.timeout = const Duration(seconds: 35),
    this.mtu = 512,
    this.autoConnect = false,
    this.license = License.free,
  });

  factory ConnectOptions.fromJson(Map<String, dynamic> json) =>
      _$ConnectOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$ConnectOptionsToJson(this);
}

@JsonSerializable()
class DisconnectOptions {
  final int timeout;
  final bool queue;
  final int androidDelay;

  const DisconnectOptions({
    this.timeout = 35,
    this.queue = true,
    this.androidDelay = 2000,
  });

  factory DisconnectOptions.fromJson(Map<String, dynamic> json) =>
      _$DisconnectOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$DisconnectOptionsToJson(this);
}

@JsonSerializable()
class DiscoverServicesOptions {
  final bool subscribeToServicesChanged;
  final int timeout;

  const DiscoverServicesOptions({
    this.subscribeToServicesChanged = false,
    this.timeout = 15,
  });

  factory DiscoverServicesOptions.fromJson(Map<String, dynamic> json) =>
      _$DiscoverServicesOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$DiscoverServicesOptionsToJson(this);
}

// ----------------------------------------------------------------------------
// Characteristic Options
// ----------------------------------------------------------------------------

@JsonSerializable()
class ReadCharacteristicOptions {
  final int timeout;

  const ReadCharacteristicOptions({this.timeout = 15});

  factory ReadCharacteristicOptions.fromJson(Map<String, dynamic> json) =>
      _$ReadCharacteristicOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$ReadCharacteristicOptionsToJson(this);
}

@JsonSerializable()
class WriteCharacteristicOptions {
  final bool withoutResponse;
  final bool allowLongWrite;
  final int timeout;

  const WriteCharacteristicOptions({
    this.withoutResponse = false,
    this.allowLongWrite = false,
    this.timeout = 15,
  });

  factory WriteCharacteristicOptions.fromJson(Map<String, dynamic> json) =>
      _$WriteCharacteristicOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$WriteCharacteristicOptionsToJson(this);
}

@JsonSerializable()
class NotifyCharacteristicOptions {
  final int timeout;
  final bool forceIndications;

  const NotifyCharacteristicOptions({
    this.timeout = 15,
    this.forceIndications = false,
  });

  factory NotifyCharacteristicOptions.fromJson(Map<String, dynamic> json) =>
      _$NotifyCharacteristicOptionsFromJson(json);
  Map<String, dynamic> toJson() => _$NotifyCharacteristicOptionsToJson(this);
}
