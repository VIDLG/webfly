# Screenshots Placeholder

Please add the following screenshots to this directory:

1. **launcher.png** - Main launcher page showing:
   - WebFly logo
   - URL input field with Bundle URL label
   - Advanced options (expandable)
   - Launch button
   - Recent URLs list

2. **scanner.png** - QR code scanner page showing:
   - Camera preview with scanning frame
   - Instructions

3. **webf_app.png** - A web app running in WebFly showing:
   - App bar with URL
   - Web content rendering
   - Native-like performance

4. **settings.png** - Settings dialog showing:
   - WebF Inspector toggle
   - Cache Controllers toggle
   - Clean UI with compact design

## Recommended Settings
- Image format: PNG
- Dimensions: 1080x2400 (mobile portrait) or similar
- File size: < 500KB per image
- Background: Include device frame if possible

You can capture screenshots using:
```bash
# On connected Android device
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

Or use Flutter DevTools screenshot feature.
