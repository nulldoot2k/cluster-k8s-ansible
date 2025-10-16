from minio import Minio
from minio.error import S3Error
from io import BytesIO
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv('.env')

# Get configuration from environment
MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT')
MINIO_ACCESS_KEY = os.getenv('MINIO_ACCESS_KEY')
MINIO_SECRET_KEY = os.getenv('MINIO_SECRET_KEY')
MINIO_BUCKET = os.getenv('MINIO_BUCKET')
MINIO_SECURE = os.getenv('MINIO_SECURE', 'false').lower() == 'true'

# Validate required environment variables
required_vars = ['MINIO_ENDPOINT', 'MINIO_ACCESS_KEY', 'MINIO_SECRET_KEY', 'MINIO_BUCKET']
missing_vars = [var for var in required_vars if not os.getenv(var)]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

# Initialize MinIO client (without region parameter)
client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=MINIO_SECURE
)

print(f"🔗 Connecting to MinIO at {MINIO_ENDPOINT}")
print(f"📦 Using bucket: {MINIO_BUCKET}")
print(f"🔒 Secure: {MINIO_SECURE}")
print("="*50)

try:
    # Test 1: Check if bucket exists
    if not client.bucket_exists(MINIO_BUCKET):
        print(f"\n❌ Bucket '{MINIO_BUCKET}' does not exist!")
        exit(1)
    print(f"\n✅ Bucket '{MINIO_BUCKET}' exists!")
    
    # Test 2: Upload small file
    content = b"Hello from Python with environment variables!"
    client.put_object(
        MINIO_BUCKET,
        "test.txt",
        BytesIO(content),
        length=len(content)
    )
    print("\n✅ Upload small file successful!")
    
    # Test 3: Upload larger file
    print("\n📤 Uploading large file...")
    large_content = b"A" * 100000  # 100KB
    client.put_object(
        MINIO_BUCKET,
        "large_file.txt",
        BytesIO(large_content),
        length=len(large_content)
    )
    print("✅ Large file uploaded!")
    
    # Test 4: Upload file from disk
    print("\n📤 Creating and uploading file from disk...")
    with open('/tmp/local_file.txt', 'w') as f:
        f.write(f"Created at {datetime.now()}\n")
        f.write("This is a test file from disk\n" * 100)
    
    client.fput_object(
        MINIO_BUCKET,
        "from_disk.txt",
        "/tmp/local_file.txt"
    )
    print("✅ File from disk uploaded!")
    
    # Test 5: List all objects with details
    print(f"\n📋 Objects in {MINIO_BUCKET}:")
    objects = client.list_objects(MINIO_BUCKET)
    total_size = 0
    for obj in objects:
        size_kb = obj.size / 1024
        print(f"  📄 {obj.object_name}")
        print(f"     Size: {obj.size} bytes ({size_kb:.2f} KB)")
        print(f"     Modified: {obj.last_modified}")
        total_size += obj.size
    print(f"\n📊 Total: {total_size} bytes ({total_size/1024:.2f} KB)")
    
    # Test 6: Download and verify
    print("\n⬇️  Downloading test.txt...")
    response = client.get_object(MINIO_BUCKET, "test.txt")
    data = response.read()
    print(f"✅ Downloaded content: {data.decode()}")
    response.close()
    
    # Test 7: Get object metadata
    print("\n📊 Getting metadata for test.txt...")
    stat = client.stat_object(MINIO_BUCKET, "test.txt")
    print(f"  Size: {stat.size} bytes")
    print(f"  Content-Type: {stat.content_type}")
    print(f"  Last Modified: {stat.last_modified}")
    
    print("\n" + "="*50)
    print("🎉 All tests completed successfully!")
    print("="*50)
    
except S3Error as e:
    print(f"\n❌ S3 Error: {e}")
except Exception as e:
    print(f"\n❌ Unexpected error: {e}")
