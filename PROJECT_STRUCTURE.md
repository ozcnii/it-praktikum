# Структура проекта

```
it-praktikum/
│
├── ansible/                          # Ansible конфигурация
│   ├── ansible.cfg                   # Конфигурация Ansible
│   ├── inventory.yml                 # Инвентарь серверов
│   ├── playbook.yml                  # Главный playbook
│   └── roles/
│       └── zabbix_agent/             # Роль для установки Zabbix Agent
│           ├── handlers/
│           │   └── main.yml          # Обработчики (перезапуск сервиса)
│           ├── tasks/
│           │   └── main.yml          # Основные задачи
│           └── templates/            # Шаблоны Jinja2
│               ├── zabbix_agentd.conf.j2          # Конфиг Zabbix Agent
│               ├── cpu_metric.sh.j2               # Скрипт метрики CPU
│               ├── ram_metric.sh.j2               # Скрипт метрики RAM
│               ├── disk_metric.sh.j2              # Скрипт метрики диска
│               ├── network_metric.sh.j2           # Скрипт метрики сети
│               ├── processes_metric.sh.j2        # Скрипт метрики процессов
│               ├── collect_metrics.sh.j2         # Скрипт сбора метрик
│               ├── save_to_postgresql.sh.j2      # Скрипт сохранения в БД
│               └── create_table.sql.j2           # SQL для создания таблицы
│
├── sql/                               # SQL скрипты
│   └── create_database.sql            # Создание базы данных
│
├── scripts/                           # Вспомогательные скрипты
│   ├── test_zabbix_agent.sh          # Тестирование агента
│   ├── view_metrics.sh               # Просмотр метрик из БД
│   ├── setup_cron.sh                 # Настройка cron для автосбора
│   └── export_metrics_report.sh      # Экспорт метрик в CSV
│
├── README.md                          # Основная документация
├── QUICKSTART.md                      # Быстрый старт
├── REPORT_EXAMPLE.md                  # Пример отчета
├── PROJECT_STRUCTURE.md               # Этот файл
├── requirements.txt                   # Требования к системе
└── .gitignore                         # Git ignore файл

```

## Описание компонентов

### Ansible Role: zabbix_agent

Роль выполняет следующие задачи:

1. **Создание каталога** `/srv/team22/{username}_zabbix`
2. **Установка Zabbix Agent** через пакетный менеджер
3. **Настройка конфигурации** агента с пользовательской метрикой
4. **Копирование скриптов** для сбора метрик
5. **Установка PostgreSQL клиента**
6. **Создание таблицы** в PostgreSQL
7. **Запуск и включение** Zabbix Agent

### Метрики

Каждый тип метрики реализован отдельным скриптом:

- **cpu** - загрузка CPU (1 минута)
- **ram** - использование RAM (%)
- **disk** - доступность диска (%)
- **network** - количество сетевых соединений
- **processes** - количество процессов

### Скрипты

- `test_zabbix_agent.sh` - проверка работы агента через zabbix_get
- `view_metrics.sh` - просмотр последних метрик из PostgreSQL
- `setup_cron.sh` - настройка автоматического сбора каждые 5 минут
- `export_metrics_report.sh` - экспорт данных в CSV для отчета

## Порядок использования

1. Настроить переменные в `ansible/playbook.yml`
2. Настроить inventory в `ansible/inventory.yml`
3. Запустить playbook: `ansible-playbook playbook.yml`
4. Проверить работу: `scripts/test_zabbix_agent.sh user1 cpu`
5. Настроить автосбор: `scripts/setup_cron.sh user1 cpu`
6. Просмотреть метрики: `scripts/view_metrics.sh user1`
