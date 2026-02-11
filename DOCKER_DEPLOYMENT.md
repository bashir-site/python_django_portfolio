# 🐳 Развертывание портфолио в Docker контейнере

## Текущая структура:

```
translate_files_nginx (Docker контейнер)
├── /etc/nginx/nginx.conf (основной конфиг)
└── /etc/nginx/conf.d/portfolio.conf (подключается через include)

Хост:
├── /home/bashir/pdf-translator/nginx/nginx.conf
└── /home/bashir/pdf-translator/nginx/portfolio.conf (монтируется в контейнер)
```

## 🚀 Быстрое обновление (3 шага):

### Шаг 1: Обновить portfolio.conf на хосте

```bash
# На сервере, в директории с проектом
cd ~/python_django_portfolio

# Скопируйте обновленный portfolio.conf в директорию nginx
cp portfolio.conf ~/pdf-translator/nginx/portfolio.conf
```

### Шаг 2: Загрузить файлы портфолио в контейнер

```bash
# Скопируйте файлы портфолио в контейнер
docker cp index.html translate_files_nginx:/var/www/portfolio/
docker cp sw.js translate_files_nginx:/var/www/portfolio/
docker cp -r assets translate_files_nginx:/var/www/portfolio/
```

**ИЛИ** если у вас есть volume для `/var/www/portfolio`:

```bash
# Найдите где монтируется volume
docker inspect translate_files_nginx | grep -A 10 Mounts

# Скопируйте файлы напрямую в директорию на хосте
# Например, если volume монтируется из ~/pdf-translator/portfolio:
cp -r index.html sw.js assets ~/pdf-translator/portfolio/
```

### Шаг 3: Перезагрузить nginx в контейнере

```bash
# Проверить конфигурацию
docker exec translate_files_nginx nginx -t

# Если все ОК, перезагрузить nginx
docker exec translate_files_nginx nginx -s reload

# ИЛИ перезапустить контейнер
docker restart translate_files_nginx
```

## 📋 Полная инструкция:

### Вариант 1: Через docker cp (если нет volume)

```bash
# 1. Обновить конфигурацию
cp portfolio.conf ~/pdf-translator/nginx/portfolio.conf

# 2. Перезапустить контейнер для применения новой конфигурации
docker restart translate_files_nginx

# 3. Загрузить файлы портфолио
docker cp index.html translate_files_nginx:/var/www/portfolio/
docker cp sw.js translate_files_nginx:/var/www/portfolio/
docker cp -r assets translate_files_nginx:/var/www/portfolio/

# 4. Установить права (если нужно)
docker exec translate_files_nginx chown -R nginx:nginx /var/www/portfolio
docker exec translate_files_nginx chmod -R 755 /var/www/portfolio
```

### Вариант 2: Через volume (рекомендуется)

Если у вас настроен volume для `/var/www/portfolio`, найдите его на хосте:

```bash
# Найти путь к volume
docker inspect translate_files_nginx | grep -A 20 Mounts

# Пример вывода может показать:
# "Source": "/home/bashir/pdf-translator/portfolio",
# "Destination": "/var/www/portfolio"

# Тогда просто скопируйте файлы:
cp index.html sw.js ~/pdf-translator/portfolio/
cp -r assets ~/pdf-translator/portfolio/

# Обновить конфигурацию
cp portfolio.conf ~/pdf-translator/nginx/portfolio.conf

# Перезапустить контейнер
docker restart translate_files_nginx
```

### Вариант 3: Через docker-compose (если используется)

Если у вас есть `docker-compose.prod.yml`, обновите его:

```yaml
services:
  nginx:
    volumes:
      - ./nginx/portfolio.conf:/etc/nginx/conf.d/portfolio.conf:ro
      - ./portfolio:/var/www/portfolio:ro  # Добавьте этот volume если его нет
```

Затем:

```bash
# Обновить файлы в ./portfolio/
cp index.html sw.js ./portfolio/
cp -r assets ./portfolio/

# Обновить конфигурацию
cp portfolio.conf ./nginx/portfolio.conf

# Перезапустить
docker-compose -f docker-compose.prod.yml restart nginx
```

## ✅ Проверка после развертывания:

### 1. Проверить конфигурацию nginx:

```bash
docker exec translate_files_nginx nginx -t
```

Должно быть: `nginx: configuration file /etc/nginx/nginx.conf test is successful`

### 2. Проверить логи:

```bash
# Проверить ошибки
docker logs translate_files_nginx --tail 50

# Проверить логи портфолио
docker exec translate_files_nginx tail -f /var/log/nginx/portfolio_error.log
```

### 3. Проверить доступность файлов:

```bash
# Проверить что файлы на месте
docker exec translate_files_nginx ls -la /var/www/portfolio/
docker exec translate_files_nginx ls -la /var/www/portfolio/assets/

# Проверить что sw.js доступен
docker exec translate_files_nginx cat /var/www/portfolio/sw.js | head -5
```

### 4. Проверить в браузере:

1. Откройте сайт: https://bashir-python-backend-django-fastapi.ru
2. Откройте DevTools (F12) → Application → Service Workers
3. Должен быть зарегистрирован Service Worker
4. Network tab → проверьте заголовки Cache-Control

## 🔧 Решение проблем:

### Проблема: 404 для файлов портфолио

**Решение:**
```bash
# Проверить что файлы на месте
docker exec translate_files_nginx ls -la /var/www/portfolio/

# Проверить права доступа
docker exec translate_files_nginx ls -la /var/www/portfolio/index.html

# Если нужно, установить права
docker exec translate_files_nginx chown -R nginx:nginx /var/www/portfolio
```

### Проблема: Конфигурация не применяется

**Решение:**
```bash
# Проверить что файл обновлен
cat ~/pdf-translator/nginx/portfolio.conf | head -20

# Проверить что он монтируется в контейнер
docker exec translate_files_nginx cat /etc/nginx/conf.d/portfolio.conf | head -20

# Перезапустить контейнер
docker restart translate_files_nginx
```

### Проблема: Service Worker не регистрируется

**Решение:**
```bash
# Проверить что sw.js доступен
docker exec translate_files_nginx curl -I http://localhost/sw.js

# Проверить логи браузера (F12 → Console)
# Должна быть ошибка если файл недоступен
```

## 📊 Проверка производительности:

После развертывания проверьте:

```bash
# Проверить заголовки кеширования
curl -I https://bashir-python-backend-django-fastapi.ru/assets/css/style.css

# Должен быть заголовок:
# Cache-Control: public, immutable, max-age=31536000
```

## 🎯 Ожидаемые результаты:

- ✅ Статические файлы кешируются на 1 год
- ✅ HTML кешируется на 1 час
- ✅ Service Worker работает
- ✅ Страница загружается мгновенно при повторных визитах

## 📝 Чеклист:

- [ ] Обновлен `portfolio.conf` в `~/pdf-translator/nginx/`
- [ ] Загружены `index.html` и `sw.js` в контейнер
- [ ] Загружена папка `assets/` в контейнер
- [ ] Перезапущен контейнер nginx
- [ ] Проверена конфигурация (`nginx -t`)
- [ ] Проверена работа Service Worker в браузере
- [ ] Проверены заголовки кеширования
