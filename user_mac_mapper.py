#!/usr/bin/env python3
"""
User-MAC Address Mapping Script
Creates a CSV file mapping old user_ids with MAC addresses to new user_ids
"""

import csv
import base64
import urllib.request
from collections import defaultdict

# File URLs
OLD_CSV_URL = "https://customer-assets.emergentagent.com/job_user-mac-linker/artifacts/cbnqfkhm_old.csv"
MAGS_CSV_URL = "https://customer-assets.emergentagent.com/job_user-mac-linker/artifacts/ieoukum6_mags.csv"
NEW_CSV_URL = "https://customer-assets.emergentagent.com/job_user-mac-linker/artifacts/ewkwgvly_new.csv"

def download_csv(url):
    """Download CSV file from URL"""
    print(f"Downloading: {url}")
    with urllib.request.urlopen(url) as response:
        content = response.read().decode('utf-8')
        return list(csv.DictReader(content.splitlines()))

def decode_mac_address(encoded_mac):
    """Decode base64 encoded MAC address to readable format"""
    try:
        if not encoded_mac or encoded_mac == '\\N':
            return None
        decoded = base64.b64decode(encoded_mac).hex()
        # Format as MAC address (XX:XX:XX:XX:XX:XX)
        mac = ':'.join([decoded[i:i+2].upper() for i in range(0, 12, 2)])
        return mac
    except Exception as e:
        print(f"Error decoding MAC: {encoded_mac} - {e}")
        return None

def main():
    print("=" * 60)
    print("User-MAC Address Mapping Tool")
    print("=" * 60)
    
    # Download all CSV files
    print("\nStep 1: Downloading CSV files...")
    old_users = download_csv(OLD_CSV_URL)
    mags_data = download_csv(MAGS_CSV_URL)
    new_users = download_csv(NEW_CSV_URL)
    
    print(f"  - Old users: {len(old_users)} records")
    print(f"  - MAC data: {len(mags_data)} records")
    print(f"  - New users: {len(new_users)} records")
    
    # Create mapping dictionaries
    print("\nStep 2: Processing data...")
    
    # Map old user_id to MAC address
    old_id_to_mac = {}
    for mag in mags_data:
        old_user_id = mag.get('user_id', '').strip()
        encoded_mac = mag.get('mac', '').strip()
        
        if old_user_id and encoded_mac:
            mac_address = decode_mac_address(encoded_mac)
            if mac_address:
                old_id_to_mac[old_user_id] = mac_address
    
    print(f"  - Found {len(old_id_to_mac)} user-MAC mappings")
    
    # Create old user lookup by username (for matching with new users)
    old_users_by_username = {}
    for user in old_users:
        username = user.get('username', '').strip()
        user_id = user.get('id', '').strip()
        if username and user_id:
            old_users_by_username[username] = user_id
    
    # Create mappings
    print("\nStep 3: Creating mappings...")
    mappings = []
    
    for new_user in new_users:
        new_user_id = new_user.get('id', '').strip()
        username = new_user.get('username', '').strip()
        
        if not username or not new_user_id:
            continue
        
        # Find corresponding old user by username
        old_user_id = old_users_by_username.get(username)
        
        if old_user_id:
            # Get MAC address for old user
            mac_address = old_id_to_mac.get(old_user_id, 'N/A')
            
            mappings.append({
                'old_user_id': old_user_id,
                'mac_address': mac_address,
                'new_user_id': new_user_id,
                'username': username
            })
    
    print(f"  - Created {len(mappings)} mappings")
    
    # Write to CSV file
    output_file = '/app/user_mac_mapping.csv'
    print(f"\nStep 4: Writing to {output_file}...")
    
    with open(output_file, 'w', newline='') as f:
        fieldnames = ['old_user_id', 'mac_address', 'new_user_id', 'username']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        writer.writeheader()
        writer.writerows(mappings)
    
    print(f"\n✓ Successfully created mapping file: {output_file}")
    print(f"  - Total mappings: {len(mappings)}")
    
    # Statistics
    mac_found = sum(1 for m in mappings if m['mac_address'] != 'N/A')
    print(f"  - With MAC addresses: {mac_found}")
    print(f"  - Without MAC addresses: {len(mappings) - mac_found}")
    
    # Show sample
    print("\nSample mappings (first 5):")
    print("-" * 80)
    print(f"{'Old ID':<10} {'MAC Address':<20} {'New ID':<10} {'Username':<30}")
    print("-" * 80)
    for mapping in mappings[:5]:
        print(f"{mapping['old_user_id']:<10} {mapping['mac_address']:<20} "
              f"{mapping['new_user_id']:<10} {mapping['username']:<30}")
    
    print("\n" + "=" * 60)
    print("Mapping complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
