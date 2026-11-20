# Выкладка Lunex AFK

Пуш в main запускает content-and-studio для любого набора файлов. Таймер lunex-afk-main-deploy на VPS проверяет текущий коммит примерно раз в минуту. Выкладка начинается после успешного прогона именно для этого SHA.

Сервер собирает Go API, Studio и подписанный Android APK. Перед переключением создаётся резервная копия PostgreSQL. При провале проверок запуска скрипт возвращает предыдущие файлы и перезапускает сервисы. Рабочий SHA хранится в /opt/lunex-afk/main-deploy/current, журналы доступны через journalctl -u lunex-afk-main-deploy. Откат файлов не восстанавливает PostgreSQL из копии автоматически.

Версии контента, отслеживаемые Git, берутся из main. Изменения контента в Studio, которые должны пережить выкладку, нужно включать в Git. Web-игра отключена. Android доступен по /afkgame/download/latest.apk и обновляется установкой новой сборки.

Для установки на существующем VPS скопировать deploy-vps.sh в /opt/lunex-afk/deploy-vps.sh и оба файла systemd в /etc/systemd/system. После обновления файлов выполнить systemctl daemon-reload и systemctl enable --now lunex-afk-main-deploy.timer. Нужны настроенные Godot и Android SDK, существующий ключ подписи APK и GitHub CLI с доступом на чтение Actions у системного пользователя gamedev.
