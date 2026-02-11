#!/usr/bin/env python3
"""
Скрипт для скачивания шрифтов Google Fonts локально
"""
import os
import urllib.request
import ssl

# Отключаем проверку SSL для скачивания (только для локального использования)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# Базовые URL для Google Fonts
BASE_URL = "https://fonts.gstatic.com/s"

# Определяем шрифты для скачивания
fonts = {
    'open-sans': {
        'weights': [300, 400, 600, 700],
        'url': 'opensans/v40'
    },
    'raleway': {
        'weights': [300, 400, 500, 600, 700],
        'url': 'raleway/v33'
    },
    'poppins': {
        'weights': [300, 400, 500, 600, 700],
        'url': 'poppins/v21'
    }
}

# Маппинг весов на названия файлов
weight_names = {
    300: 'Light',
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold'
}

def download_file(url, save_path):
    """Скачивает файл по URL"""
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, context=ssl_context) as response:
        with open(save_path, 'wb') as out_file:
            out_file.write(response.read())

def download_font(font_name, weight, base_path):
    """Скачивает файл шрифта"""
    weight_name = weight_names[weight]
    
    # Используем альтернативный метод через Google Fonts CSS API
    font_family_map = {
        'open-sans': 'Open+Sans',
        'raleway': 'Raleway',
        'poppins': 'Poppins'
    }
    
    font_family = font_family_map.get(font_name, font_name.replace('-', '+'))
    css_url = f"https://fonts.googleapis.com/css2?family={font_family}:wght@{weight}&display=swap"
    
    try:
        print(f"Скачиваю {font_name} {weight_name}...")
        
        # Получаем CSS с URL файлов шрифтов (используем правильный User-Agent для получения woff2)
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        req = urllib.request.Request(css_url, headers=headers)
        with urllib.request.urlopen(req, context=ssl_context) as response:
            css_content = response.read().decode('utf-8')
            
            # Извлекаем URL файла шрифта из CSS (может быть несколько вариантов)
            import re
            # Ищем все URL в CSS
            urls = re.findall(r'url\((https://[^)]+)\)', css_content)
            
            woff2_url = None
            woff_url = None
            
            for url in urls:
                if url.endswith('.woff2'):
                    woff2_url = url
                elif url.endswith('.woff'):
                    woff_url = url
            
            if woff2_url:
                save_path = os.path.join(base_path, font_name, f"{weight_name}.woff2")
                download_file(woff2_url, save_path)
                print(f"✓ Скачано: {save_path}")
            else:
                print(f"⚠ Не найден woff2 файл")
            
            if woff_url:
                save_path_woff = os.path.join(base_path, font_name, f"{weight_name}.woff")
                download_file(woff_url, save_path_woff)
                print(f"✓ Скачано: {save_path_woff}")
                
    except Exception as e:
        print(f"✗ Ошибка при скачивании {font_name} {weight_name}: {e}")
        import traceback
        traceback.print_exc()


def main():
    """Основная функция"""
    base_path = os.path.join(os.path.dirname(__file__), 'assets', 'fonts')
    
    # Создаем директории
    for font_name in fonts.keys():
        font_dir = os.path.join(base_path, font_name)
        os.makedirs(font_dir, exist_ok=True)
    
    # Скачиваем все шрифты
    print("Начинаю скачивание шрифтов...\n")
    for font_name, font_info in fonts.items():
        print(f"\n=== {font_name.upper()} ===")
        for weight in font_info['weights']:
            download_font(font_name, weight, base_path)
    
    print("\n✓ Завершено!")

if __name__ == '__main__':
    main()
