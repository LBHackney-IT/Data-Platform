var githubapi = require("github"),
async = require("async"),
AWS = require('aws-sdk'),
// secrets = require('./secrets.js');

exports.handler = async (event) => {
// TODO implement


    // var referenceCommitSha,
    //     newTreeSha, newCommitSha, code;
    
    const response = {
        statusCode: 200,
        body: JSON.stringify('Hello from Lambda!'),
    };
    return response;
};