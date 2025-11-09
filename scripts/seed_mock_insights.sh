#!/bin/bash

echo "🌱 Seeding mock insights to local Isar database..."

# Run the Dart script
~/flutter/bin/flutter run lib/features/insights/data/mock/generate_mock_insights.dart

echo "✅ Mock data seeding complete!"
