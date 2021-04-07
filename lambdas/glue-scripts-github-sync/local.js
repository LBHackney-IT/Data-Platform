const handler = require('./index');
const AWS = require("aws-sdk");

var credentials = new AWS.SharedIniFileCredentials({profile: 'madetech'});
AWS.config.credentials = credentials;

handler.handler({})

