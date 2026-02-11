#!/bin/bash

# Скрипт для быстрого обновления портфолио в Docker контейнере
# Использование: ./update_portfolio.sh

set -e

echo "🚀 Обновление портфолио в Docker контейнере..."

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Имя контейнера nginx
NGINX_CONTAINER="translate_files_nginx"

# Проверка что контейнер запущен
if ! docker ps | grep -q "$NGINX_CONTAINER"; then
    echo -e "${RED}❌ Контейнер $NGINX_CONTAINER не запущен!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Контейнер $NGINX_CONTAINER найден${NC}"

# Шаг 1: Обновить конфигурацию nginx
echo -e "\n${YELLOW}📝 Шаг 1: Обновление конфигурации nginx...${NC}"
if [ -f "portfolio.conf" ]; then
    cp portfolio.conf ~/pdf-translator/nginx/portfolio.conf
    echo -e "${GREEN}✅ Конфигурация обновлена${NC}"
else
    echo -e "${RED}❌ Файл portfolio.conf не найден!${NC}"
    exit 1
fi

# Шаг 2: Проверить конфигурацию
echo -e "\n${YELLOW}🔍 Шаг 2: Проверка конфигурации nginx...${NC}"
if docker exec $NGINX_CONTAINER nginx -t; then
    echo -e "${GREEN}✅ Конфигурация валидна${NC}"
else
    echo -e "${RED}❌ Ошибка в конфигурации!${NC}"
    exit 1
fi

# Шаг 3: Загрузить файлы портфолио
echo -e "\n${YELLOW}📦 Шаг 3: Загрузка файлов портфолио...${NC}"

# Проверить существует ли директория
if docker exec $NGINX_CONTAINER test -d /var/www/portfolio; then
    echo -e "${GREEN}✅ Директория /var/www/portfolio существует${NC}"
else
    echo -e "${YELLOW}⚠️  Создание директории /var/www/portfolio...${NC}"
    docker exec $NGINX_CONTAINER mkdir -p /var/www/portfolio
fi

# Копировать файлы
if [ -f "index.html" ]; then
    docker cp index.html $NGINX_CONTAINER:/var/www/portfolio/
    echo -e "${GREEN}✅ index.html загружен${NC}"
else
    echo -e "${RED}❌ Файл index.html не найден!${NC}"
    exit 1
fi

if [ -f "sw.js" ]; then
    docker cp sw.js $NGINX_CONTAINER:/var/www/portfolio/
    echo -e "${GREEN}✅ sw.js загружен${NC}"
else
    echo -e "${YELLOW}⚠️  Файл sw.js не найден (пропускаем)${NC}"
fi

if [ -d "assets" ]; then
    docker cp assets $NGINX_CONTAINER:/var/www/portfolio/
    echo -e "${GREEN}✅ assets загружены${NC}"
else
    echo -e "${RED}❌ Папка assets не найдена!${NC}"
    exit 1
fi

# Шаг 4: Установить права доступа
echo -e "\n${YELLOW}🔐 Шаг 4: Установка прав доступа...${NC}"
docker exec $NGINX_CONTAINER chown -R nginx:nginx /var/www/portfolio 2>/dev/null || \
docker exec $NGINX_CONTAINER chown -R www-data:www-data /var/www/portfolio 2>/dev/null || \
echo -e "${YELLOW}⚠️  Не удалось установить права (может быть не критично)${NC}"
docker exec $NGINX_CONTAINER chmod -R 755 /var/www/portfolio
echo -e "${GREEN}✅ Права установлены${NC}"

# Шаг 5: Перезагрузить nginx
echo -e "\n${YELLOW}🔄 Шаг 5: Перезагрузка nginx...${NC}"
if docker exec $NGINX_CONTAINER nginx -s reload; then
    echo -e "${GREEN}✅ Nginx перезагружен${NC}"
else
    echo -e "${YELLOW}⚠️  Перезагрузка не удалась, перезапускаем контейнер...${NC}"
    docker restart $NGINX_CONTAINER
    sleep 2
    echo -e "${GREEN}✅ Контейнер перезапущен${NC}"
fi

# Шаг 6: Проверка
echo -e "\n${YELLOW}✅ Шаг 6: Финальная проверка...${NC}"
if docker exec $NGINX_CONTAINER test -f /var/www/portfolio/index.html; then
    echo -e "${GREEN}✅ index.html на месте${NC}"
else
    echo -e "${RED}❌ index.html не найден в контейнере!${NC}"
    exit 1
fi

if docker exec $NGINX_CONTAINER test -f /var/www/portfolio/sw.js; then
    echo -e "${GREEN}✅ sw.js на месте${NC}"
fi

echo -e "\n${GREEN}🎉 Портфолио успешно обновлено!${NC}"
echo -e "\n${YELLOW}📋 Следующие шаги:${NC}"
echo "1. Откройте сайт: https://bashir-python-backend-django-fastapi.ru"
echo "2. Проверьте DevTools → Application → Service Workers"
echo "3. Проверьте Network tab → заголовки Cache-Control"
echo ""
echo -e "${GREEN}Готово! 🚀${NC}"
