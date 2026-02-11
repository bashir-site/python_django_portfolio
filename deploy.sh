#!/bin/bash

# Скрипт для развертывания портфолио на сервере
# Использование: ./deploy.sh

set -e  # Остановка при ошибке

echo "🚀 Начинаем развертывание портфолио..."

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка, что скрипт запущен на сервере
if [ ! -d "/home/bashir" ]; then
    echo -e "${RED}❌ Ошибка: Скрипт должен быть запущен на сервере${NC}"
    exit 1
fi

# Переход в домашнюю директорию
cd /home/bashir

echo -e "${YELLOW}📁 Создаем директорию для портфолио...${NC}"
sudo mkdir -p /var/www/portfolio

echo -e "${YELLOW}📦 Копируем файлы портфолио...${NC}"
if [ -d "python_django_portfolio" ]; then
    sudo cp -r python_django_portfolio/* /var/www/portfolio/
    echo -e "${GREEN}✅ Файлы скопированы${NC}"
else
    echo -e "${RED}❌ Ошибка: Директория python_django_portfolio не найдена${NC}"
    exit 1
fi

echo -e "${YELLOW}🔐 Устанавливаем права доступа...${NC}"
sudo chown -R www-data:www-data /var/www/portfolio
sudo chmod -R 755 /var/www/portfolio

echo -e "${YELLOW}🔄 Перезапускаем nginx...${NC}"
cd pdf-translator

# Проверяем, какая версия docker-compose используется
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    docker compose restart nginx
else
    docker-compose restart nginx
fi

echo -e "${GREEN}✅ Nginx перезапущен${NC}"

echo -e "${YELLOW}🔍 Проверяем конфигурацию nginx...${NC}"
docker exec translate_files_nginx nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Конфигурация nginx корректна${NC}"
else
    echo -e "${RED}❌ Ошибка в конфигурации nginx${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Проверяем доступность файлов...${NC}"
if [ -f "/var/www/portfolio/index.html" ]; then
    echo -e "${GREEN}✅ index.html найден${NC}"
else
    echo -e "${RED}❌ Ошибка: index.html не найден${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Развертывание завершено успешно!${NC}"
echo ""
echo "Проверьте работу сайта:"
echo "  - https://bashir-python-backend-django-fastapi.ru"
echo ""
echo "Для проверки логов используйте:"
echo "  docker logs translate_files_nginx"
