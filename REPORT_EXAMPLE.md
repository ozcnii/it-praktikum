# Пример отчета команды 22

## Состав команды и распределение метрик

| Студент | Username | Метрика | Описание |
|---------|----------|---------|----------|
| Студент 1 | user1 | CPU Load | Загрузка процессора (1 минута) |
| Студент 2 | user2 | RAM Usage | Использование оперативной памяти (%) |
| Студент 3 | user3 | Disk Availability | Доступность диска (%) |
| Студент 4 | user4 | Network Connections | Количество установленных сетевых соединений |
| Студент 5 | user5 | Processes | Количество запущенных процессов |

## Результаты проверки сбора метрик

### Проверка через zabbix_get

```bash
# CPU Load (user1)
$ zabbix_get -s 192.168.1.10 -k user1.cpu
0.45

# RAM Usage (user2)
$ zabbix_get -s 192.168.1.11 -k user2.ram
67.23

# Disk Availability (user3)
$ zabbix_get -s 192.168.1.12 -k user3.disk
45

# Network Connections (user4)
$ zabbix_get -s 192.168.1.13 -k user4.network
23

# Processes (user5)
$ zabbix_get -s 192.168.1.14 -k user5.processes
156
```

### Проверка логов Zabbix Agent

Все агенты успешно запущены и собирают данные:

```bash
$ sudo systemctl status zabbix-agent
● zabbix-agent.service - Zabbix Agent
   Loaded: loaded (/usr/lib/systemd/system/zabbix-agent.service; enabled)
   Active: active (running) since Mon 2024-01-15 10:00:00 UTC
```

## Данные в PostgreSQL

### Структура таблиц

Все таблицы созданы успешно:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%_zabbix';
```

Результат:
- user1_zabbix
- user2_zabbix
- user3_zabbix
- user4_zabbix
- user5_zabbix

### Пример данных из таблицы user1_zabbix

```
 id |      timestamp       | metric_type | metric_value |        created_at        
----+----------------------+-------------+--------------+--------------------------
  1 | 2024-01-15 10:00:00  | cpu         | 0.45         | 2024-01-15 10:00:00
  2 | 2024-01-15 10:05:00  | cpu         | 0.52         | 2024-01-15 10:05:00
  3 | 2024-01-15 10:10:00  | cpu         | 0.38         | 2024-01-15 10:10:00
```

## Автоматизация через Ansible

### Выполнение playbook

```bash
$ ansible-playbook playbook.yml

PLAY [Deploy Zabbix Agent and configure metrics] ******************************

TASK [zabbix_agent : Create team22 directory] *********************************
changed: [student1]
changed: [student2]
changed: [student3]
changed: [student4]
changed: [student5]

TASK [zabbix_agent : Install Zabbix Agent] ************************************
changed: [student1]
changed: [student2]
changed: [student3]
changed: [student4]
changed: [student5]

TASK [zabbix_agent : Copy Zabbix Agent configuration] ************************
changed: [student1]
changed: [student2]
changed: [student3]
changed: [student4]
changed: [student5]

...

PLAY RECAP *********************************************************************
student1                  : ok=12   changed=10   unreachable=0    failed=0
student2                  : ok=12   changed=10   unreachable=0    failed=0
student3                  : ok=12   changed=10   unreachable=0    failed=0
student4                  : ok=12   changed=10   unreachable=0    failed=0
student5                  : ok=12   changed=10   unreachable=0    failed=0
```

## Файлы с метриками

Каждый студент сохранил результаты в текстовый файл:

```bash
$ cat /srv/team22/user1_zabbix/metrics_output.txt
[2024-01-15 10:00:00] cpu: 0.45
[2024-01-15 10:05:00] cpu: 0.52
[2024-01-15 10:10:00] cpu: 0.38
[2024-01-15 10:15:00] cpu: 0.41
[2024-01-15 10:20:00] cpu: 0.39
```

## Итоговый набор метрик

Команда успешно развернула полный набор метрик для мониторинга системы:

✓ **CPU Load** - мониторинг загрузки процессора
✓ **RAM Usage** - мониторинг использования памяти
✓ **Disk Availability** - мониторинг доступности дискового пространства
✓ **Network Connections** - мониторинг сетевых соединений
✓ **Processes** - мониторинг количества процессов

Все метрики собираются автоматически каждые 5 минут и сохраняются в PostgreSQL для дальнейшего анализа.

## Выводы

1. ✅ Zabbix Agent успешно установлен и настроен на всех серверах
2. ✅ Каждая метрика собирается корректно
3. ✅ Данные сохраняются в PostgreSQL
4. ✅ Автоматизация через Ansible работает корректно
5. ✅ Полный набор метрик позволяет мониторить состояние системы

