# New MACs CSV Format Output

## What Changed

The application now generates output CSV files that **match the format of your uploaded MACs CSV**, with updated user IDs.

### Before (Old Behavior)
Output format was always:
```csv
old_user_id,mac_address,new_user_id,username
14003,N/A,117140,nv1hosting
19348,MDA6MUU6Qjg6Q0E6NTM6NUE=,117141,user2
```

### After (New Behavior)
Output matches your uploaded MACs CSV template:
```csv
user_id,mac,device_type,status,language
117140,N/A,Desktop,Active,en
117141,MDA6MUU6Qjg6Q0E6NTM6NUE=,Mobile,Active,en
```

## How It Works

1. **Upload your 3 CSV files**:
   - Old Users CSV (old user IDs)
   - MACs CSV (MAC addresses with old user IDs)
   - New Users CSV (new user IDs)

2. **The application**:
   - Reads all columns from your MACs CSV
   - Matches old user IDs to new user IDs (by username)
   - Creates new rows with the **same structure** as your MACs CSV
   - Replaces old user_id with new user_id
   - Keeps all other columns (mac, device_type, status, language, etc.)

3. **Download**: New file named `new_macs.csv`

## Example

### Input Files

**old.csv**:
```csv
id,username,member_id
14003,john.doe,100
19348,jane.smith,100
```

**mags.csv** (your template):
```csv
user_id,mac,device_type,status,language
14003,ABC123,Desktop,Active,en
19348,DEF456,Mobile,Active,en
```

**new.csv**:
```csv
id,username,member_id
117140,john.doe,100
117141,jane.smith,100
```

### Output

**new_macs.csv**:
```csv
user_id,mac,device_type,status,language
117140,ABC123,Desktop,Active,en
117141,DEF456,Mobile,Active,en
```

Notice how:
- ✅ `user_id` updated from old (14003) to new (117140)
- ✅ All other columns preserved exactly as in original MACs CSV
- ✅ Same column order and structure

## Benefits

1. **Drop-in Replacement**: Output can directly replace your old MACs CSV
2. **Preserves Metadata**: All additional columns are preserved
3. **No Manual Editing**: No need to manually update user IDs
4. **Same Structure**: Output matches your existing database schema

## API Changes

### Preview Endpoint
**Before**:
```json
{
  "sample": [
    {"old_user_id": "14003", "mac_address": "ABC", "new_user_id": "117140", "username": "john"}
  ]
}
```

**After**:
```json
{
  "sample": [
    {"user_id": "117140", "mac": "ABC", "device_type": "Desktop", "status": "Active", "language": "en"}
  ],
  "note": "Output will match the uploaded MACs CSV template format"
}
```

### Download Endpoint
- **Before**: Downloaded as `user_mac_mapping.csv`
- **After**: Downloads as `new_macs.csv`

## Important Notes

1. **Matching by Username**: The application matches old and new users by their `username` field
2. **Missing Matches**: If a MAC entry has no matching new user, it keeps the original user_id
3. **All Columns Preserved**: Every column from your MACs CSV is included in the output
4. **MAC Format**: MAC addresses remain in their original format (not decoded)

## Troubleshooting

### Issue: Output has wrong columns

**Problem**: MACs CSV doesn't have expected columns

**Solution**: Ensure your MACs CSV has at least:
- `user_id` column (required)
- `mac` column (required)
- Any other columns you want preserved

### Issue: Some user_ids not updated

**Problem**: No matching username found

**Solution**: 
- Check that usernames in old.csv and new.csv match exactly
- Verify username field exists in both files
- Check for spelling differences or extra spaces

### Issue: Blank MACs in output

**Problem**: Original MACs CSV had blank/missing MAC addresses

**Solution**: This is expected - blank MACs are preserved as-is

## Testing

### On Your Server

```bash
# After updating the code
cd /var/www/html/macmapping
git pull origin main
sudo supervisorctl restart macmapping-backend

# Test the API
curl http://localhost:8001/api/

# Use the web interface at
# http://192.168.1.210:3000
```

### Manual Test

1. Upload your 3 CSV files
2. Click "Preview Mapping"
3. Check the sample data matches your MACs CSV structure
4. Click "Generate & Download CSV"
5. Open downloaded `new_macs.csv`
6. Verify:
   - ✅ user_id column has new IDs
   - ✅ All other columns preserved
   - ✅ Same structure as uploaded MACs CSV

## Migration Guide

### Old Application (Before Update)

If you were using the old format, you can still access it by:
1. Downloading the `new_macs.csv`
2. Extracting just the columns you need

Or modify the backend to add a format parameter (see developer notes below).

### For Developers

To add format selection:

```python
# Add query parameter
@api_router.post("/process-files")
async def process_files(
    old_file: UploadFile,
    mags_file: UploadFile,
    new_file: UploadFile,
    format: str = 'macs_template'  # or 'simple'
):
    mappings = process_csv_files(
        old_content, 
        mags_content, 
        new_content, 
        output_format=format
    )
```

## Support

For issues:
1. Check all CSV files have required columns
2. Verify usernames match between old and new
3. Check backend logs: `tail -f /var/log/supervisor/macmapping-backend.err.log`
4. Test API directly: `curl http://localhost:8001/api/`
