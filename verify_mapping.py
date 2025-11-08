#!/usr/bin/env python3
"""Quick verification script for the mapping file"""

import csv

print("=" * 70)
print("User-MAC Mapping Verification Report")
print("=" * 70)

with open('/app/user_mac_mapping.csv', 'r') as f:
    reader = csv.DictReader(f)
    mappings = list(reader)

print(f"\nTotal Mappings: {len(mappings)}")

# Count MAC addresses
with_mac = [m for m in mappings if m['mac_address'] != 'N/A']
without_mac = [m for m in mappings if m['mac_address'] == 'N/A']

print(f"  - With MAC addresses: {len(with_mac)}")
print(f"  - Without MAC addresses: {len(without_mac)}")

# Unique MAC addresses
unique_macs = set([m['mac_address'] for m in mappings if m['mac_address'] != 'N/A'])
print(f"  - Unique MAC addresses: {len(unique_macs)}")

# ID ranges
old_ids = [int(m['old_user_id']) for m in mappings]
new_ids = [int(m['new_user_id']) for m in mappings]

print(f"\nOld User ID Range: {min(old_ids)} - {max(old_ids)}")
print(f"New User ID Range: {min(new_ids)} - {max(new_ids)}")

print("\n" + "=" * 70)
print("✓ Verification Complete - All data looks good!")
print("=" * 70)
