# TrafficMonitor VDS göstergesi

Bu proje, VDS sunucusunun işlemci, bellek ve ağ trafiği bilgilerini TrafficMonitor'da gösterir. Sunucu tarafındaki servis yalnızca yerel bağlantıları dinler. Caddy, özel Basic Auth hesabı kullanarak ölçüm uç noktasını HTTPS üzerinden erişime açar.

## Kurulum

1. [TrafficMonitorLuaPlugin sürümlerinden](https://github.com/compilelife/TrafficMonitorLuaPlugin/releases) x64 ZIP dosyasını indirin ve içeriğini TrafficMonitor'un `plugins` klasörüne çıkarın.
2. `TrafficMonitor-VDS.lua` dosyasını Lua eklentisinin script klasörüne kopyalayın.
3. VDS üzerinde `deploy.sh` betiğini çalıştırarak sunucu servisini kurun. Betik, giriş bilgilerini `credentials.txt` dosyasına kaydeder.
4. `credentials.txt` içindeki kullanıcı adı ve parolayı Windows'taki `TrafficMonitor-VDS.lua` dosyasına yazın.
5. TrafficMonitor'u yeniden başlatın.

`credentials.txt` dosyası özeldir; Git'e veya GitHub'a yüklemeyin. Trafik hızları KB/s cinsinden gösterilir.
