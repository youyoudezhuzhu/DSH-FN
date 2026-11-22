# Troubleshooting

## Messages won't send, or no reply comes

Check the 飞牛 host status at the bottom of the chat list.

- The host page shows the connection phase; when it fails, check that the NAS is online, the DSH app is running and the fnconnect ID is right, then retry.
- Session expired: sign in to 飞牛 again on the host page; the app refreshes the session cookie.
- If no model is set up, **Choose model** offers to enter an API key or add a provider.

To report a problem, export a diagnostics bundle in the app: it includes the version, device, bounded connection logs and captured errors, not all system logs or a complete crash history. The app attempts to remove keys and cookies; still inspect the bundle before sharing it.

## Notifications don't arrive in the background

DSH-FN has no on-device engine; keeping it alive just means keeping the connection to the NAS:

- Android: allow DSH-FN notifications in system settings, and follow the vendor guidance to disable battery optimization and lock the app in Recents.
- After the system reclaims the app, the next launch reconnects to the NAS; interrupted commands and phone actions are not replayed.
- Turn on the alerts you want in the app's **Notifications**. Alerts may be delayed while DSH on the NAS restarts or the network is down.

## The app can chat, but headless reports MISSING_CREDENTIAL

`dsh --profile headless` starts a separate one-shot task. Its default profile disables the interactive credential store, authorization and DeepSeek account services, so it does not automatically use API keys or account sign-ins saved in the app. A working chat in the app does not mean this command has credentials configured.

The default DeepSeek official API route needs `DEEPSEEK_API_KEY`. Supply it in the process environment that launches the command, or set your own API key as `DEEPSEEK_API_KEY=...` in the launch directory's `.env` or `$DSH_HOME/.env`. These are read in order: process environment, launch directory's `.env`, then `$DSH_HOME/.env`. An exported empty variable also shadows the `.env` fallback; unset that empty variable before using a file instead. Keep real keys out of chats, issue reports and source control.

DeepSeek account sign-in and an official API key are different credentials. An account sign-in token cannot be used as `DEEPSEEK_API_KEY`. You can keep using the account in the app, or configure an API key separately for headless.

Adding the app's sign-in patch alone does not enable the services that headless disables by default. Custom profiles and remote hosts may use different configurations; follow the configuration of that host.

## The pet is gone

- Not in chats: if the pet page is set to **None**, choose a pet; if it's hidden for an hour, tap **Show now**.
- Not outside the app: check that **Show outside the app** is on and display over other apps is allowed. **When to show** defaults to **When active**, which hides the pet after 5 quiet minutes. If it was hidden for today, tap **Restore** on the pet page. It also hides while the app is in the foreground.

See [Pets](06-pets.md).

## A plugin is installed but doesn't show up

Check that the plugin is enabled, and restart DSH on the NAS if asked. A plugin's native UI needs the dsh-go bridge on that NAS; without the bridge only tool cards show. A display place may also be turned off in the plugin's details. Plugin panels without a native UI appear in the Plugins group of All features, opening in the app or as Web entries. See [Plugins](08-plugins.md).

## What the app sends

<!-- nav: commonSettings,hubPrivacy,usageStatsTitle -->
`Settings › Privacy and sharing › Send anonymous usage stats` · [Open](dshgo://open/usage-stats)

dsh-go’s own anonymous usage statistics are on by default; the switch is on the welcome screen the first time you open the app. If you updated from an earlier version, a one-time notice at the bottom of the home screen tells you, and can turn it off right there. While it's on, the app sends anonymous stats for the days before, at most once a day, and only this: app and Android version, CPU architecture, phone maker and model (such as `V2405A`, from 1.0.15), the maker's system and its version (such as OriginOS 5.0, from 1.0.15), app language, how the local engine was started, and that day's number of messages, voice inputs (speech typed into the message box, not voice calls), generations, shares and installed plugins. From 1.0.17 also: messages sent in the tavern, visits to the companion room, voice calls that connected, and the day's total input and output tokens that model replies reported (only the numbers the provider gives in its replies; channels that give none are not counted, and nothing is estimated). Devices are told apart by a random ID that changes every 90 days.

On Android, daily totals also include foreground activity, the first day of collection, reported model usage, feature outcomes, and crashes or hangs confirmed by Android. Collection is on by default; showing the notice only informs you and does not change when it starts. These reports cannot measure who is online now.

These statistics never include accounts, API keys, chats, character cards, files, prompts, host addresses or which model you use, or device identifiers such as phone number or IMEI. Turning this switch off stops the feature and model collection and deletes that unsent data; on Android, one anonymous daily-activity count with no content is still reported. Reports already received by the server cannot be withdrawn.

The old “pair a computer by QR code” scanner was removed together with the DSH Remote relay; hosts are now configured only by entering a fnconnect ID on the 飞牛 host page.

## The guide doesn't match what I see

Check the app version under **Version** in Settings and compare it with the version in the [guide index](../README.md). The app is always right.
