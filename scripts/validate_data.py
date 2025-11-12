#!/usr/bin/env python3
"""
Data Validation Script for NEON BELT

Validates all JSON data files against expected schemas.
Run this before committing changes to data files.

Usage:
    python scripts/validate_data.py
"""

import json
import os
import sys
from pathlib import Path


def validate_json_file(filepath):
    """Validate that a file contains valid JSON."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return True, None
    except json.JSONDecodeError as e:
        return False, f"JSON decode error: {e}"
    except Exception as e:
        return False, f"Error reading file: {e}"


def validate_weapon(data, filepath):
    """Validate weapon schema."""
    required_fields = ['id', 'displayName', 'slot', 'type', 'stats']
    missing = [field for field in required_fields if field not in data]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"

    # Validate weapon type
    valid_types = ['kinetic', 'energy', 'explosive', 'exotic']
    if data['type'] not in valid_types:
        return False, f"Invalid weapon type: {data['type']}. Must be one of {valid_types}"

    return True, None


def validate_asteroid(data, filepath):
    """Validate asteroid schema."""
    required_fields = ['id', 'displayName', 'tier', 'sizes']
    missing = [field for field in required_fields if field not in data]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"

    # Validate sizes
    if 'large' not in data.get('sizes', {}):
        return False, "Asteroid must have at least 'large' size defined"

    return True, None


def validate_ship(data, filepath):
    """Validate ship schema."""
    required_fields = ['id', 'displayName', 'archetype', 'stats', 'signature']
    missing = [field for field in required_fields if field not in data]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"

    # Validate stats
    required_stats = ['hull', 'shields', 'speed', 'turnRate']
    missing_stats = [stat for stat in required_stats if stat not in data.get('stats', {})]
    if missing_stats:
        return False, f"Missing required stats: {', '.join(missing_stats)}"

    return True, None


def validate_upgrade(data, filepath):
    """Validate upgrade schema."""
    required_fields = ['id', 'displayName', 'description', 'rarity', 'modifiers']
    missing = [field for field in required_fields if field not in data]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"

    return True, None


def validate_sector(data, filepath):
    """Validate sector schema."""
    required_fields = ['id', 'displayName', 'tier', 'structure']
    missing = [field for field in required_fields if field not in data]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"

    return True, None


VALIDATORS = {
    'weapons': validate_weapon,
    'asteroids': validate_asteroid,
    'ships': validate_ship,
    'upgrades': validate_upgrade,
    'sectors': validate_sector,
}


def main():
    """Main validation function."""
    project_root = Path(__file__).parent.parent
    data_dir = project_root / 'data'

    if not data_dir.exists():
        print(f"Error: Data directory not found: {data_dir}")
        return 1

    errors = []
    validated = 0

    print("Validating NEON BELT data files...")
    print("=" * 60)

    for category_dir in data_dir.iterdir():
        if not category_dir.is_dir():
            continue

        category = category_dir.name
        validator = VALIDATORS.get(category)

        if not validator:
            print(f"⚠️  No validator for category: {category}")
            continue

        print(f"\n📁 {category.upper()}")

        for json_file in category_dir.glob('*.json'):
            # Validate JSON syntax
            is_valid_json, json_error = validate_json_file(json_file)
            if not is_valid_json:
                errors.append(f"{json_file}: {json_error}")
                print(f"  ❌ {json_file.name}: {json_error}")
                continue

            # Validate schema
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)

            is_valid, error = validator(data, json_file)
            if is_valid:
                print(f"  ✅ {json_file.name}")
                validated += 1
            else:
                errors.append(f"{json_file}: {error}")
                print(f"  ❌ {json_file.name}: {error}")

    print("\n" + "=" * 60)
    print(f"\n📊 Results: {validated} files validated")

    if errors:
        print(f"❌ {len(errors)} errors found:\n")
        for error in errors:
            print(f"  - {error}")
        return 1
    else:
        print("✅ All data files valid!")
        return 0


if __name__ == '__main__':
    sys.exit(main())
