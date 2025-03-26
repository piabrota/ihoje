#!/usr/bin/env python3
import os
import json

# Events API endpoint response
events = [
    {
        "id": "1",
        "title": "Festival de Música",
        "description": "Um grande festival de música com artistas locais",
        "date": "2025-05-01T19:00:00",
        "location": "São Paulo, SP",
        "image_url": "/static/images/event1.svg",
        "category": "Música",
        "price": 50.0,
        "city_id": "1"
    },
    {
        "id": "2",
        "title": "Workshop de Dança",
        "description": "Aprenda diferentes estilos de dança com os melhores professores",
        "date": "2025-05-10T14:00:00",
        "location": "Rio de Janeiro, RJ",
        "image_url": "/static/images/event2.svg",
        "category": "Dança",
        "price": 35.0,
        "city_id": "2"
    },
    {
        "id": "3",
        "title": "Feira Gastronômica",
        "description": "Experimente pratos de diferentes culinárias",
        "date": "2025-05-15T11:00:00",
        "location": "Belo Horizonte, MG",
        "image_url": "/static/images/event3.svg",
        "category": "Gastronomia",
        "price": 0.0,
        "city_id": "3"
    }
]

# Cities API endpoint response
cities = [
    {"id": "1", "name": "São Paulo"},
    {"id": "2", "name": "Rio de Janeiro"},
    {"id": "3", "name": "Belo Horizonte"}
]

# Create API directory if it doesn't exist
os.makedirs('dist/api', exist_ok=True)

# Save events response to events.json file
with open('dist/api/events', 'w', encoding='utf-8') as f:
    json.dump(events, f, ensure_ascii=False, indent=2)
print("✅ Created events API endpoint")

# Save cities response to cities.json file
with open('dist/api/cities', 'w', encoding='utf-8') as f:
    json.dump(cities, f, ensure_ascii=False, indent=2)
print("✅ Created cities API endpoint")

print("Mock API files created successfully for a same-origin API solution.")