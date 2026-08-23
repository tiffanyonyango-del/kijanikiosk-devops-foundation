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

module.exports.processReceipt = async (event) => {
  for (const record of event.Records || []) {
    const sourceBucket = record.s3?.bucket?.name;

    const sourceKey = decodeURIComponent(
      (record.s3?.object?.key || '').replace(/\+/g, ' ')
    );

    if (!sourceBucket || !sourceKey) {
      console.warn(JSON.stringify({
        event: 'receipt.process.invalid',
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

    const receipt = JSON.parse(
      await streamToString(object.Body)
    );

    const processedReceipt = {
      ...receipt,
      processedAt: new Date().toISOString()
    };

    const outputKey =
      `notifications/${receipt.receiptId}.json`;

    await s3.send(
      new PutObjectCommand({
        Bucket: process.env.NOTIFICATIONS_BUCKET,
        Key: outputKey,
        Body: JSON.stringify(processedReceipt),
        ContentType: 'application/json'
      })
    );

    console.log(JSON.stringify({
      event: 'receipt.processed',
      orderId: receipt.orderId,
      receiptId: receipt.receiptId,
      sourceBucket,
      sourceKey,
      outputBucket: process.env.NOTIFICATIONS_BUCKET,
      outputKey,
      timestamp: processedReceipt.processedAt
    }));
  }

  return {
    statusCode: 200
  };
};