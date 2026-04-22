#!/usr/bin/env bash
# Run Flutter Web with HTML renderer (needed for B2 images without CORS)
flutter run -d chrome --web-renderer html "$@"
