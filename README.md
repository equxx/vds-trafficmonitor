# TrafficMonitor VDS widget

This folder contains a small, read-only metrics endpoint and a TrafficMonitor Lua plug-in. The endpoint reports host CPU, memory, and aggregate network rates. It listens only on loopback; Caddy exposes it through HTTPS with a dedicated Basic Auth account.

The Windows side needs the 64-bit TrafficMonitor Lua plug-in installed. Download the x64 ZIP from the upstream [TrafficMonitorLuaPlugin releases](https://github.com/compilelife/TrafficMonitorLuaPlugin/releases), extract its contents into TrafficMonitor's `plugins` directory, then place `TrafficMonitor-VDS.lua` in the Lua plug-in's script directory. After deployment, copy the credentials from `credentials.txt` into `TrafficMonitor-VDS.lua` on the Windows client, then restart TrafficMonitor. Keep `credentials.txt` private and do not commit it.
