# Быстрый старт

## Шаг 1: Подготовка PostgreSQL

```bash
# Войдите в PostgreSQL
sudo -u postgres psql

# Выполните создание базы данных
\i sql/create_database.sql
\q
```

## Шаг 2: Настройка переменных

Отредактируйте `ansible/playbook.yml`:

```yaml
vars:
  zabbix_server: "192.168.1.100" # IP вашего Zabbix Server
  postgresql_host: "localhost"
  postgresql_user: "postgres"
  postgresql_password: "ваш_пароль"
  postgresql_database: "zabbix_metrics"
```

## Шаг 3: Настройка inventory

Отредактируйте `ansible/inventories/inventory.yml` с вашими серверами:

```yaml
student1:
  ansible_host: 192.168.1.10
  username: user1
  metric_type: cpu
```

## Шаг 4: Запуск

```bash
cd ansible
ansible-playbook -i inventories/inventory.yml playbook.yml
```

## Шаг 5: Проверка

```bash
# Проверка метрики через zabbix_get
zabbix_get -s 192.168.1.10 -k user1.cpu

# Или через скрипт
../scripts/test_zabbix_agent.sh user1 cpu 192.168.1.10
```

## Шаг 6: Настройка автоматического сбора

```bash
sudo ../scripts/setup_cron.sh user1 cpu
```

## Шаг 7: Просмотр метрик

```bash
# В PostgreSQL
../scripts/view_metrics.sh user1

# Экспорт в CSV для отчета
../scripts/export_metrics_report.sh user1
```

## Примеры для каждого студента

### Student 1 (CPU)

```bash
ansible-playbook playbook.yml -e "username=user1" -e "metric_type=cpu" -l student1
```

### Student 2 (RAM)

```bash
ansible-playbook playbook.yml -e "username=user2" -e "metric_type=ram" -l student2
```

### Student 3 (Disk)

```bash
ansible-playbook playbook.yml -e "username=user3" -e "metric_type=disk" -l student3
```

### Student 4 (Network)

```bash
ansible-playbook playbook.yml -e "username=user4" -e "metric_type=network" -l student4
```

### Student 5 (Processes)

```bash
ansible-playbook playbook.yml -e "username=user5" -e "metric_type=processes" -l student5
```

### Student 6 (Swap)

```bash
ansible-playbook playbook.yml -e "username=user6" -e "metric_type=swap" -l student6
```
