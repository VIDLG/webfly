package org.vidlg.webfly

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Call registerWith directly, catching Throwable (not just Exception).
        // WebF's System.loadLibrary("quickjs") throws UnsatisfiedLinkError
        // (an Error, not Exception) which escapes GeneratedPluginRegistrant's
        // catch(Exception) blocks and kills the entire registration chain.
        // WebF itself still works via FFI despite this failure.
        try {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        } catch (e: Throwable) {
            io.flutter.Log.w(
                "MainActivity",
                "GeneratedPluginRegistrant partially failed: ${e.cause?.message}"
            )
        }
        // Re-register plugins that may have been skipped due to the above failure.
        // FlutterEngine.plugins.add() is a no-op if the plugin is already registered.
        // TODO: Remove this workaround once WebF fixes the libquickjs.so issue.
        //       See: https://github.com/openwebf/webf/issues/876
        try {
            flutterEngine.plugins.add(org.vidlg.webfly_updater.WebflyUpdaterPlugin())
        } catch (e: Throwable) {
            io.flutter.Log.e("MainActivity", "Failed to register WebflyUpdaterPlugin", e)
        }
    }
}
