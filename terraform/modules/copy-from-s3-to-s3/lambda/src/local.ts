process.on('unhandledRejection', (error: Error) => {
    // Will print "unhandledRejection err is not defined"
    console.log('[UnhandledRejection]', error.message)
    console.log(error)
})

process.env.ORIGIN_BUCKET_ID = 'dataplatform-joates-landing-zone'
process.env.ORIGIN_PATH = 'housing/rentsense/'
process.env.TARGET_BUCKET_ID = 'feeds-pluto-mobysoft'
process.env.TARGET_PATH = 'hackneylondonborough.beta/'
process.env.ASSUME_ROLE_ARN = 'arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104'

const handler = require('./index')

handler.handler({})

export {}