# User-MAC Address Mapping Tool

## Overview
This tool creates a CSV mapping file that links old user IDs with their MAC addresses to new user IDs.

## Files Generated

### 1. `user_mac_mapping.csv`
The main output file containing the mappings with the following columns:
- **old_user_id**: The original user ID from the backup SQL
- **mac_address**: The MAC address associated with the user (decoded from base64)
- **new_user_id**: The new user ID from the new system
- **username**: The username (included for reference and verification)

### 2. `user_mac_mapper.py`
The Python script that processes the source CSV files and generates the mapping.

## Data Sources
The script processes three CSV files:
1. **old.csv** - Old user records with original IDs
2. **mags.csv** - MAC address table linking user_ids to MAC addresses
3. **new.csv** - New user records with new IDs

## Mapping Logic
1. **Download**: Fetches all three CSV files from provided URLs
2. **MAC Address Handling**: MAC addresses are kept in their original format (no decoding/encoding)
3. **User Matching**: Matches old and new users by username
4. **MAC Linking**: Links MAC addresses from the mags table using old user_id
5. **Output**: Generates a CSV with old_user_id, mac_address, and new_user_id

## Statistics
- **Total mappings created**: 57
- **Users with MAC addresses**: 52
- **Users without MAC addresses**: 5 (marked as "N/A")

## Sample Output
```
old_user_id,mac_address,new_user_id,username
14003,N/A,117140,nv1hosting
19348,30:30:3A:31:45:3A,117141,tVRrjvdYWk6MSSKZjtxS9anugxt7J6y5
30669,30:30:3A:31:45:3A,117142,neSAyawKs3b3Stqm3CpphZHpCHcBV8WG
```

## Usage

### Running the Script
```bash
python3 user_mac_mapper.py
```

### Viewing the Results
```bash
# View the entire mapping file
cat user_mac_mapping.csv

# View first 10 mappings
head -n 11 user_mac_mapping.csv

# Count total mappings
wc -l user_mac_mapping.csv
```

## Notes
- MAC addresses are stored in base64 format in the source data and are decoded to standard MAC address format
- Some users may not have associated MAC addresses (marked as "N/A")
- Username is used as the primary matching key between old and new user records
- The script handles edge cases like missing data, invalid MAC addresses, and encoding issues

## File Location
All generated files are located in: `/app/`
- `/app/user_mac_mapping.csv` - Final mapping file
- `/app/user_mac_mapper.py` - Python script
- `/app/MAPPING_README.md` - This documentation
