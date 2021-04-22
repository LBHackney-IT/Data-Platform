resource "aws_route53_record" "yrgjjtklo2jbiclmjf55oe2yhecc2b3q_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "yrgjjtklo2jbiclmjf55oe2yhecc2b3q._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["yrgjjtklo2jbiclmjf55oe2yhecc2b3q.dkim.amazonses.com"]
}
resource "aws_route53_record" "wwwwendy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.wendy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["wendy.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwmuseum_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.museum.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["museum.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwmap_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.map.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["map.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwjobs_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.jobs.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["jobs.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwidox_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.idox.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["idox.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwelicensing_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.elicensing.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["elicensing.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwdev_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.dev.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dev.hackney.gov.uk"]
}
resource "aws_route53_record" "wwwconsultation_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.consultation.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["cs-hackney.delib.net"]
}
resource "aws_route53_record" "webcontentapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "web-content-api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneywebsite-wp-nlb-live-2e13c709aaef64fd.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "webcontentapistaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "web-content-api-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneywebsite-wp-nlb-stg-5d354830600d65ee.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "w6ko37i2ntb35eroouedq7wis7mlxy3p_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "w6ko37i2ntb35eroouedq7wis7mlxy3p._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["w6ko37i2ntb35eroouedq7wis7mlxy3p.dkim.amazonses.com"]
}
resource "aws_route53_record" "vulnerabilities_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "vulnerabilities.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d32ivhwgr60dfx.cloudfront.net"]
}
resource "aws_route53_record" "volunteering_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "volunteering.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["defined-velociraptor-jtfri2e9ni6mazhthc21vsxk.herokudns.com"]
}
resource "aws_route53_record" "url8381_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "url8381.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["sendgrid.net"]
}
resource "aws_route53_record" "uploadshackney_gov_uk_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "uploads.hackney.gov.uk.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d-9nmg81ygoj.execute-api.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "uploads_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "uploads.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d21n8e1688tg5f.cloudfront.net"]
}
resource "aws_route53_record" "ukhakpr02_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-pr02.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ukhakpbr.hackney.gov.uk"]
}
resource "aws_route53_record" "ukhakpr01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-pr01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ukhakppr.hackney.gov.uk"]
}
resource "aws_route53_record" "ukhakbi02_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-bi02.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ukhakbts.hackney.gov.uk"]
}
resource "aws_route53_record" "ukhakbi01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-bi01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ukhakbpr.hackney.gov.uk"]
}
resource "aws_route53_record" "ugj4e51xsffksupport_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ugj4e51xsffk.support.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["gv-pigxjmww4ragw7.dv.googlehosted.com"]
}
resource "aws_route53_record" "u3g3bunanahy5atni2qux2aabwkmjv3y_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "u3g3bunanahy5atni2qux2aabwkmjv3y._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["u3g3bunanahy5atni2qux2aabwkmjv3y.dkim.amazonses.com"]
}
resource "aws_route53_record" "tmpexch2k_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "tmpexch2k.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["tmpexch2k.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "testllpg_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "testllpg.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1yrz2o0z1bwj3.cloudfront.net"]
}
resource "aws_route53_record" "testfmeserver_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "testfmeserver.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1s9i9m01njnz8.cloudfront.net"]
}
resource "aws_route53_record" "testdocumentsapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "test-documents.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d10t4o6l7dj2ps.cloudfront.net"]
}
resource "aws_route53_record" "stagingvulnerabilities_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging.vulnerabilities.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2vx80jrivqyj0.cloudfront.net"]
}
resource "aws_route53_record" "staginguploads_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging.uploads.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1du6832qtr3a8.cloudfront.net"]
}
resource "aws_route53_record" "stagingsharedplan_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging.sharedplan.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2hvjxrdp3128k.cloudfront.net"]
}
resource "aws_route53_record" "stagingmanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3e34vl2yd7riy.cloudfront.net"]
}
resource "aws_route53_record" "stagingmanagearrears_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging.managearrears.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["floating-tundra-0f0mbbufoit9948adn9hj6k8.herokudns.com"]
}
resource "aws_route53_record" "stagingetramanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging.etra.manage-a-tenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1tfi5dbtpcuq4.cloudfront.net"]
}
resource "aws_route53_record" "stagingsingleview_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-singleview.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dr04jrud0j80r.cloudfront.net"]
}
resource "aws_route53_record" "stagingmyrentaccount_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-myrentaccount.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["5bohryphdd.execute-api.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "stagingjigsawdocumentsapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-jigsaw-documents.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2exbe9ylsubn4.cloudfront.net"]
}
resource "aws_route53_record" "stagingevidencestoreapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-evidence-store.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1inlapsfmf8vr.cloudfront.net"]
}
resource "aws_route53_record" "stagingetramanageatenancyhackney_gov_uk_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-etra.manageatenancy.hackney.gov.uk.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3qq2bhhx5n3mu.cloudfront.net\\010."]
}
resource "aws_route53_record" "staging_etra_dot_manageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-etra.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3qq2bhhx5n3mu.cloudfront.net"]
}
resource "aws_route53_record" "stagingedocs_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-edocs.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d22c1jdjmtyg3n.cloudfront.net"]
}
resource "aws_route53_record" "stagingdocumentsapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-documents.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2ketx9rkw7j30.cloudfront.net"]
}
resource "aws_route53_record" "stagingdiscretionarybusinessgrants_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-discretionarybusinessgrants.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2rrnbn9sklwt9.cloudfront.net"]
}
resource "aws_route53_record" "stagingcovidbusinessgrants_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-covidbusinessgrants.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1jjf6bj5eiq61.cloudfront.net"]
}
resource "aws_route53_record" "stagingcominoprinting_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-comino-printing.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d32qlezcozdnko.cloudfront.net"]
}
resource "aws_route53_record" "stagingcominoprintingapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-comino-printing.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d32qlezcozdnko.cloudfront.net"]
}
resource "aws_route53_record" "stagingadditionalrestrictionsgrant_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-additionalrestrictionsgrant.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dmgh7kswhrczg.cloudfront.net"]
}
resource "aws_route53_record" "spacebankapistaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "spacebank-api-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneyspacebank-wp-nlb-stg-c13490c5f69df04b.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "socialcareservice_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "social-care-service.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d14m1xlgnwvsex.cloudfront.net"]
}
resource "aws_route53_record" "socialcareservicestaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "social-care-service-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1jg4cdokkwoxh.cloudfront.net"]
}
resource "aws_route53_record" "singleview_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "singleview.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1xd4kgo5foq2s.cloudfront.net"]
}
resource "aws_route53_record" "singlepoint_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "singlepoint.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["singlepoint-alb-559386657.eu-west-2.elb.amazonaws.com"]
}
resource "aws_route53_record" "sharedplanhnproto_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sharedplan.hnproto.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d30t7mzulkh5hs.cloudfront.net"]
}
resource "aws_route53_record" "sharedplan_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sharedplan.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1flmfh892poy9.cloudfront.net"]
}
resource "aws_route53_record" "services_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "services.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hlbctrial.outsystemsenterprise.com"]
}
resource "aws_route53_record" "s2_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "s2._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["s2.domainkey.u5934666.wl167.sendgrid.net"]
}
resource "aws_route53_record" "s1_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "s1._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["s1.domainkey.u5934666.wl167.sendgrid.net"]
}
resource "aws_route53_record" "residentlookup_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "resident-lookup.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2ehivh2mbh39l.cloudfront.net"]
}
resource "aws_route53_record" "residentlookupstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "resident-lookup-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d23lxbg1nzbtly.cloudfront.net"]
}
resource "aws_route53_record" "reportaproblemstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "reportaproblem.staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackney.staging.fixmystreet.com"]
}
resource "aws_route53_record" "repairs_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "repairs.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["repairs.hackney.gov.uk.herokudns.com"]
}
resource "aws_route53_record" "repairshub_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "repairs-hub.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d30dnszf6x0hiz.cloudfront.net"]
}
resource "aws_route53_record" "repairshubstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "repairs-hub-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3kjnecca5vuxz.cloudfront.net"]
}
resource "aws_route53_record" "repairshubdevelopment_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "repairs-hub-development.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2hddhcab4ynhs.cloudfront.net"]
}
resource "aws_route53_record" "rentaccount_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "rentaccount.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hlbctrial.outsystemsenterprise.com"]
}
resource "aws_route53_record" "r5ecnbopgouqgsa6uncnyrr2zag7cd5i_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "r5ecnbopgouqgsa6uncnyrr2zag7cd5i._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["r5ecnbopgouqgsa6uncnyrr2zag7cd5i.dkim.amazonses.com"]
}
resource "aws_route53_record" "qliksenseaws_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qliksenseaws.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["qlik-loading-balancer-1000445967.eu-west-2.elb.amazonaws.com"]
}
resource "aws_route53_record" "qdzpnjpyfc7hpyc62xixbbwth34z4fdy_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qdzpnjpyfc7hpyc62xixbbwth34z4fdy._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["qdzpnjpyfc7hpyc62xixbbwth34z4fdy.dkim.amazonses.com"]
}
resource "aws_route53_record" "psrp_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "psrp.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["rp.mail.myaceni.co.uk."]
}
resource "aws_route53_record" "protocollabtools_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "proto.collabtools.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dm8tw0jts2dey.cloudfront.net"]
}
resource "aws_route53_record" "propertylicensing_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "propertylicensing.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackney.metastreet.co.uk."]
}
resource "aws_route53_record" "planningapplication_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planningapplication.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1vdbpqjrw6hx5.cloudfront.net"]
}
resource "aws_route53_record" "planningapplicationstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planningapplication-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dimiil8p7fy0.cloudfront.net"]
}
resource "aws_route53_record" "opportunities_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "opportunities.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["opportunities-wp-nlb-live-7ae780b0e275fe0d.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "opportunitiesstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "opportunities-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["opportunities-wp-nlb-stg-46b2eee650a04f38.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "ngwnameserver_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ngwnameserver.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ngwns.hackney.gov.uk"]
}
resource "aws_route53_record" "nextmanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "next.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2og2hene087ad.cloudfront.net"]
}
resource "aws_route53_record" "news_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "news.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ssl-client.presspage.com"]
}
resource "aws_route53_record" "myrentaccount_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myrentaccount.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["9wqawoqv40.execute-api.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "myaccountsignon_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myaccountsignon.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "60"
  records = ["rocky-carnation-vrhc2rhnab8y1kj32iaqe6ah.herokudns.com"]
}
resource "aws_route53_record" "mosaictest_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mosaictest.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["mosaictest-hackneygovuk.msappproxy.net"]
}
resource "aws_route53_record" "map2_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "map2.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3nhdorr4s2xwq.cloudfront.net"]
}
resource "aws_route53_record" "manageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2og2hene087ad.cloudfront.net"]
}
resource "aws_route53_record" "managearrears_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "managearrears.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["stormy-tortoise-v762ehyhc5i4wobqwkd7k2qq.herokudns.com"]
}
resource "aws_route53_record" "lovecleanhackney_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lovecleanhackney.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["static.mediaklik.com"]
}
resource "aws_route53_record" "llpg_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "llpg.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1kiqnq4pbpoim.cloudfront.net"]
}
resource "aws_route53_record" "licensingpubreg_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "licensingpubreg.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["lbhdmzweb01.hackney.gov.uk"]
}
resource "aws_route53_record" "lbhmdm_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhmdm.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["https://lbhmdm01.hackney.gov.uk/mobileenrollment/ld-iosenroll.aspx."]
}
resource "aws_route53_record" "lbhcedgw01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhcedgw01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["cedar.hackney.gov.uk"]
}
resource "aws_route53_record" "lbhcedbrk01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhcedbrk01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["lbhcedbrk01.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "k1_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "k1._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dkim.mcsv.net"]
}
resource "aws_route53_record" "jvoci7bmppz7sghvpx3rxcsngia2uhgp_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "jvoci7bmppz7sghvpx3rxcsngia2uhgp._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["jvoci7bmppz7sghvpx3rxcsngia2uhgp.dkim.amazonses.com"]
}
resource "aws_route53_record" "jigsawdocumentsapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "jigsaw-documents.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d21l6oxxa6prj7.cloudfront.net"]
}
resource "aws_route53_record" "itrent_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "itrent.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["https://ce0154li.webitrent.com"]
}
resource "aws_route53_record" "irczdyaigtubqa2xvcumwnulkai4jgz2_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "irczdyaigtubqa2xvcumwnulkai4jgz2._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["irczdyaigtubqa2xvcumwnulkai4jgz2.dkim.amazonses.com"]
}
resource "aws_route53_record" "intranet_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "intranet.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneyintranet-wp-nlb-live-4bf0aa81ab916dd3.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "intranetstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "intranet-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneyintranet-wp-nlb-stg-d62704b6a2ad1798.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "inhadmin_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "inh-admin.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["opaque-kumquat-30olv9uw4ou9lg5b03cx7su1.herokudns.com"]
}
resource "aws_route53_record" "inhadmintest_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "inh-admin-test.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["limitless-peak-kjoc4bjf9fag6qk31mevjbeq.herokudns.com"]
}
resource "aws_route53_record" "hthsm01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hthsm01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hthsm01.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "hthdc01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hthdc01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hthdc01.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "hthcl01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hthcl01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hthcl01.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "hthbe01_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hthbe01.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hthbe01.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "housingwaittime_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "housingwaittime.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d16jxqe7mfnzd.cloudfront.net"]
}
resource "aws_route53_record" "heretohelp_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "here-to-help.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1544dy8zg8zex.cloudfront.net"]
}
resource "aws_route53_record" "heretohelpstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "here-to-help-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dyv0c6hbjijvj.cloudfront.net"]
}
resource "aws_route53_record" "hackneyworks_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackneyworks.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["opportunities.hackney.gov.uk"]
}
resource "aws_route53_record" "hackneyworksstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney-works.staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneyworks-wp-nlb-stg-ccb5f02ee8422e66.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "hackney_works_staging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney-works-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneyworks-wp-nlb-stg-ccb5f02ee8422e66.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "hackneymusuemdev_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney-musuem-dev.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["lbh-wp-nlb-dev-5b9a0e04f4960502.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "hackneymuseum_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney-museum.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneymuseum-wp-nlb-live-63f9f3a1026ececb.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "hackneymuseumstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney-museum-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneymuseum-wp-nlb-stg-efb519f49d7db301.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "gsuite_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "gsuite.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ghs.googlehosted.com"]
}
resource "aws_route53_record" "goinggoogle_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "goinggoogle.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ghs.googlehosted.com"]
}
resource "aws_route53_record" "frontdoorsnapshot_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "frontdoor-snapshot.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2931hk2cwex0i.cloudfront.net"]
}
resource "aws_route53_record" "frontdoorsnapshotstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "frontdoor-snapshot-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d22adgfe5f93pc.cloudfront.net"]
}
resource "aws_route53_record" "fostering_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "fostering.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["fostering.hackney.gov.uk.herokudns.com"]
}
resource "aws_route53_record" "foi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "foi.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackney-foi.mysociety.org."]
}
resource "aws_route53_record" "fmeserver_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "fmeserver.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2qjybtr2gce70.cloudfront.net"]
}
resource "aws_route53_record" "findsupportservices_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "find-support-services.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["findsupportservices-wp-nlb-live-5f5a227cc2c88d42.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "findsupportservicesstaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "find-support-services-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["findsupportservices-wp-nlb-stg-e60e563c1ca31439.elb.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "findsupportservicesstagingadmin_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "find-support-services-staging-admin.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2pmg1s29sud3k.cloudfront.net"]
}
resource "aws_route53_record" "findsupportservicesadmin_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "find-support-services-admin.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1y326dldluurf.cloudfront.net"]
}
resource "aws_route53_record" "evidence_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "evidence.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d36d8pkyfuhjc0.cloudfront.net"]
}
resource "aws_route53_record" "evidencestoreapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "evidence-store.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1juvj0uot6ph9.cloudfront.net"]
}
resource "aws_route53_record" "evidencestorestaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "evidence-store-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dkmaqx5ih0tjp.cloudfront.net"]
}
resource "aws_route53_record" "etramanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "etra.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1nq3r0ur91je7.cloudfront.net"]
}
resource "aws_route53_record" "etra_manage_a_tenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "etra.manage-a-tenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d27tr1ol0k0w70.cloudfront.net"]
}
resource "aws_route53_record" "estunjeongq3eeim3kcfxjcf6k5vlxqw_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "estunjeongq3eeim3kcfxjcf6k5vlxqw._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["estunjeongq3eeim3kcfxjcf6k5vlxqw.dkim.amazonses.com"]
}
resource "aws_route53_record" "em7520_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "em7520.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["u5934666.wl167.sendgrid.net"]
}
resource "aws_route53_record" "em6089_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "em6089.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["u12268292.wl043.sendgrid.net"]
}
resource "aws_route53_record" "ej5v5vqoq5fck5gl5lcfgeclr24bg4gv_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ej5v5vqoq5fck5gl5lcfgeclr24bg4gv._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ej5v5vqoq5fck5gl5lcfgeclr24bg4gv.dkim.amazonses.com"]
}
resource "aws_route53_record" "education_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "education.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["learningtrust.co.uk."]
}
resource "aws_route53_record" "educationevidence_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "education-evidence.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3rs16gz9m47yk.cloudfront.net"]
}
resource "aws_route53_record" "educationevidencestaging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "education-evidence-staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d22mg2n66sse9k.cloudfront.net"]
}
resource "aws_route53_record" "education_evidence_staging_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "education-evidence-.staging.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d22mg2n66sse9k.cloudfront.net"]
}
resource "aws_route53_record" "edocs_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "edocs.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d21br3didopi1d.cloudfront.net"]
}
resource "aws_route53_record" "earthlight_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "earthlight.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3lasjtu4j37yu.cloudfront.net"]
}
resource "aws_route53_record" "e5financesystem_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "e5financesystem.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["e56prod.gslb.svc.adv365.co.uk."]
}
resource "aws_route53_record" "e5financesystemtrain_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "e5financesystem-train.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["e56test.gslb.svc.adv365.co.uk."]
}
resource "aws_route53_record" "e5financesystemtest_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "e5financesystem-test.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["e56test.gslb.svc.adv365.co.uk."]
}
resource "aws_route53_record" "e5financesystemdev_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "e5financesystem-dev.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["e56test.gslb.svc.adv365.co.uk."]
}
resource "aws_route53_record" "dp2_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dp2._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dp2.domainkey.u12268292.wl043.sendgrid.net"]
}
resource "aws_route53_record" "dp_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dp._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dp.domainkey.u12268292.wl043.sendgrid.net"]
}
resource "aws_route53_record" "documentsapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "documents.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3ttyr52un5esc.cloudfront.net"]
}
resource "aws_route53_record" "discretionarybusinessgrants_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "discretionarybusinessgrants.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3lvj7o4ju545f.cloudfront.net"]
}
resource "aws_route53_record" "developerapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "developer.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2p0x8nlwan8it.cloudfront.net"]
}
resource "aws_route53_record" "devcloudapis_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "devcloudapis.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d-0md56rqfq6.execute-api.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "devetramanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dev.etra.manage-a-tenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1ig3s9n2b3ib8.cloudfront.net"]
}
resource "aws_route53_record" "devetramanageatenancyhackney_gov_uk_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dev-etra.manageatenancy.hackney.gov.uk.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1dx9uvwdfmkjz.cloudfront.net"]
}
resource "aws_route53_record" "dev_etra_dot_manageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dev-etra.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1dx9uvwdfmkjz.cloudfront.net"]
}
resource "aws_route53_record" "designsystem_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "design-system.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["lbhackney-it.github.io."]
}
resource "aws_route53_record" "playbook_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "playbook.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["lbhackney-it.github.io."]
}
resource "aws_route53_record" "democracy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "democracy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["ersvm2-sni.moderngov.co.uk."]
}
resource "aws_route53_record" "d1tfi5dbtpcuq4cloudfrontnet_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "d1tfi5dbtpcuq4.cloudfront.net.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d27tr1ol0k0w70.cloudfront.net"]
}
resource "aws_route53_record" "covidbusinessgrants_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "covidbusinessgrants.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d316ufks6stmo0.cloudfront.net"]
}
resource "aws_route53_record" "contractorrepairs_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "contractorrepairs.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["lbhdmzwebp05.ad.hackney.gov.uk"]
}
resource "aws_route53_record" "consultation_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "consultation.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["cs-hackney.delib.net"]
}
resource "aws_route53_record" "communityhelp_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "communityhelp.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["warm-snake-lylw5m5e2r1kcsa5srjm40ax.herokudns.com"]
}
resource "aws_route53_record" "community_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "community.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["tropical-butterfly-ri729ngpqe0wudzakd24axhu.herokudns.com"]
}
resource "aws_route53_record" "cominoprinting_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "comino-printing.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dw1k1yqruyf63.cloudfront.net"]
}
resource "aws_route53_record" "cominoprintingapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "comino-printing.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dw1k1yqruyf63.cloudfront.net"]
}
resource "aws_route53_record" "collabtools_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "collabtools.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["proto.collabtools.hackney.gov.uk.s3-website.eu-west-2.amazonaws.com"]
}
resource "aws_route53_record" "co2mh6tfsb34p2plutx3rt5g6awwwo5e_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "co2mh6tfsb34p2plutx3rt5g6awwwo5e._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["co2mh6tfsb34p2plutx3rt5g6awwwo5e.dkim.amazonses.com"]
}
resource "aws_route53_record" "cedartest_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "cedartest.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["cedartest-hackneygovuk.msappproxy.net"]
}
resource "aws_route53_record" "booking_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "booking.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["hackneycouncil.bookinglive.com"]
}
resource "aws_route53_record" "betasingleview_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "beta.singleview.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d1xd4kgo5foq2s.cloudfront.net"]
}
resource "aws_route53_record" "auth_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "auth.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["cryptic-pig-3xgx3sq3gxj6zwfsuw9g35vl.herokudns.com"]
}
resource "aws_route53_record" "assets_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "assets.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d2mtx3yj3nx6h5.cloudfront.net"]
}
resource "aws_route53_record" "appopportunities_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "app.opportunities.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["concave-mite-vr7dy30sifcdtds2p6to50xs.herokudns.com"]
}
resource "aws_route53_record" "additionalrestrictionsgrant_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "additionalrestrictionsgrant.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d358356fdav5ge.cloudfront.net"]
}
resource "aws_route53_record" "_f3a24e7787bbf9439e0839a55728a47atestmanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_f3a24e7787bbf9439e0839a55728a47a.test.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_b26c2ff812949c7123dbe634d332de2a.jfrzftwwjs.acm-validations.aws."]
}
resource "aws_route53_record" "_e6e49e8e610bf379349ab7f975aa9b8cvulnerabilities_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_e6e49e8e610bf379349ab7f975aa9b8c.vulnerabilities.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_7bdd40ad407c55f63f9a0a7d53504258.tfmgdnztqk.acm-validations.aws."]
}
resource "aws_route53_record" "_e582235733e3abf623eaf3354c878005devmanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_e582235733e3abf623eaf3354c878005.dev.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_6ce4eaee4e76d6e89088d31af8e31edc.jfrzftwwjs.acm-validations.aws."]
}
resource "aws_route53_record" "_d5f8ab1a951781db00d41c4328fba032betasingleview_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_d5f8ab1a951781db00d41c4328fba032.beta.singleview.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_9d3eed6ddb61438bafddacbbefa87e08.kirrbxfjtw.acm-validations.aws."]
}
resource "aws_route53_record" "_d174b680e533d34f187e7d0c00999091_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_d174b680e533d34f187e7d0c00999091.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["8561ba870365110ddea93c0a9741ce34.a9d1937d43184c12dcb15e402485062f.comodoca.com"]
}
resource "aws_route53_record" "_cbb75ccde0cf38b55c2ff991199fa257stagingmanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_cbb75ccde0cf38b55c2ff991199fa257.staging.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_0d58ddc41d45fa329d53674962a95aaa.jfrzftwwjs.acm-validations.aws."]
}
resource "aws_route53_record" "_c1ffdcfb7e6c197e206602604af52e22developerapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_c1ffdcfb7e6c197e206602604af52e22.developer.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "60"
  records = ["_748d20d6203b3fe9b50668dcc071d7b5.hkvuiqjoua.acm-validations.aws."]
}
resource "aws_route53_record" "_bd4b470e9ce35465f5bbfb067ff52377api_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_bd4b470e9ce35465f5bbfb067ff52377.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_00ba1e881c2010d14da27b636d5b9add.jfrzftwwjs.acm-validations.aws."]
}
resource "aws_route53_record" "_b833e87c150ac832703d93af49ab354b_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_b833e87c150ac832703d93af49ab354b.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["f3d3bd5de478c9e9974b17b8ec9f19dd.5a03a924262152c0611433ff8451c7c4.comodoca.com"]
}
resource "aws_route53_record" "_946e6a1f63fc8ae368c4006c7ad10dbdprotocollabtools_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_946e6a1f63fc8ae368c4006c7ad10dbd.proto.collabtools.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_b6b3d5629b58e5b5e9a4a21630e121a3.mzlfeqexyx.acm-validations.aws."]
}
resource "aws_route53_record" "_7d47b0282bdf7a38ebdf2acee9ecab22manageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_7d47b0282bdf7a38ebdf2acee9ecab22.manageatenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_dee4c8c4fe40667ce3aa217de7e457c4.jfrzftwwjs.acm-validations.aws."]
}
resource "aws_route53_record" "_5e446c2bab7f3f7435b2a78fe546ef1bhnproto_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_5e446c2bab7f3f7435b2a78fe546ef1b.hnproto.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_c42675244d357a94c463a5d855b1cbfe.vhzmpjdqfx.acm-validations.aws."]
}
resource "aws_route53_record" "_5a60e2222f10946de01b0e662aaa0901propertylicensing_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_5a60e2222f10946de01b0e662aaa0901.propertylicensing.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_42927fe6ccd4ab30e03a6103f99f7f73.tljzshvwok.acm-validations.aws."]
}
resource "aws_route53_record" "_4051fd02ef9d1266b600af676f94ba5fapi_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_4051fd02ef9d1266b600af676f94ba5f.api.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "60"
  records = ["_93619baa0bc7c91acd3154aafff2f7fc.hkvuiqjoua.acm-validations.aws."]
}
resource "aws_route53_record" "_3cd394184f1052ee3ab61ac6af04a71f_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_3cd394184f1052ee3ab61ac6af04a71f.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["245dbe4b9774dc417cec86b1839ab4c8.6c752cc9718f972d30ea42f4dbbece52.comodoca.com"]
}
resource "aws_route53_record" "_3033f8490ec2e593d3723b9009c0188bsharedplan_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_3033f8490ec2e593d3723b9009c0188b.sharedplan.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_201a1008155ae2d55e9b37a059e8de37.auiqqraehs.acm-validations.aws."]
}
resource "aws_route53_record" "_06962c3b37754252412506587f7b91eaetramanageatenancy_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_06962c3b37754252412506587f7b91ea.etra.manage-a-tenancy.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_3669664cb36b76b00667173646c69c9e.duyqrilejt.acm-validations.aws."]
}
resource "aws_route53_record" "_6dbrd5dpdo4qq3kcssmssinefeiyly2y_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "6dbrd5dpdo4qq3kcssmssinefeiyly2y._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["6dbrd5dpdo4qq3kcssmssinefeiyly2y.dkim.amazonses.com"]
}
resource "aws_route53_record" "_42jtt6z7nlsw6jcxyrjxfm2h7kws5vxk_domainkey_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "42jtt6z7nlsw6jcxyrjxfm2h7kws5vxk._domainkey.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["42jtt6z7nlsw6jcxyrjxfm2h7kws5vxk.dkim.amazonses.com"]
}
resource "aws_route53_record" "wildcardvulnerabilities_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "*.vulnerabilities.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_7bdd40ad407c55f63f9a0a7d53504258.tfmgdnztqk.acm-validations.aws."]
}
resource "aws_route53_record" "wildcardsharedplan_hackney_gov_uk_cname" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "*.sharedplan.hackney.gov.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["_201a1008155ae2d55e9b37a059e8de37.auiqqraehs.acm-validations.aws."]
}
