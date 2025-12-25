#!/bin/bash
cd "$(dirname "$0")/../flutter_application_1"
osascript -e 'tell app "Terminal" to do script "cd '"$(pwd)"' && flutter run -d chrome --web-port=8080"'
