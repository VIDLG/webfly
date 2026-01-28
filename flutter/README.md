# WebFly (Flutter)

## Quickstart

```bash
flutter pub get
just gen-platforms
just android
```

## Notes

- Android manifests are template-driven: edit `platforms/android/AndroidManifest.*.xml` and rerun `just gen-platforms`.
- Native Diagnostics is available in-app (BLE diagnostics + in-app logs) to help debug device features.
