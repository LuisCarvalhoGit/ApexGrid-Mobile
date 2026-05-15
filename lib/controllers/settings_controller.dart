import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final bool highFrequency;
  final bool autoCalibrate;
  final bool offlineMaps;
  final bool isMetric;

  AppSettings({
    this.highFrequency = true,
    this.autoCalibrate = false,
    this.offlineMaps = true,
    this.isMetric = true, // true = km/h, false = mph
  });

  AppSettings copyWith({bool? highFrequency, bool? autoCalibrate, bool? offlineMaps, bool? isMetric}) {
    return AppSettings(
      highFrequency: highFrequency ?? this.highFrequency,
      autoCalibrate: autoCalibrate ?? this.autoCalibrate,
      offlineMaps: offlineMaps ?? this.offlineMaps,
      isMetric: isMetric ?? this.isMetric,
    );
  }
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return AppSettings(); // Inicia com as definições padrão
  }

  void toggleHighFreq(bool val) => state = state.copyWith(highFrequency: val);
  void toggleAutoCalibrate(bool val) => state = state.copyWith(autoCalibrate: val);
  void toggleOfflineMaps(bool val) => state = state.copyWith(offlineMaps: val);
  void toggleMetric() => state = state.copyWith(isMetric: !state.isMetric);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(() {
  return SettingsController();
});