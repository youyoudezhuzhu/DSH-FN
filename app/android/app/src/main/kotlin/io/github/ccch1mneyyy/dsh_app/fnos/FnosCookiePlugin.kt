package io.github.ccch1mneyyy.dsh_app.fnos

import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 飞牛 fnOS 会话 Cookie，Android 侧（Dart: lib/fnos/fnos_auth.dart）：
 * MethodChannel `dsh_fn/fnos_cookies`。
 *
 * - `getCookie {url}` → WebView 在 [url] 下保存的完整 Cookie 头（`k=v; k2=v2`）；
 *   没有或读不到时返回 null。
 * - `setCookie {url, cookie}` → 在 [url] 下写一条 Cookie（网页版打开前注入会话）。
 * - `flushCookies` → 把 CookieManager 落盘（登录成功后，冷启动仍可用）。
 * - `clearCookies` → 清掉 WebView 的全部 Cookie（退出账号、换 fnconnect ID）。
 *
 * 登录页的 WebView 把 fnOS 会话写进 CookieManager；Dart 只读这份 Cookie，
 * 不接触账号密码。任何调用都不打印 Cookie 值。
 */
class FnosCookiePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
        // 登录页的 WebView 会写会话 Cookie：先确保 CookieManager 接受它们。
        onMain { CookieManager.getInstance().setAcceptCookie(true) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCookie" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                onMain {
                    result.success(
                        runCatching {
                            val manager = CookieManager.getInstance().apply { setAcceptCookie(true) }
                            manager.getCookie(url)?.takeIf { it.isNotEmpty() }
                        }.getOrNull()
                    )
                }
            }
            "setCookie" -> {
                val url = call.argument<String>("url")
                val cookie = call.argument<String>("cookie")
                if (url.isNullOrEmpty() || cookie.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                onMain {
                    runCatching {
                        CookieManager.getInstance().apply { setAcceptCookie(true) }.setCookie(url, cookie)
                        result.success(null)
                    }.onFailure { result.success(null) }
                }
            }
            "flushCookies" -> onMain {
                runCatching { CookieManager.getInstance().flush() }
                result.success(null)
            }
            "clearCookies" -> onMain {
                runCatching {
                    CookieManager.getInstance().apply {
                        setAcceptCookie(true)
                        removeAllCookies(null)
                        flush()
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** CookieManager 要在主线程用；MethodChannel 本就在主线程回调，这里兜底。 */
    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else main.post(block)
    }

    companion object {
        private const val CHANNEL = "dsh_fn/fnos_cookies"
    }
}
