from fastapi import FastAPI, APIRouter, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
import os
import logging
from pathlib import Path
import csv
import io
from typing import List

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


def decode_mac_address(encoded_mac: str) -> str:
    """Return MAC address as-is without decoding"""
    try:
        if not encoded_mac or encoded_mac in ['\\N', 'N/A', '']:
            return 'N/A'
        # Return the MAC address as-is without decoding
        return encoded_mac
    except Exception as e:
        logging.error(f"Error processing MAC: {encoded_mac} - {e}")
        return 'N/A'


def process_csv_files(old_content: str, mags_content: str, new_content: str, output_format: str = 'simple') -> List[dict]:
    """Process the three CSV files and create mappings
    
    Args:
        old_content: Old users CSV content
        mags_content: MACs CSV content
        new_content: New users CSV content
        output_format: 'simple' for old_user_id,mac_address,new_user_id,username
                      'macs_template' to match the uploaded MACs CSV format
    """
    
    # Parse CSV contents
    old_users = list(csv.DictReader(io.StringIO(old_content)))
    mags_data = list(csv.DictReader(io.StringIO(mags_content)))
    new_users = list(csv.DictReader(io.StringIO(new_content)))
    
    # Get the original mags CSV headers for template mode
    mags_headers = list(mags_data[0].keys()) if mags_data else []
    
    # Create old to new user ID mapping
    old_to_new_user_id = {}
    
    # Create old user lookup by username
    old_users_by_username = {}
    for user in old_users:
        username = user.get('username', '').strip()
        user_id = user.get('id', '').strip()
        if username and user_id:
            old_users_by_username[username] = user_id
    
    # Create new user lookup by username
    new_users_by_username = {}
    for user in new_users:
        username = user.get('username', '').strip()
        user_id = user.get('id', '').strip()
        if username and user_id:
            new_users_by_username[username] = user_id
    
    # Build old_to_new mapping
    for username, old_id in old_users_by_username.items():
        new_id = new_users_by_username.get(username)
        if new_id:
            old_to_new_user_id[old_id] = new_id
    
    # Create mappings based on format
    mappings = []
    
    if output_format == 'macs_template':
        # Output in the same format as the uploaded MACs CSV
        for mag_row in mags_data:
            old_user_id = mag_row.get('user_id', '').strip()
            new_user_id = old_to_new_user_id.get(old_user_id)
            
            if new_user_id:
                # Create a new row with the same structure as original
                new_row = mag_row.copy()
                new_row['user_id'] = new_user_id
                mappings.append(new_row)
            else:
                # If no mapping found, keep original (or skip if you prefer)
                # For now, we'll include it with original user_id
                mappings.append(mag_row.copy())
    
    else:
        # Simple format: old_user_id, mac_address, new_user_id, username
        for new_user in new_users:
            new_user_id = new_user.get('id', '').strip()
            username = new_user.get('username', '').strip()
            
            if not username or not new_user_id:
                continue
            
            # Find corresponding old user by username
            old_user_id = old_users_by_username.get(username)
            
            if old_user_id:
                # Get MAC address for old user
                mac_address = 'N/A'
                for mag in mags_data:
                    if mag.get('user_id', '').strip() == old_user_id:
                        mac_address = mag.get('mac', 'N/A').strip()
                        break
                
                mappings.append({
                    'old_user_id': old_user_id,
                    'mac_address': mac_address,
                    'new_user_id': new_user_id,
                    'username': username
                })
    
    return mappings


@api_router.get("/")
async def root():
    return {"message": "User-MAC Mapper API", "version": "1.0"}


@api_router.post("/process-files")
async def process_files(
    old_file: UploadFile = File(..., description="Old users CSV file"),
    mags_file: UploadFile = File(..., description="MACs CSV file"),
    new_file: UploadFile = File(..., description="New users CSV file")
):
    """Process the three CSV files and return mapping CSV"""
    
    try:
        # Read file contents
        old_content = (await old_file.read()).decode('utf-8')
        mags_content = (await mags_file.read()).decode('utf-8')
        new_content = (await new_file.read()).decode('utf-8')
        
        # Process files
        mappings = process_csv_files(old_content, mags_content, new_content)
        
        if not mappings:
            raise HTTPException(status_code=400, detail="No mappings could be created. Please check your CSV files.")
        
        # Generate CSV output
        output = io.StringIO()
        fieldnames = ['old_user_id', 'mac_address', 'new_user_id', 'username']
        writer = csv.DictWriter(output, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(mappings)
        
        # Get CSV content
        csv_content = output.getvalue()
        
        # Create response with file download
        return StreamingResponse(
            iter([csv_content]),
            media_type="text/csv",
            headers={
                "Content-Disposition": "attachment; filename=user_mac_mapping.csv"
            }
        )
        
    except UnicodeDecodeError:
        raise HTTPException(status_code=400, detail="Invalid file encoding. Please ensure files are UTF-8 encoded.")
    except KeyError as e:
        raise HTTPException(status_code=400, detail=f"Missing required column in CSV: {str(e)}")
    except Exception as e:
        logging.error(f"Error processing files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing files: {str(e)}")


@api_router.post("/preview")
async def preview_mapping(
    old_file: UploadFile = File(...),
    mags_file: UploadFile = File(...),
    new_file: UploadFile = File(...)
):
    """Preview the mapping without downloading"""
    
    try:
        # Read file contents
        old_content = (await old_file.read()).decode('utf-8')
        mags_content = (await mags_file.read()).decode('utf-8')
        new_content = (await new_file.read()).decode('utf-8')
        
        # Process files
        mappings = process_csv_files(old_content, mags_content, new_content)
        
        # Calculate statistics
        total = len(mappings)
        with_mac = sum(1 for m in mappings if m['mac_address'] != 'N/A')
        without_mac = total - with_mac
        
        return {
            "success": True,
            "total_mappings": total,
            "with_mac": with_mac,
            "without_mac": without_mac,
            "sample": mappings[:10]  # First 10 mappings as preview
        }
        
    except Exception as e:
        logging.error(f"Error previewing files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error previewing files: {str(e)}")


# Add a root route for the main app (without /api prefix)
@app.get("/")
async def root_redirect():
    return {"message": "User-MAC Mapper API", "note": "Use /api/ endpoint", "version": "1.0"}

# Include the router in the main app
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)
