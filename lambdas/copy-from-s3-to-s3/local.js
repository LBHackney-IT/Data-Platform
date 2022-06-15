process.on('unhandledRejection', error => {
  // Will print "unhandledRejection err is not defined"
  console.log('[UnhandledRejection]', error.message);
  console.log(error)
});

process.env.ORIGIN_BUCKET_ID = "dataplatform-b-dalton-landing-zone";
process.env.ORIGIN_PATH = "/";
process.env.TARGET_BUCKET_ID = "dataplatform-b-dalton-landing-zone";
process.env.TARGET_PATH = "/";
const handler = require("./index");

handler.handler({});


// /housing/databases   / name of the database / name of the table /
// import_year{todays year} / import_month={todays month} / import_day={todays day} / parquet filename