'use strict';

const {
  S3Client,
  GetObjectCommand,
  PutObjectCommand
} = require('@aws-sdk/client-s3');

const s3Config = {
  region: process.env.AWS_REGION || 'af-south-1'
};

if (process.env.S3_ENDPOINT) {
  s3Config.endpoint = process.env.S3_ENDPOINT;
  s3Config.forcePathStyle = true;
  s3Config.credentials = {
    accessKeyId: 'S3RVER',
    secretAccessKey: 'S3RVER'
  };
}

const s3 = new S3Client(s3Config);

const streamToString = async (stream) => {
  const chunks = [];

  for await (const chunk of stream) {
    chunks.push(Buffer.from(chunk));
  }

  return Buffer.concat(chunks).toString('utf-8');
};

module.exports.generateReceipt = async (event) => {
  const body = JSON.parse(event.body || '{}');

  if (!body.orderId) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        error: 'orderId is required'
      })
    };
  }

  const currency = process.env.DEFAULT_CURRENCY || 'KES';
  const timestamp = new Date().toISOString();

  const receipt = {
    orderId: body.orderId,
    amount: body.amount,
    currency,
    timestamp,
    receiptId: `receipt-${body.orderId}-${Date.now()}`
  };

  console.log(JSON.stringify({
    event: 'receipt.generated',
    orderId: receipt.orderId,
    receiptId: receipt.receiptId,
    amount: receipt.amount,
    currency: receipt.currency,
    timestamp: receipt.timestamp
  }));

  return {
    statusCode: 200,
    body: JSON.stringify(receipt)
  };
};

module.exports.processReceiptUpload = async (event) => {
  for (const record of event.Records || []) {
    const sourceBucket = record.s3?.bucket?.name;

    const sourceKey = decodeURIComponent(
      (record.s3?.object?.key || '').replace(/\+/g, ' ')
    );

    if (!sourceBucket || !sourceKey) {
      console.warn(JSON.stringify({
        event: 'receipt.upload.invalid',
        message: 'S3 event did not contain a valid bucket or object key'
      }));

      continue;
    }

    const object = await s3.send(
      new GetObjectCommand({
        Bucket: sourceBucket,
        Key: sourceKey
      })
    );

    const receipt = await streamToString(object.Body);

    const outputBucket = process.env.PROCESSED_BUCKET;

    await s3.send(
      new PutObjectCommand({
        Bucket: outputBucket,
        Key: sourceKey,
        Body: receipt,
        ContentType: 'application/json'
      })
    );

    console.log(JSON.stringify({
      event: 'receipt.uploaded',
      sourceBucket,
      sourceKey,
      outputBucket,
      outputKey: sourceKey
    }));
  }

  return {
    statusCode: 200
  };
};