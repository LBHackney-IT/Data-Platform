process.on('unhandledRejection', (error: Error) => {
    // Will print "unhandledRejection err is not defined"
    console.log('[UnhandledRejection]', error.message)
    console.log(error)
})

process.env.ORIGIN_BUCKET_ID = 'dataplatform-joates-landing-zone'
process.env.ORIGIN_PATH = 'parking/'
process.env.TARGET_BUCKET_ID = 'dataplatform-joates-test'
process.env.TARGET_PATH = 'potato/'

const handler = require('./index')

handler.handler({})

export {}