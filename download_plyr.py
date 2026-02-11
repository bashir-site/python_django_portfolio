#!/usr/bin/env python3
"""
Скрипт для скачивания plyr.js локально
"""
import os
import urllib.request
import ssl

# Отключаем проверку SSL для скачивания (только для локального использования)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

def download_file(url, save_path):
    """Скачивает файл по URL"""
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, context=ssl_context) as response:
        with open(save_path, 'wb') as out_file:
            out_file.write(response.read())

def main():
    """Основная функция"""
    base_path = os.path.join(os.path.dirname(__file__), 'assets', 'vendor', 'glightbox', 'js')
    
    print("Скачиваю plyr.js...")
    try:
        download_file('https://cdn.plyr.io/3.6.12/plyr.js', os.path.join(base_path, 'plyr.js'))
        print("✓ Скачано: plyr.js")
    except Exception as e:
        print(f"✗ Ошибка: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()
