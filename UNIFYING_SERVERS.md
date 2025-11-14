# Объединение серверов команды в единый

Этот документ описывает процесс объединения всех серверов команды в единую систему мониторинга.

## Архитектура решения

### Вариант 1: Централизованный Zabbix Server

```
┌─────────────────┐
│ Zabbix Server   │
│ (центральный)   │
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┬──────────┬──────────┐
    │         │          │          │          │          │
┌───▼───┐ ┌──▼───┐  ┌───▼───┐  ┌───▼───┐  ┌───▼───┐  ┌───▼───┐
│Agent1 │ │Agent2│  │Agent3 │  │Agent4 │  │Agent5 │  │Agent6 │
│ CPU   │ │ RAM  │  │ Disk  │  │Network│  │Process│  │ Swap  │
└───────┘ └──────┘  └───────┘  └───────┘  └───────┘  └───────┘
    │         │          │          │          │          │
    └─────────┴──────────┴──────────┴──────────┴──────────┘
                    │
            ┌───────▼────────┐
            │ PostgreSQL DB  │
            │ (центральная)  │
            └────────────────┘
```

## Шаг 1: Настройка централизованного Zabbix Server

### 1.1. Выбор сервера для Zabbix Server

Выберите один из серверов команды или выделите отдельный сервер для Zabbix Server.

### 1.2. Установка Zabbix Server

На выбранном сервере:

```bash
# Добавление репозитория
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian12_all.deb
sudo dpkg -i zabbix-release_6.0-4+debian12_all.deb
sudo apt update

# Установка Zabbix Server и PostgreSQL
sudo apt install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql -y

# Установка PostgreSQL (если еще не установлен)
sudo apt install postgresql -y
```

### 1.3. Настройка базы данных Zabbix

```bash
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
```

### 1.4. Настройка Zabbix Server

Отредактируйте `/etc/zabbix/zabbix_server.conf`:

```bash
sudo nano /etc/zabbix/zabbix_server.conf
```

Основные параметры:
```
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=your_password
```

### 1.5. Запуск Zabbix Server

```bash
sudo systemctl restart zabbix-server
sudo systemctl enable zabbix-server
sudo systemctl status zabbix-server
```

## Шаг 2: Настройка централизованной базы данных метрик

### 2.1. Создание общей базы данных

На сервере с PostgreSQL (может быть тот же, что и Zabbix Server):

```bash
sudo -u postgres psql
```

```sql
CREATE DATABASE zabbix_metrics;
\c zabbix_metrics
```

### 2.2. Создание таблиц для всех участников

```sql
-- Таблица для user1 (CPU)
CREATE TABLE user1_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для user2 (RAM)
CREATE TABLE user2_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для user3 (Disk)
CREATE TABLE user3_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для user4 (Network)
CREATE TABLE user4_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для user5 (Processes)
CREATE TABLE user5_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица для user6 (Swap)
CREATE TABLE user6_zabbix (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    metric_type VARCHAR(50) NOT NULL,
    metric_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание индексов
CREATE INDEX idx_user1_zabbix_timestamp ON user1_zabbix(timestamp);
CREATE INDEX idx_user2_zabbix_timestamp ON user2_zabbix(timestamp);
CREATE INDEX idx_user3_zabbix_timestamp ON user3_zabbix(timestamp);
CREATE INDEX idx_user4_zabbix_timestamp ON user4_zabbix(timestamp);
CREATE INDEX idx_user5_zabbix_timestamp ON user5_zabbix(timestamp);
CREATE INDEX idx_user6_zabbix_timestamp ON user6_zabbix(timestamp);
```

### 2.3. Настройка доступа к базе данных

Если база данных находится на отдельном сервере, настройте `pg_hba.conf`:

```bash
sudo nano /etc/postgresql/*/main/pg_hba.conf
```

Добавьте строки для доступа с других серверов:
```
host    zabbix_metrics    postgres    192.168.1.0/24    md5
```

Перезапустите PostgreSQL:
```bash
sudo systemctl restart postgresql
```

## Шаг 3: Настройка Zabbix Agents на всех серверах

### 3.1. Обновление конфигурации агентов

На каждом сервере отредактируйте `/etc/zabbix/zabbix_agentd.conf`:

```bash
sudo nano /etc/zabbix/zabbix_agentd.conf
```

Укажите IP центрального Zabbix Server:
```
Server=192.168.1.100  # IP центрального Zabbix Server
ServerActive=192.168.1.100
Hostname=server1  # Уникальное имя хоста
```

### 3.2. Обновление скриптов сохранения в PostgreSQL

На каждом сервере обновите скрипт `save_to_postgresql.sh`:

```bash
sudo nano /srv/team22/user1_zabbix/save_to_postgresql.sh
```

Измените параметры подключения:
```bash
PGHOST="192.168.1.100"  # IP сервера с PostgreSQL
PGUSER="postgres"
PGPASSWORD="your_password"
PGDATABASE="zabbix_metrics"
```

### 3.3. Перезапуск агентов

```bash
sudo systemctl restart zabbix-agent
sudo systemctl status zabbix-agent
```

## Шаг 4: Регистрация хостов в Zabbix Server

### 4.1. Доступ к веб-интерфейсу Zabbix

Откройте в браузере:
```
http://zabbix-server-ip/zabbix
```

Войдите с учетными данными по умолчанию:
- Username: `Admin`
- Password: `zabbix`

### 4.2. Добавление хостов

1. Перейдите в **Configuration → Hosts**
2. Нажмите **Create host**
3. Для каждого сервера заполните:
   - **Host name**: уникальное имя (например, `server1`, `server2`)
   - **Groups**: добавьте группу `Linux servers`
   - **Interfaces**: добавьте IP адрес и порт 10050
   - **Templates**: добавьте `Linux by Zabbix agent`

### 4.3. Добавление пользовательских метрик

Для каждого хоста добавьте UserParameter:

1. Перейдите в **Configuration → Hosts**
2. Выберите хост
3. Перейдите на вкладку **Macros**
4. Добавьте макрос `{$USERPARAM}` или настройте через конфигурацию агента

Или используйте конфигурацию напрямую на агенте (уже настроено в `/etc/zabbix/zabbix_agentd.conf`).

## Шаг 5: Проверка работы

### 5.1. Проверка метрик в Zabbix

1. Перейдите в **Monitoring → Latest data**
2. Выберите хосты команды
3. Проверьте наличие метрик:
   - `user1.cpu`
   - `user2.ram`
   - `user3.disk`
   - `user4.network`
   - `user5.processes`
   - `user6.swap`

### 5.2. Проверка данных в PostgreSQL

```bash
sudo -u postgres psql -d zabbix_metrics
```

Проверьте данные всех таблиц:
```sql
-- Проверка всех метрик
SELECT 'user1' as user, COUNT(*) as count FROM user1_zabbix
UNION ALL
SELECT 'user2', COUNT(*) FROM user2_zabbix
UNION ALL
SELECT 'user3', COUNT(*) FROM user3_zabbix
UNION ALL
SELECT 'user4', COUNT(*) FROM user4_zabbix
UNION ALL
SELECT 'user5', COUNT(*) FROM user5_zabbix
UNION ALL
SELECT 'user6', COUNT(*) FROM user6_zabbix;

-- Последние метрики от всех
SELECT 'user1' as user, timestamp, metric_type, metric_value 
FROM user1_zabbix ORDER BY timestamp DESC LIMIT 1
UNION ALL
SELECT 'user2', timestamp, metric_type, metric_value 
FROM user2_zabbix ORDER BY timestamp DESC LIMIT 1
UNION ALL
SELECT 'user3', timestamp, metric_type, metric_value 
FROM user3_zabbix ORDER BY timestamp DESC LIMIT 1
UNION ALL
SELECT 'user4', timestamp, metric_type, metric_value 
FROM user4_zabbix ORDER BY timestamp DESC LIMIT 1
UNION ALL
SELECT 'user5', timestamp, metric_type, metric_value 
FROM user5_zabbix ORDER BY timestamp DESC LIMIT 1
UNION ALL
SELECT 'user6', timestamp, metric_type, metric_value 
FROM user6_zabbix ORDER BY timestamp DESC LIMIT 1;
```

### 5.3. Создание дашборда в Zabbix

1. Перейдите в **Monitoring → Dashboards**
2. Создайте новый дашборд "Team 22 Metrics"
3. Добавьте виджеты для каждой метрики:
   - Graph для CPU
   - Graph для RAM
   - Graph для Disk
   - Graph для Network
   - Graph для Processes
   - Graph для Swap

## Шаг 6: Автоматизация через Ansible

### 6.1. Обновление inventory

Обновите `ansible/inventories/inventory.yml` с IP адресами всех серверов:

```yaml
all:
  children:
    team22:
      hosts:
        server1:
          ansible_host: 192.168.1.10
          username: user1
          metric_type: cpu
          zabbix_server: 192.168.1.100  # Центральный сервер
          postgresql_host: 192.168.1.100  # Центральная БД
        server2:
          ansible_host: 192.168.1.11
          username: user2
          metric_type: ram
          zabbix_server: 192.168.1.100
          postgresql_host: 192.168.1.100
        # ... и т.д.
```

### 6.2. Запуск playbook для всех серверов

```bash
cd ansible
ansible-playbook -i inventories/inventory.yml playbook.yml
```

## Итоговая архитектура

После объединения у команды будет:

1. **Единый Zabbix Server** - централизованный сбор метрик
2. **Единая база данных PostgreSQL** - хранение всех метрик команды
3. **6 Zabbix Agents** - каждый собирает свою метрику
4. **Единый дашборд** - визуализация всех метрик команды
5. **Автоматизация через Ansible** - быстрое развертывание на новых серверах

## Преимущества объединения

- ✅ Централизованный мониторинг всех серверов
- ✅ Единая точка доступа к метрикам
- ✅ Возможность создания общих дашбордов
- ✅ Упрощенное управление конфигурациями
- ✅ Единая база данных для анализа метрик команды

