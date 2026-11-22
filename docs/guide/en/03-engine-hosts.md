# Connecting to a 飞牛 fnOS host

DSH-FN connects to exactly one host: the DSH running on your 飞牛 (fnOS) NAS. The phone is only a client; no engine runs on the phone, and there is no SSH or relay transport.

## First connection

1. Install and enable DSH (DeepSeek Harness) from the App Center on the NAS.
2. Open the app and enter the fnOS fnconnect ID on the host page (e.g. `mynas`; no `https://` or `.fnos.net` needed).
3. The app opens the fnOS login page. Sign in once in the web view; the app captures the session and connects to DSH.
4. Once connected the host page shows “飞牛 · <ID> connected”; chats, workspaces and plugins all belong to that NAS.

The ID alone is enough. Full addresses such as `mynas.fnos.net` or an `https://` URL are also accepted and resolve to the same host.

## Connection states

The host page shows the connection phase and the failure reason:

- Connecting: probing the DSH gateway or establishing the session.
- Connected: you can chat; HTTP/WebSocket traffic goes through the fnOS gateway.
- Signed out: sign in again; the app reopens the fnOS login page and refreshes the session.
- Unreachable: check that the NAS is online, the DSH app is running and the fnconnect ID is right, then retry.

## Switching hosts or signing out

- Change the fnconnect ID: enter a new ID on the host page; the app clears the old session and signs in again.
- Sign out: clears the saved fnOS session cookie on the phone; you sign in again next time.

## Network and environment

- The phone must be able to reach `https://<ID>.fnos.net`; the fnOS gateway forwards requests to DSH on the NAS.
- VPNs, proxies or corporate networks that block that domain look like connection timeouts; switch networks and retry.
- The DSH app on the NAS must keep running; the phone cannot wake a powered-off or sleeping NAS.
- The session cookie is kept only in the phone's secure storage, for the NAS you configured; never share it.

## Differences from earlier versions

The old dsh-go could run DSH on the phone (local engine), connect over SSH, and use the DSH Remote relay/direct transport, on Android, HarmonyOS and iOS. Those paths are gone in DSH-FN: only a remote 飞牛 fnOS host remains. Saved hosts from an older version fall back to the fnOS host on upgrade; enter the fnconnect ID again.
