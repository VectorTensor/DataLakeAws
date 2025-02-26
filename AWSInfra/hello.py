import json
import boto3
import os

s3_client = boto3.client('s3')

# Destination bucket (Set this as an environment variable in Lambda)
DESTINATION_BUCKET = os.getenv('DEST_BUCKET')

def lambda_handler(event, context):
    # Extract bucket name and file key from the event
    for record in event['Records']:
        source_bucket = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']

        print(f"File {file_key} uploaded to {source_bucket}")

        # JSON content to be uploaded
        json_content = json.dumps({"name": file_key})

        # Destination file name (same name but with .json extension)
        destination_key = f"{file_key}.json"

        # Upload JSON file to destination bucket
        s3_client.put_object(
            Bucket=DESTINATION_BUCKET,
            Key=destination_key,
            Body=json_content,
            ContentType="application/json"
        )

        print(f"Metadata JSON uploaded to {DESTINATION_BUCKET}/{destination_key}")

    return {
        "statusCode": 200,
        "body": json.dumps("JSON metadata created successfully")
    }
