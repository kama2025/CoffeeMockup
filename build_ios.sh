#!/bin/bash

echo "🏗️  Сборка CoffeeApp для iOS..."

xcodebuild \
  -project CoffeeApp.xcodeproj \
  -scheme CoffeeApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -sdk iphonesimulator \
  build

if [ $? -eq 0 ]; then
  echo "✅ Сборка успешна!"
  
  echo "📱 Установка приложения в симулятор..."
  xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/CoffeeApp-acwnmdkwswgzsodbpxfyirwjvbml/Build/Products/Debug-iphonesimulator/CoffeeApp.app
  
  echo "🚀 Запуск приложения..."
  xcrun simctl launch booted com.coffeeapp.demo
  
  echo "🎉 Готово!"
else
  echo "❌ Ошибка сборки"
  exit 1
fi 