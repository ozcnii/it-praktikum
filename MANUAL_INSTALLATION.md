# Ручная установка (Manual Installation)

Этот документ описывает шаги ручной установки и настройки перед автоматизацией через Ansible.

## Порядок выполнения

**Важно**: Сначала выполните все шаги вручную, затем создайте Ansible роль для автоматизации.

## Шаг 1: Подготовка системы

### 1.1. Обновление системы

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.2. Установка Midnight Commander

```bash
sudo apt update && sudo apt install mc -y
```

Проверка установки:
```bash
mc --version
```

### 1.3. Настройка локали

```bash
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

Проверка:
```bash
locale
```

## Шаг 2: Создание рабочего каталога

```bash
sudo mkdir -p /srv/team22/userX_zabbix
sudo chmod 755 /srv/team22/userX_zabbix
sudo chown root:root /srv/team22/userX_zabbix
```

Замените `userX` на ваше имя пользователя (например, `user1`, `user2` и т.д.).

## Шаг 3: Установка Zabbix Agent

### 3.1. Добавление репозитория Zabbix

```bash
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian12_all.deb
sudo dpkg -i zabbix-release_6.0-4+debian12_all.deb
sudo apt update
```

### 3.2. Установка Zabbix Agent

```bash
sudo apt install zabbix-agent -y
```

### 3.3. Проверка установки

```bash
zabbix_agentd --version
```

## Шаг 4: Настройка метрики

### 4.1. Создание скрипта метрики

Выберите тип метрики в зависимости от вашего номера:
- **user1** - CPU Load
- **user2** - RAM Usage
- **user3** - Disk Availability
- **user4** - Network Connections
- **user5** - Processes
- **user6** - Swap Usage

Пример для CPU (user1):

```bash
sudo nano /srv/team22/user1_zabbix/cpu_metric.sh
```

Содержимое:
```bash
#!/bin/bash
# CPU Load Metric for user1

cpu_load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
echo "$cpu_load"
```

Пример для Swap (user6):

```bash
sudo nano /srv/team22/user6_zabbix/swap_metric.sh
```

Содержимое:
```bash
#!/bin/bash
# Swap Usage Metric for user6

total_swap=$(free | grep Swap | awk '{print $2}')
used_swap=$(free | grep Swap | awk '{print $3}')

if [ "$total_swap" -eq 0 ]; then
    echo "0.00"
else
    swap_usage=$(awk "BEGIN {printf \"%.2f\", ($used_swap/$total_swap)*100}")
    echo "$swap_usage"
fi
```

Сделайте скрипт исполняемым:
```bash
sudo chmod +x /srv/team22/user1_zabbix/cpu_metric.sh
```

Проверка:
```bash
/srv/team22/user1_zabbix/cpu_metric.sh
```

### 4.2. Настройка Zabbix Agent

Отредактируйте конфигурацию:
```bash
sudo nano /etc/zabbix/zabbix_agentd.conf
```

Добавьте или измените следующие параметры:

```
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=your-hostname
UserParameter=user1.cpu,/srv/team22/user1_zabbix/cpu_metric.sh
```

Замените `127.0.0.1` на IP вашего Zabbix Server.

### 4.3. Перезапуск Zabbix Agent

```bash
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
sudo systemctl status zabbix-agent
```

### 4.4. Проверка метрики

```bash
sudo zabbix_agentd -t user1.cpu
```

Или через zabbix_get (если установлен):
```bash
zabbix_get -s 127.0.0.1 -k user1.cpu
```

## Шаг 5: Настройка PostgreSQL

### 5.1. Установка PostgreSQL

```bash
sudo apt install postgresql postgresql-client -y
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 5.2. Создание базы данных

```bash
sudo -u postgres psql
```

В psql выполните:
```sql
CREATE DATABASE zabbix_metrics;
\c zabbix_metrics
\q
```

### 5.3. Создание таблицы

```bash
sudo -u postgres psql -d zabbix_metrics
```

Создайте таблицу для вашего пользователя:
```sql
CREATE TABLE user1_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user1_zabbix_timestamp ON user1_zabbix(timestamp);
CREATE INDEX idx_user1_zabbix_type ON user1_zabbix(metric_type);
```

### 5.4. Проверка таблицы

```sql
\dt
SELECT * FROM user1_zabbix;
```

## Шаг 6: Создание скрипта сбора метрик

### 6.1. Скрипт сбора метрик

```bash
sudo nano /srv/team22/user1_zabbix/collect_metrics.sh
```

Содержимое:
```bash
#!/bin/bash
METRIC_TYPE="cpu"
METRIC_SCRIPT="/srv/team22/user1_zabbix/${METRIC_TYPE}_metric.sh"
OUTPUT_FILE="/srv/team22/user1_zabbix/metrics_output.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

METRIC_VALUE=$($METRIC_SCRIPT)
echo "[$TIMESTAMP] $METRIC_TYPE: $METRIC_VALUE" >> "$OUTPUT_FILE"

# Save to PostgreSQL (using peer authentication via sudo)
sudo -u postgres psql -d zabbix_metrics -c \
  "INSERT INTO user1_zabbix (timestamp, metric_type, metric_value) VALUES ('$TIMESTAMP', '$METRIC_TYPE', '$METRIC_VALUE');"

echo "$METRIC_VALUE"
```

Сделайте исполняемым:
```bash
sudo chmod +x /srv/team22/user1_zabbix/collect_metrics.sh
```

### 6.2. Тестовый запуск

```bash
/srv/team22/user1_zabbix/collect_metrics.sh
cat /srv/team22/user1_zabbix/metrics_output.txt
```

Проверка в PostgreSQL:
```bash
sudo -u postgres psql -d zabbix_metrics -c "SELECT * FROM user1_zabbix ORDER BY timestamp DESC LIMIT 5;"
```

## Шаг 7: Настройка автоматического сбора

### 7.1. Настройка cron

```bash
sudo crontab -e
```

Добавьте строку (каждые 5 минут):
```
*/5 * * * * /srv/team22/user1_zabbix/collect_metrics.sh
```

Проверка:
```bash
sudo crontab -l
```

## Шаг 8: Финальная проверка

### 8.1. Проверка всех компонентов

```bash
# Проверка каталога
ls -la /srv/team22/user1_zabbix/

# Проверка Zabbix Agent
sudo systemctl status zabbix-agent
sudo zabbix_agentd -t user1.cpu

# Проверка PostgreSQL
sudo -u postgres psql -d zabbix_metrics -c "SELECT COUNT(*) FROM user1_zabbix;"

# Проверка логов
tail -20 /var/log/zabbix/zabbix_agentd.log
```

## Следующие шаги

После успешной ручной установки:

1. Задокументируйте все шаги (для отчета)
2. Сделайте скриншоты процесса
3. Создайте Ansible роль для автоматизации (см. `ansible/roles/zabbix_agent/`)
4. Проверьте работу Ansible роли

## Примечания

- Замените `user1` на ваше имя пользователя
- Замените `cpu` на ваш тип метрики
- Замените пароли PostgreSQL на безопасные
- Настройте правильный IP Zabbix Server

