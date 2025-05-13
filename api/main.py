from google.cloud import storage
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import qrcode
import os
from io import BytesIO

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

app = FastAPI()

# CORS for local development
origins = [
    "http://localhost:3000"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Gcloud Storage

storage_client = storage.Client()

bucket_name = "qr-bucket-1"

@app.post("/generate-qr-code/")
async def generate_qr_code(url: str):
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")


    # Save the image to a BytesIO object
    img_bytes = BytesIO()
    img.save(img_bytes, format='PNG')
    img_bytes.seek(0)

    # Generate a unique filename
    sanitized_url = url.rstrip('/')
    filename = f"qr_codes/{sanitized_url.split('//')[-1]}.png"

    try:

        # Upload the image to Google Cloud Storage
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(filename)
        blob.upload_from_file(img_bytes, content_type='image/png')


        # Make the blob publicly accessible
        blob.make_public()

        return {"qr_url": blob.public_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading to GCS: {str(e)}")