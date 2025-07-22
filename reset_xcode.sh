#!/bin/bash

echo "🔄 Полный сброс Xcode для CoffeeApp..."

echo "1️⃣ Закрытие Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

echo "2️⃣ Очистка DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/CoffeeApp-*

echo "3️⃣ Очистка кэшей Xcode..."
rm -rf ~/Library/Developer/Xcode/UserData/IDEEditorInteractivity* 2>/dev/null || true
find ~/Library/Caches/com.apple.dt.Xcode* -name "*CoffeeApp*" -exec rm -rf {} \; 2>/dev/null || true

echo "4️⃣ Очистка индексов..."
rm -rf ~/Library/Developer/Xcode/UserData/IDECoreData*Index* 2>/dev/null || true

echo "5️⃣ Очистка проекта..."
xcodebuild clean -project CoffeeApp.xcodeproj -scheme CoffeeApp

echo "6️⃣ Сборка проекта..."
xcodebuild \
  -project CoffeeApp.xcodeproj \
  -scheme CoffeeApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -sdk iphonesimulator \
  build

if [ $? -eq 0 ]; then
  echo "✅ Проект успешно собран!"
  
  echo "7️⃣ Установка в симулятор..."
  xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/CoffeeApp-*/Build/Products/Debug-iphonesimulator/CoffeeApp.app
  
  echo "8️⃣ Запуск приложения..."
  xcrun simctl launch booted com.coffeeapp.demo
  
  echo "🎉 Готово! Теперь можно открыть Xcode - ошибки должны исчезнуть."
  echo "💡 Рекомендация: Product -> Clean Build Folder в Xcode для закрепления результата"
else
  echo "❌ Ошибка сборки"
  exit 1
fi 