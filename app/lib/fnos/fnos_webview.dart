/// 飞牛 fnOS 登录页：WebView 里登录一次，抓到会话 Cookie 并验证 DSH 可访问后，
/// 把 Cookie 串交给调用方。
///
/// 不依赖 l10n 生成文件：本模块是新增的独立入口，直接写中文常量。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'fnconnect.dart';
import 'fnos_auth.dart';

/// 读 Cookie 的间隔。
const _cookiePollInterval = Duration(seconds: 1);

/// 整个登录流程的上限。
const _loginTimeout = Duration(minutes: 5);

/// 飞牛 fnOS 账号登录页。
///
/// 打开 [target.origin]，每秒读一次 WebView 的 Cookie；一旦拿到 Cookie 就用
/// [probeFnosDsh] 验证，验证通过时先调用 [onLoggedIn]，再带着 Cookie 串 pop。
/// 用户返回、5 分钟超时都只 pop 不带值。
class FnosLoginPage extends StatefulWidget {
  const FnosLoginPage({super.key, required this.target, required this.onLoggedIn});

  /// 要登录的飞牛 fnconnect 目标。
  final FnConnectTarget target;

  /// 验证通过后的回调（可异步）；页面随后 pop，并把 Cookie 串作为路由结果返回。
  final FutureOr<void> Function(String cookieHeader) onLoggedIn;

  /// 以路由方式打开登录页：成功返回 Cookie 串，用户放弃或超时返回 null。
  static Future<String?> show(BuildContext context, {required FnConnectTarget target}) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => FnosLoginPage(target: target, onLoggedIn: (_) {}),
      ),
    );
  }

  @override
  State<FnosLoginPage> createState() => _FnosLoginPageState();
}

class _FnosLoginPageState extends State<FnosLoginPage> {
  WebViewController? _controller;
  Timer? _poll;
  Timer? _deadline;

  /// 同一时刻只跑一个探测。
  bool _probing = false;

  /// 已经拿到可用 Cookie，不再轮询、只 pop 一次。
  bool _finished = false;

  /// 超过 [_loginTimeout]，等用户点「重试」。
  bool _timedOut = false;

  bool _loading = true;
  String _status = '正在打开飞牛登录页…';
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    _startTimers();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _startTimers() {
    _poll?.cancel();
    _deadline?.cancel();
    _poll = Timer.periodic(_cookiePollInterval, (_) => unawaited(_checkCookie()));
    _deadline = Timer(_loginTimeout, _onTimeout);
  }

  void _stopTimers() {
    _poll?.cancel();
    _deadline?.cancel();
    _poll = null;
    _deadline = null;
  }

  /// 建 WebView 并打开飞牛登录入口。
  Future<void> _open() async {
    try {
      final controller = WebViewController();
      _controller = controller;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            _set(() => _loading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            _set(() {
              _loading = false;
              if (_status == '正在打开飞牛登录页…' || _status == '正在重新打开飞牛登录页…') {
                _status = '登录一次即可，之后自动连接';
              }
            });
          },
          onWebResourceError: (error) {
            // 主文档失败才提示；子资源（图标、统计）失败不影响登录。
            if (!mounted || error.isForMainFrame != true) return;
            _set(() {
              _loading = false;
              _error = '登录页加载失败，请检查网络后重试';
            });
          },
        ),
      );
      if (!mounted) return;
      await controller.loadRequest(widget.target.origin);
    } catch (error) {
      if (!mounted) return;
      _set(() {
        _loading = false;
        _error = '无法打开飞牛登录页（WebView 初始化失败）';
      });
    }
  }

  /// 每秒一次：读到 Cookie 就验证，验证过了就收工。
  Future<void> _checkCookie() async {
    if (_finished || _probing || _timedOut || !mounted) return;
    _probing = true;
    try {
      final cookie = await readFnosCookies(widget.target.origin.toString());
      if (cookie == null || _finished || _timedOut || !mounted) return;
      _setStatus('已拿到飞牛登录凭据，正在验证 DSH 连接…');
      // Cookie 由登录页的 WebView 写入 CookieManager；落盘后冷启动与网页版都还在。
      await writeFnosCookies(widget.target.origin.toString(), cookie);
      final probe = await probeFnosDsh(target: widget.target, cookieHeader: cookie);
      if (_finished || _timedOut || !mounted) return;
      if (probe.authenticated) {
        await _finish(cookie);
      } else {
        // Cookie 可能刚写入、网关会话还没生效：显示原因但继续等。
        _setStatus(probe.detail ?? 'DSH 验证未通过，请确认已登录飞牛账号');
      }
    } finally {
      _probing = false;
    }
  }

  /// 回调调用方，然后带着 Cookie 串 pop。
  Future<void> _finish(String cookie) async {
    if (_finished) return;
    _finished = true;
    _stopTimers();
    try {
      await widget.onLoggedIn(cookie);
    } catch (error) {
      // 保存失败不阻止把 Cookie 交回上一页；只记类型，绝不打印 Cookie。
      debugPrint('[fnos] onLoggedIn failed: ${error.runtimeType}');
    }
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(cookie);
    } else {
      _set(() => _status = '已连接飞牛 fnOS');
    }
  }

  void _onTimeout() {
    if (_finished) return;
    _timedOut = true;
    _poll?.cancel();
    _poll = null;
    _deadline = null;
    _set(() => _error = '登录超时（5 分钟）。请检查网络后点「重试」。');
  }

  void _retry() {
    _set(() {
      _timedOut = false;
      _error = null;
      _loading = true;
      _status = '正在重新打开飞牛登录页…';
    });
    final controller = _controller;
    if (controller != null) {
      unawaited(controller.reload().catchError((Object _) {}));
    } else {
      unawaited(_open());
    }
    _startTimers();
  }

  void _set(VoidCallback changes) {
    if (!mounted) return;
    setState(changes);
  }

  void _setStatus(String status) {
    if (!mounted || _status == status) return;
    _set(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('登录飞牛 fnOS')),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          _header(theme),
          if (error != null) _errorBar(theme, error),
          Expanded(
            child: controller == null
                ? Center(child: Text(error == null ? '正在初始化 WebView…' : '请点「重试」重新打开登录页'))
                : WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('登录一次即可，之后自动连接', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_status, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _errorBar(ThemeData theme, String error) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
          ),
          TextButton(onPressed: _retry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// 自动登录：用保存在本机安全存储里的飞牛账号密码，在一个隐藏 WebView 里
/// 自动填表登录，刷新会话 Cookie。
///
/// - 打开 [target.origin]（fnOS 登录页），每 2 秒尝试一次自动填表（页面刚
///   加载时输入框可能还没渲染），最多 3 次；
/// - 每秒读 Cookie 并用 [probeFnosDsh] 验证，通过即回调；
/// - 45 秒内没成功（密码改了、需要验证码、页面结构变化）回调失败，由调用方
///   退回手动登录页；密码不会出现在任何日志或界面里。
class FnosAutoLoginPage extends StatefulWidget {
  const FnosAutoLoginPage({
    super.key,
    required this.target,
    required this.credentials,
    required this.onFinished,
  });

  final FnConnectTarget target;
  final FnosCredentials credentials;

  /// 成功给 Cookie 串，失败给中文原因（都不含密码）。
  final void Function(String? cookieHeader, String? error) onFinished;

  @override
  State<FnosAutoLoginPage> createState() => _FnosAutoLoginPageState();
}

const _autoLoginTimeout = Duration(seconds: 45);
const _autoFillRetry = Duration(seconds: 2);

class _FnosAutoLoginPageState extends State<FnosAutoLoginPage> {
  WebViewController? _controller;
  Timer? _poll;
  Timer? _deadline;
  Timer? _fillTimer;
  int _submits = 0;
  bool _finished = false;
  bool _probing = false;
  String _status = '正在自动登录飞牛…';

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    _poll = Timer.periodic(_cookiePollInterval, (_) => unawaited(_checkCookie()));
    _deadline = Timer(_autoLoginTimeout, () => _finish(null, '自动登录超时：请在登录页手动登录一次'));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _deadline?.cancel();
    _fillTimer?.cancel();
    super.dispose();
  }

  void _finish(String? cookie, String? error) {
    if (_finished) return;
    _finished = true;
    _poll?.cancel();
    _deadline?.cancel();
    _fillTimer?.cancel();
    if (mounted) widget.onFinished(cookie, error);
  }

  Future<void> _open() async {
    try {
      final controller = WebViewController();
      if (mounted) setState(() => _controller = controller);
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted || _finished) return;
            unawaited(_fillForm());
          },
        ),
      );
      await controller.loadRequest(widget.target.origin);
      _fillTimer = Timer.periodic(_autoFillRetry, (_) => unawaited(_fillForm()));
    } catch (_) {
      _finish(null, '无法打开飞牛登录页（WebView 初始化失败）');
    }
  }

  /// 把账号密码填进登录表单并提交。只在表单渲染出来后执行。
  Future<void> _fillForm() async {
    final controller = _controller;
    if (controller == null || _finished || _submits >= 3) return;
    final user = jsonEncode(widget.credentials.username);
    final pass = jsonEncode(widget.credentials.password);
    final js = '''
(function() {
  const user = $user, pass = $pass;
  const set = (el, v) => {
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
    setter.call(el, v);
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
  };
  const password = document.querySelector('input[type=password]');
  const visible = [...document.querySelectorAll('input')].filter((el) => {
    const type = (el.getAttribute('type') || 'text').toLowerCase();
    return (type === 'text' || type === 'email' || type === 'tel') && el.offsetParent !== null;
  });
  if (!password || visible.length === 0) return 'no-form';
  set(visible[0], user);
  set(password, pass);
  const button = [...document.querySelectorAll('button, input[type=submit]')].find((el) =>
    /登录|登 录|sign\\s*in|log\\s*in/i.test((el.textContent || el.value || '').trim()));
  if (button) { button.click(); return 'submitted'; }
  const form = password.closest('form');
  if (form) { if (form.requestSubmit) form.requestSubmit(); else form.submit(); return 'submitted'; }
  return 'no-button';
})();
''';
    try {
      final result = await controller.runJavaScriptReturningResult(js);
      final text = '$result';
      if (text.contains('submitted')) {
        _submits++;
        _status = '正在登录飞牛…';
      }
    } catch (_) {
      // 页面还没就绪：下一次重试。
    }
  }

  Future<void> _checkCookie() async {
    if (_finished || _probing) return;
    final cookie = await readFnosCookies(widget.target.origin.toString());
    if (cookie == null || cookie.isEmpty) return;
    _probing = true;
    try {
      final probe = await probeFnosDsh(target: widget.target, cookieHeader: cookie);
      if (!mounted || _finished) return;
      if (probe.authenticated) {
        await writeFnosCookies(widget.target.origin.toString(), cookie);
        _finish(cookie, null);
      } else {
        _status = probe.detail ?? '自动登录没有通过网关验证';
      }
    } finally {
      _probing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // WebView 必须在树上才会真正加载页面；放在全屏底层、被下面的不透明
          // 遮罩盖住，用户只看到进度提示。
          if (controller != null)
            Positioned.fill(
              child: IgnorePointer(child: WebViewWidget(controller: controller)),
            ),
          Positioned.fill(
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4)),
                    const SizedBox(height: 16),
                    Text(_status),
                    const SizedBox(height: 8),
                    Text(
                      '已保存飞牛账号，正在自动重新登录；不需要的话可在设置里关闭',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
