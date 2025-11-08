# User-MAC Address Mapper Web Application

## Overview
A full-stack web application that allows you to upload CSV files and generate mappings between old user IDs, MAC addresses, and new user IDs.

## Features
- 🎨 Modern, intuitive web interface
- 📤 Drag-and-drop file upload support
- 👁️ Live preview of mapping results with statistics
- 📊 Visual statistics dashboard
- ⬇️ Direct CSV download of generated mappings
- 🔒 Client-side file processing (files are not stored on server)
- 📱 Fully responsive design

## Tech Stack
- **Frontend**: React.js with modern CSS
- **Backend**: FastAPI (Python)
- **File Processing**: Python CSV library

## Application URLs
- **Frontend**: https://user-mac-linker.preview.emergentagent.com
- **Backend API**: https://user-mac-linker.preview.emergentagent.com/api

## How to Use

### 1. Access the Website
Open your browser and navigate to:
```
https://user-mac-linker.preview.emergentagent.com
```

### 2. Upload Your CSV Files
The application requires three CSV files:

#### a) **Old Users CSV** (old.csv)
Should contain columns:
- `id` - Old user ID
- `username` - Username
- Other user information fields

#### b) **MACs CSV** (mags.csv)
Should contain columns:
- `user_id` - Links to old user ID
- `mac` - MAC address (base64 encoded or plain text)
- Other MAC-related fields

#### c) **New Users CSV** (new.csv)
Should contain columns:
- `id` - New user ID
- `username` - Username (matching old users)
- Other user information fields

### 3. Preview the Mapping
Click the **"👁️ Preview Mapping"** button to:
- See total number of mappings
- View statistics (users with/without MAC addresses)
- Preview first 10 rows of the mapping

### 4. Generate & Download
Click the **"⬇️ Generate & Download CSV"** button to:
- Create the complete mapping CSV
- Automatically download it to your computer

### 5. Output Format
The generated CSV file (`user_mac_mapping.csv`) contains:
```csv
old_user_id,mac_address,new_user_id,username
14003,N/A,117140,nv1hosting
19348,MDA6MUU6Qjg6Q0E6NTM6NUE=,117141,tVRrjvdYWk6MSSKZjtxS9anugxt7J6y5
...
```
**Note**: MAC addresses are kept in their original format from the source CSV (e.g., base64 encoded)

## API Endpoints

### GET /api/
Health check endpoint
```bash
curl https://user-mac-linker.preview.emergentagent.com/api/
```

### POST /api/preview
Preview mapping statistics and sample data
```bash
curl -X POST https://user-mac-linker.preview.emergentagent.com/api/preview \
  -F "old_file=@old.csv" \
  -F "mags_file=@mags.csv" \
  -F "new_file=@new.csv"
```

Response:
```json
{
  "success": true,
  "total_mappings": 57,
  "with_mac": 52,
  "without_mac": 5,
  "sample": [...]
}
```

### POST /api/process-files
Generate and download complete mapping CSV
```bash
curl -X POST https://user-mac-linker.preview.emergentagent.com/api/process-files \
  -F "old_file=@old.csv" \
  -F "mags_file=@mags.csv" \
  -F "new_file=@new.csv" \
  -o user_mac_mapping.csv
```

## Local Development

### Backend
```bash
cd /app/backend
python server.py
# Runs on http://localhost:8001
```

### Frontend
```bash
cd /app/frontend
yarn start
# Runs on http://localhost:3000
```

### Testing API with cURL
```bash
# Preview mapping
curl -X POST http://localhost:8001/api/preview \
  -F "old_file=@path/to/old.csv" \
  -F "mags_file=@path/to/mags.csv" \
  -F "new_file=@path/to/new.csv"

# Generate mapping
curl -X POST http://localhost:8001/api/process-files \
  -F "old_file=@path/to/old.csv" \
  -F "mags_file=@path/to/mags.csv" \
  -F "new_file=@path/to/new.csv" \
  -o mapping.csv
```

## File Structure
```
/app/
├── backend/
│   └── server.py           # FastAPI backend with file processing
├── frontend/
│   └── src/
│       ├── App.js          # React main component
│       └── App.css         # Styling
├── user_mac_mapper.py      # Standalone CLI script
├── user_mac_mapping.csv    # Example output
└── WEB_APP_README.md       # This file
```

## Error Handling
The application handles various error cases:
- Invalid CSV format
- Missing required columns
- Encoding issues (non-UTF-8 files)
- Empty or malformed data
- No matching users found

All errors are displayed clearly in the UI with helpful messages.

## Data Processing Logic

1. **MAC Address Handling**: MAC addresses are kept in their original format (no decoding/encoding)
2. **User Matching**: Matches old and new users by username
3. **MAC Linking**: Links MAC addresses using old user_id from mags table
4. **Missing Data**: Users without MAC addresses are marked as "N/A"

## Security & Privacy
- Files are processed in-memory and not stored on the server
- No data is persisted after processing
- All communication is over HTTPS
- CORS is configured for secure cross-origin requests

## Browser Compatibility
- ✅ Chrome (recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Edge
- ⚠️ IE11 (limited support)

## Troubleshooting

### File Upload Fails
- Ensure files are valid CSV format
- Check file encoding (must be UTF-8)
- Verify file size is reasonable (<10MB recommended)

### No Mappings Generated
- Verify usernames match between old and new CSV files
- Check that column names are correct
- Ensure data is not empty

### Preview Shows Wrong Data
- Verify you uploaded correct files in correct order
- Check CSV headers match expected format

## Support
For issues or questions, check the logs:
```bash
# Backend logs
tail -f /var/log/supervisor/backend.err.log

# Frontend logs
tail -f /var/log/supervisor/frontend.out.log
```

## Version
- **Version**: 1.0.0
- **Last Updated**: November 2024
