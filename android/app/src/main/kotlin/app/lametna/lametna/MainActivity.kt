package app.lametna.lametna

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * لمّتنا / Lametna
 *
 * قناة خفيفة لفتح «ورقة المشاركة» الأصلية في أندرويد (واتساب، تيليجرام،
 * الرسائل، أي تطبيق) بدون إضافة أي حزمة خارجية.
 */
class MainActivity : FlutterActivity() {

    private val shareChannel = "app.lametna/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> {
                        val text = call.argument<String>("text").orEmpty()
                        val title = call.argument<String>("title")
                        if (text.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, text)
                                if (!title.isNullOrEmpty()) {
                                    putExtra(Intent.EXTRA_SUBJECT, title)
                                }
                            }
                            startActivity(Intent.createChooser(send, title))
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
