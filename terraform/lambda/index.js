const AWS = require('aws-sdk');
const s3 = new AWS.S3();

exports.handler = async (event) => {
  try {
    // Get bucket name from environment variable
    const bucketName = process.env.BUCKET_NAME;
    const key = 'todo-data.json';

    // Read file from S3
    const params = {
      Bucket: bucketName,
      Key: key
    };

    const data = await s3.getObject(params).promise();
    const todoData = JSON.parse(data.Body.toString('utf-8'));

    // Return response with CORS headers
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,OPTIONS'
      },
      body: JSON.stringify(todoData)
    };
  } catch (error) {
    console.error('Error reading from S3:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        error: 'Failed to retrieve todo data',
        message: error.message
      })
    };
  }
};
