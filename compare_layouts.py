#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# ///
"""Compare TOTEM and KLOR keymap layouts, showing only differences."""

import re
import sys
from pathlib import Path

# TOTEM: 38 keys
# Row 0:        10 keys (no outer)
# Row 1:        10 keys (no outer)
# Row 2: 1 +  5 + 6 + 1 = 12 keys (with outer columns)
# Row 3:         6 thumbs

# KLOR: 42 keys
# Row 0:        10 keys (no outer)
# Row 1: 1 + 10 + 1 = 12 keys (with outer columns)
# Row 2: 1 + 5 + 2 + 6 + 1 = 14 keys (with outer + encoders)
# Row 3:     3 + 2 + 3 = 8 thumbs (with encoder keys)

# Mapping: TOTEM index -> KLOR index (for common keys only)
TOTEM_TO_KLOR = {
    # Row 0: same positions
    0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9,
    # Row 1: KLOR has extra outer columns, shift by 1
    10: 11, 11: 12, 12: 13, 13: 14, 14: 15, 15: 16, 16: 17, 17: 18, 18: 19, 19: 20,
    # Row 2: KLOR has extra outer + encoder keys
    20: 22,  # left outer (GLOBE)
    21: 23, 22: 24, 23: 25, 24: 26, 25: 27,  # left side
    26: 30, 27: 31, 28: 32, 29: 33, 30: 34,  # right side
    31: 35,  # right outer
    # Row 3: thumbs - KLOR has extra encoder positions
    32: 36, 33: 37, 34: 38,  # left thumbs
    35: 41, 36: 42, 37: 43,  # right thumbs
}


def parse_bindings(bindings_raw: str) -> list[str]:
    """Parse individual bindings from raw string."""
    bindings = []
    tokens = bindings_raw.split()
    i = 0
    while i < len(tokens):
        if tokens[i].startswith('&'):
            binding = tokens[i]
            i += 1
            while i < len(tokens) and not tokens[i].startswith('&'):
                binding += ' ' + tokens[i]
                i += 1
            bindings.append(binding)
        else:
            i += 1
    return bindings


def parse_keymap(filepath: Path) -> dict[str, list[str]]:
    """Parse a ZMK keymap file and extract bindings for each layer."""
    content = filepath.read_text()
    layers = {}

    layer_pattern = re.compile(
        r'(\w+(?:[_-]\w+)*)\s*\{\s*bindings\s*=\s*<([^>]+)>',
        re.DOTALL
    )

    for match in layer_pattern.finditer(content):
        layer_name = match.group(1)
        layers[layer_name] = parse_bindings(match.group(2))

    return layers


def normalize_binding(binding: str) -> str:
    """Normalize a binding for comparison."""
    # Remove extra whitespace
    return ' '.join(binding.split())


def compare_layouts(totem_layers: dict, klor_layers: dict) -> None:
    """Compare layouts and print differences."""
    # Map layer names between keyboards
    layer_mapping = [
        ('base_layer', 'colemak-dh'),
        ('num_layer', 'num_layer'),
        ('sim_layer', 'sim_layer'),
        ('adjust_layer', 'adjust_layer'),
        ('arrows', 'arrows'),
        ('mouse', 'mouse'),
    ]

    for totem_layer, klor_layer in layer_mapping:
        if totem_layer not in totem_layers:
            print(f"Layer '{totem_layer}' not found in TOTEM")
            continue
        if klor_layer not in klor_layers:
            print(f"Layer '{klor_layer}' not found in KLOR")
            continue

        totem_bindings = totem_layers[totem_layer]
        klor_bindings = klor_layers[klor_layer]

        differences = []

        for totem_idx, klor_idx in TOTEM_TO_KLOR.items():
            if totem_idx >= len(totem_bindings):
                continue
            if klor_idx >= len(klor_bindings):
                continue

            totem_bind = normalize_binding(totem_bindings[totem_idx])
            klor_bind = normalize_binding(klor_bindings[klor_idx])

            if totem_bind != klor_bind:
                differences.append((totem_idx, totem_bind, klor_bind))

        if differences:
            print(f"\n## {totem_layer} / {klor_layer}")
            print(f"{'Pos':<4} {'TOTEM':<30} {'KLOR':<30}")
            print("-" * 66)
            for pos, totem_bind, klor_bind in differences:
                print(f"{pos:<4} {totem_bind:<30} {klor_bind:<30}")
        else:
            print(f"\n## {totem_layer} / {klor_layer}: identical")


def main():
    script_dir = Path(__file__).parent
    totem_path = script_dir / 'config' / 'totem.keymap'
    klor_path = script_dir / 'config' / 'klor.keymap'

    if not totem_path.exists():
        print(f"Error: {totem_path} not found")
        sys.exit(1)
    if not klor_path.exists():
        print(f"Error: {klor_path} not found")
        sys.exit(1)

    print("# TOTEM vs KLOR Layout Comparison")
    print("Comparing common keys only (38 of 42)")

    totem_layers = parse_keymap(totem_path)
    klor_layers = parse_keymap(klor_path)

    print(f"\nTOTEM layers: {list(totem_layers.keys())}")
    print(f"KLOR layers: {list(klor_layers.keys())}")

    compare_layouts(totem_layers, klor_layers)


if __name__ == '__main__':
    main()
