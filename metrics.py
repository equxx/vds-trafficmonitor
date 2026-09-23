#!/usr/bin/env python3
"""Small localhost-only VDS metrics endpoint for the TrafficMonitor widget."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import time


def read_cpu():
    with open("/proc/stat", encoding="ascii") as f:
        fields = f.readline().split()[1:]
    values = [int(value) for value in fields]
    idle = values[3] + (values[4] if len(values) > 4 else 0)
    return sum(values), idle


def read_memory():
    values = {}
    with open("/proc/meminfo", encoding="ascii") as f:
        for line in f:
            key, value = line.split(":", 1)
            if key in ("MemTotal", "MemAvailable"):
                values[key] = int(value.strip().split()[0])
    total = values["MemTotal"]
    used = total - values["MemAvailable"]
    return used * 100.0 / total if total else 0.0


def read_network():
    rx = tx = 0
    interface = None
    with open("/proc/net/route", encoding="ascii") as f:
        next(f)
        for line in f:
            fields = line.split()
            if len(fields) > 2 and fields[1] == "00000000":
                interface = fields[0]
                break
    with open("/proc/net/dev", encoding="ascii") as f:
        for line in f.readlines()[2:]:
            name, counters = line.split(":", 1)
            if interface and name.strip() != interface:
                continue
            if name.strip() == "lo":
                continue
            data = [int(value) for value in counters.split()]
            rx += data[0]
            tx += data[8]
    return rx, tx


def sample(previous):
    now = time.monotonic()
    cpu_total, cpu_idle = read_cpu()
    rx, tx = read_network()
    memory = read_memory()
    if previous is None:
        return (cpu_total, cpu_idle, rx, tx, now), 0.0, memory, 0.0, 0.0
    old_total, old_idle, old_rx, old_tx, old_time = previous
    elapsed = max(now - old_time, 0.001)
    total_delta = max(cpu_total - old_total, 0)
    idle_delta = max(cpu_idle - old_idle, 0)
    cpu = 100.0 * (total_delta - idle_delta) / total_delta if total_delta else 0.0
    # /proc/net/dev counters are bytes; report binary kilobytes per second.
    rx_kbs = max(rx - old_rx, 0) / elapsed / 1024
    tx_kbs = max(tx - old_tx, 0) / elapsed / 1024
    return (cpu_total, cpu_idle, rx, tx, now), cpu, memory, rx_kbs, tx_kbs


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_error(404)
            return
        snapshot, cpu, memory, rx, tx = sample(getattr(self.server, "snapshot", None))
        self.server.snapshot = snapshot
        body = f"VDS CPU {cpu:.0f}% | RAM {memory:.0f}% | RX {rx:.2f} KB/s | TX {tx:.2f} KB/s\n".encode("ascii")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 61235), Handler).serve_forever()
