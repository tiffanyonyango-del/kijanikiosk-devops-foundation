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

module.exports.analyzeReceipts = async (event) => {
  const receipts = [];

  for (const record of event.Records || []) {
    const sourceBucket = record.s3?.bucket?.name;

    const sourceKey = decodeURIComponent(
      (record.s3?.object?.key || '').replace(/\+/g, ' ')
    );

    if (!sourceBucket || !sourceKey) {
      console.warn(JSON.stringify({
        event: 'receipt.analytics.invalid',
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

    receipts.push(receipt);
  }

  if (receipts.length === 0) {
    return {
      statusCode: 200
    };
  }

  const amounts = receipts.map(
    receipt => Number(receipt.amount || 0)
  );

  const timestamps = receipts
    .map(receipt => receipt.timestamp)
    .filter(Boolean)
    .sort();

  const summary = {
    receiptCount: receipts.length,
    totalAmount: amounts.reduce(
      (total, amount) => total + amount,
      0
    ),
    currency: receipts[0].currency || 'KES',
    earliestTimestamp: timestamps[0] || null,
    latestTimestamp: timestamps[timestamps.length - 1] || null,
    analyzedAt: new Date().toISOString()
  };

  console.log(JSON.stringify({
    event: 'receipt.analytics.summary',
    ...summary
  }));

  return {
    statusCode: 200,
    body: JSON.stringify(summary)
  };
};