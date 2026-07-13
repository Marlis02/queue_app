#!/usr/bin/env python3
"""
Проверка UDP-канала табло очереди (порт 8088).

Postman UDP не умеет — используйте этот скрипт.

Запуск:
  python3 tools/udp_test.py discover              # найти табло в сети (broadcast)
  python3 tools/udp_test.py scan                  # найти табло unicast-обходом подсети
  python3 tools/udp_test.py send                  # послать данные broadcast'ом (всем ТВ)
  python3 tools/udp_test.py send 192.168.0.181    # послать данные на конкретный IP

Что проверяет:
  discover — шлёт QUEUE_DISCOVER_V1 broadcast'ом, печатает ответы табло (их IP).
  scan     — шлёт QUEUE_DISCOVER_V1 на каждый адрес подсети по очереди (unicast).
             Работает там, где broadcast режется роутером или Wi-Fi-фильтром
             телефона; именно так стоит искать табло из POS.
  send     — шлёт QUEUE_DATA_V1 с тестовой очередью; на экране появятся заказы,
             а заказ с "selected": true озвучится (проиграет NN.mp3).
"""
import socket
import sys
import json

PORT = 8088
DISCOVER = b"QUEUE_DISCOVER_V1"
DATA_PREFIX = "QUEUE_DATA_V1 "


def local_ip():
    """Свой IP в локальной сети (через маршрут до 8.8.8.8, пакеты не шлются)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except OSError:
        return None
    finally:
        s.close()


def subnet_broadcast():
    """Broadcast-адрес текущей подсети (напр. 192.168.0.255).

    Directed broadcast подсети доходит через Wi-Fi роутеры надёжнее,
    чем глобальный 255.255.255.255 (его роутеры часто режут).
    """
    ip = local_ip()
    parts = ip.split(".") if ip else []
    return ".".join(parts[:3] + ["255"]) if len(parts) == 4 else "255.255.255.255"

# Тестовая очередь: 2 готовятся, 1 готов и выбран (озвучится №7).
SAMPLE = {
    "seq": 6,  # увеличивайте при каждой новой отправке, иначе датаграмма отбросится как устаревшая
    "queues": {
        "cooking": [
        
            {"id": 13, "time": "12.07.2026 13:06", "info": "Бешбармак",   "counter": "7"},
            {"id": 15, "time": "12.07.2026 13:07", "info": "Норин",       "counter": "35"},
            {"id": 17, "time": "12.07.2026 13:08", "info": "Хоним",       "counter": "6"},
            {"id": 19, "time": "12.07.2026 13:09", "info": "Димляма",     "counter": "38"},
            {"id": 21, "time": "12.07.2026 13:10", "info": "Казан-кебаб", "counter": "28"},
            {"id": 23, "time": "12.07.2026 13:11", "info": "Чучвара",     "counter": "3"},
            {"id": 25, "time": "12.07.2026 13:12", "info": "Мастава",     "counter": "2"},
            {"id": 27, "time": "12.07.2026 13:13", "info": "Ковурма",     "counter": "6"},
            {"id": 29, "time": "12.07.2026 13:14", "info": "Дамлама",     "counter": "14"},
            {"id": 31, "time": "12.07.2026 13:15", "info": "Тандыр-гушт", "counter": "15"},
            {"id": 33, "time": "12.07.2026 13:16", "info": "Нарханги",    "counter": "33"},
            {"id": 35, "time": "12.07.2026 13:17", "info": "Кабоб",       "counter": "39"},
            {"id": 37, "time": "12.07.2026 13:18", "info": "Мошкичири",   "counter": "2"},
            {"id": 39, "time": "12.07.2026 13:19", "info": "Хасип",       "counter": "36"},
        ],
        "done": [
            {"id": 2,  "time": "12.07.2026 12:30", "info": "Плов",        "counter": "13", "selected": True}
        ]
    },
}

def discover(target=None):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    s.settimeout(3)
    bcast = target or subnet_broadcast()
    s.sendto(DISCOVER, (bcast, PORT))
    print(f"Отправлен discovery на {bcast}:{PORT}, жду ответы 3с...")
    found = 0
    while True:
        try:
            data, addr = s.recvfrom(2048)
            print(f"  Табло {addr[0]}: {data.decode(errors='replace')}")
            found += 1
        except socket.timeout:
            break
    print(f"Найдено табло: {found}")


def scan():
    """Unicast-обход подсети: discovery на каждый адрес x.x.x.1-254.

    Не зависит от broadcast'а — роутеры часто не ретранслируют его между
    Wi-Fi-клиентами, а Wi-Fi-драйверы телефонов фильтруют. Unicast доходит
    всегда, если устройства вообще видят друг друга (ping работает).
    """
    me = local_ip()
    if not me:
        print("Не удалось определить свой IP — нет сети?")
        return
    prefix = ".".join(me.split(".")[:3])
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(3)
    print(f"Опрашиваю {prefix}.1-254:{PORT} (я {me}), жду ответы 3с...")
    for host in range(1, 255):
        ip = f"{prefix}.{host}"
        if ip != me:
            s.sendto(DISCOVER, (ip, PORT))
    found = set()
    while True:
        try:
            data, addr = s.recvfrom(2048)
            if addr[0] not in found:
                print(f"  Табло {addr[0]}: {data.decode(errors='replace')}")
                found.add(addr[0])
        except socket.timeout:
            break
    print(f"Найдено табло: {len(found)}")


def send(target):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    payload = DATA_PREFIX + json.dumps(SAMPLE, ensure_ascii=False)
    raw = payload.encode("utf-8")
    s.sendto(raw, (target, PORT))
    print(f"Отправлено {len(raw)} байт на {target}:{PORT}")
    if len(raw) > 1400:
        print("  ВНИМАНИЕ: >1400 байт — датаграмма может фрагментироваться и потеряться, используйте HTTP (python3 tools/udp_test.py http <IP>)")


def http(target):
    """Отправка по HTTP POST — надёжно, без ограничения размера."""
    import urllib.request
    body = json.dumps(SAMPLE, ensure_ascii=False).encode("utf-8")
    url = f"http://{target}:{PORT}/"
    req = urllib.request.Request(url, data=body, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            print(f"HTTP {resp.status}: {resp.read().decode(errors='replace')}  ({len(body)} байт → {url})")
    except Exception as e:
        print(f"Ошибка HTTP на {url}: {e}")
        print("  Проверь: телефон и комп в одной Wi-Fi, IP правильный (смотри в настройках приложения).")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "discover"
    if cmd == "discover":
        discover(sys.argv[2] if len(sys.argv) > 2 else None)
    elif cmd == "scan":
        scan()
    elif cmd == "send":
        target = sys.argv[2] if len(sys.argv) > 2 else subnet_broadcast()
        send(target)
    elif cmd == "http":
        if len(sys.argv) < 3:
            print("Укажи IP телефона: python3 tools/udp_test.py http 192.168.0.XX")
        else:
            http(sys.argv[2])
    else:
        print(__doc__)
