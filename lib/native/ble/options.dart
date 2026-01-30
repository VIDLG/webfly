import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'serialization.dart';

class ScanOptions {
  final List<Guid> withServices;
  final List<String> withRemoteIds;
  final List<String> withNames;
  final List<String> withKeywords;
  final List<MsdFilter> withMsd;
  final List<ServiceDataFilter> withServiceData;
  final Duration? timeout;
  final Duration? removeIfGone;
  final bool continuousUpdates;
  final int continuousDivisor;
  final bool oneByOne;
  final bool androidLegacy;
  final AndroidScanMode androidScanMode;
  final bool androidUsesFineLocation;
  final bool androidCheckLocationServices;
  final List<Guid> webOptionalServices;

  // Defaults
  // No need to redeclare defaults in fromMap, as we use null checks + constructor
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
  
  // Create an empty instance once to reuse defaults
  static const _defaults = ScanOptions();

  factory ScanOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ScanOptions();

    return ScanOptions(
      withServices: readList(map['withServices'], (x) => Guid(x as String)),
      withRemoteIds: readList(map['withRemoteIds']),
      withNames: readList(map['withNames']),
      withKeywords: readList(map['withKeywords']),
      withMsd: readList(map['withMsd'], _parseMsd),
      withServiceData: readList(map['withServiceData'], _parseServiceData),
      
      timeout: readDuration(map['timeout']),
      removeIfGone: readDuration(map['removeIfGone']),
      
      continuousUpdates: map['continuousUpdates'] as bool? ?? _defaults.continuousUpdates,
      continuousDivisor: map['continuousDivisor'] as int? ?? _defaults.continuousDivisor,
      oneByOne: map['oneByOne'] as bool? ?? _defaults.oneByOne,
      androidLegacy: map['androidLegacy'] as bool? ?? _defaults.androidLegacy,
      
      // Special Parser for ScanMode
      androidScanMode: _parseAndroidScanMode(map['androidScanMode']) ?? _defaults.androidScanMode,
          
      androidUsesFineLocation: map['androidUsesFineLocation'] as bool? ?? _defaults.androidUsesFineLocation,
      androidCheckLocationServices: map['androidCheckLocationServices'] as bool? ?? _defaults.androidCheckLocationServices,
      
      webOptionalServices: readList(map['webOptionalServices'], (x) => Guid(x as String)),
    );
  }

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

class SetOptions {
  final bool showPowerAlert;
  final bool restoreState;

  const SetOptions({
    this.showPowerAlert = true,
    this.restoreState = false,
  });

  static const _defaults = SetOptions();

  factory SetOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SetOptions();
    return SetOptions(
      showPowerAlert: map['showPowerAlert'] as bool? ?? _defaults.showPowerAlert,
      restoreState: map['restoreState'] as bool? ?? _defaults.restoreState,
    );
  }
}

class ConnectOptions {
  final Duration timeout;
  final int mtu;
  final bool autoConnect;
  final License license;

  const ConnectOptions({
    this.timeout = const Duration(seconds: 35),
    this.mtu = 512,
    this.autoConnect = false,
    this.license = License.free,
  });

  static const _defaults = ConnectOptions();

  factory ConnectOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ConnectOptions();

    return ConnectOptions(
      timeout: readDuration(map['timeout']) ?? _defaults.timeout,
      mtu: map['mtu'] is int ? map['mtu'] : _defaults.mtu,
      autoConnect: map['autoConnect'] is bool ? map['autoConnect'] : _defaults.autoConnect,
      license: map['license'] == 'commercial' ? License.commercial : _defaults.license,
    );
  }
}


class DisconnectOptions {
  final int timeout;
  final bool queue;
  final int androidDelay;

  const DisconnectOptions({
    this.timeout = 35,
    this.queue = true,
    this.androidDelay = 2000,
  });

  static const _defaults = DisconnectOptions();

  factory DisconnectOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DisconnectOptions();
    return DisconnectOptions(
      timeout: map['timeout'] as int? ?? _defaults.timeout,
      queue: map['queue'] as bool? ?? _defaults.queue,
      androidDelay: map['androidDelay'] as int? ?? _defaults.androidDelay,
    );
  }
}

class DiscoverServicesOptions {
  final bool subscribeToServicesChanged;
  final int timeout;

  const DiscoverServicesOptions({
    this.subscribeToServicesChanged = false,
    this.timeout = 15,
  });

  static const _defaults = DiscoverServicesOptions();

  factory DiscoverServicesOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DiscoverServicesOptions();
    return DiscoverServicesOptions(
      subscribeToServicesChanged: map['subscribeToServicesChanged'] as bool? ?? _defaults.subscribeToServicesChanged,
      timeout: map['timeout'] as int? ?? _defaults.timeout,
    );
  }
}

// ----------------------------------------------------------------------------
// Characteristic Options
// ----------------------------------------------------------------------------

class ReadCharacteristicOptions {
  final int timeout;

  const ReadCharacteristicOptions({
    this.timeout = 15,
  });

  static const _defaults = ReadCharacteristicOptions();

  factory ReadCharacteristicOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ReadCharacteristicOptions();
    return ReadCharacteristicOptions(
      timeout: map['timeout'] as int? ?? _defaults.timeout,
    );
  }
}

class WriteCharacteristicOptions {
  final bool withoutResponse;
  final bool allowLongWrite;
  final int timeout;

  const WriteCharacteristicOptions({
    this.withoutResponse = false,
    this.allowLongWrite = false,
    this.timeout = 15,
  });

  static const _defaults = WriteCharacteristicOptions();

  factory WriteCharacteristicOptions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const WriteCharacteristicOptions();
    return WriteCharacteristicOptions(
      withoutResponse: map['withoutResponse'] as bool? ?? _defaults.withoutResponse,
      allowLongWrite: map['allowLongWrite'] as bool? ?? _defaults.allowLongWrite,
      timeout: map['timeout'] as int? ?? _defaults.timeout,
    );
  }
}

class NotifyCharacteristicOptions {
    final int timeout;
    final bool forceIndications;

    const NotifyCharacteristicOptions({
        this.timeout = 15,
        this.forceIndications = false,
    });

    static const _defaults = NotifyCharacteristicOptions();

    factory NotifyCharacteristicOptions.fromMap(Map<String, dynamic>? map) {
        if (map == null) return const NotifyCharacteristicOptions();
        return NotifyCharacteristicOptions(
            timeout: map['timeout'] as int? ?? _defaults.timeout,
            forceIndications: map['forceIndications'] as bool? ?? _defaults.forceIndications,
        );
    }
}


// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

MsdFilter _parseMsd(dynamic item) {
    if (item is! Map) return MsdFilter(0, data: []);
    return MsdFilter(
      item['manufacturerId'] as int,
      data: readList<int>(item['data']),
    );
}

ServiceDataFilter _parseServiceData(dynamic item) {
    if (item is! Map) return ServiceDataFilter(Guid.empty(), data: []);
    return ServiceDataFilter(
      Guid(item['serviceUuid'] as String),
      data: readList<int>(item['data']),
    );
}

AndroidScanMode? _parseAndroidScanMode(dynamic value) {
    if (value is! int) return null;
    const modes = [
      AndroidScanMode.opportunistic,
      AndroidScanMode.lowPower,
      AndroidScanMode.balanced,
      AndroidScanMode.lowLatency,
    ];
    for (var m in modes) {
      if (m.value == value) return m;
    }
    return null;
}
