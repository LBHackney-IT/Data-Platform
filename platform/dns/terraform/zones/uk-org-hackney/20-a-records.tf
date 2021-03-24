resource "aws_route53_record" "www2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www2.hackney.gov.uk."
  type    = "A"
  ttl     = "60"
  records = ["156.61.16.20"]
}

resource "aws_route53_record" "www_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "www.hackney.gov.uk."
  type    = "A"
  ttl     = "120"
  records = ["104.198.14.52"]
}

resource "aws_route53_record" "wshackneypublic_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ws-hackneypublic.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.23"]
}

resource "aws_route53_record" "wshackneygeneral_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ws-hackneygeneral.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.21"]
}

resource "aws_route53_record" "wendy_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "wendy.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.39"]
}

resource "aws_route53_record" "webmail_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "webmail.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.25"]
}

resource "aws_route53_record" "webforms_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "webforms.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.98"]
}

resource "aws_route53_record" "waste_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "waste.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.172"]
}

resource "aws_route53_record" "video_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "video.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.47"]
}

resource "aws_route53_record" "ukhakwts_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-wts.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.20"]
}

resource "aws_route53_record" "ukhakwpr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-wpr.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.10"]
}

resource "aws_route53_record" "ukhakwim_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-wim.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.40"]
}

resource "aws_route53_record" "ukhakwht_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-wht.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.5"]
}

resource "aws_route53_record" "ukhaksts_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-sts.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.25"]
}

resource "aws_route53_record" "ukhakstr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-str.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.65"]
}

resource "aws_route53_record" "ukhakspr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-spr.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.15"]
}

resource "aws_route53_record" "ukhakpts_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-pts.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.17"]
}

resource "aws_route53_record" "ukhakppr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-ppr.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.17"]
}

resource "aws_route53_record" "ukhakpbr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-pbr.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.27"]
}

resource "aws_route53_record" "ukhakcsp_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-csp.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.7"]
}

resource "aws_route53_record" "ukhakbts_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-bts.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.16"]
}

resource "aws_route53_record" "ukhakbpr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ukhak-bpr.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["172.29.84.26"]
}

resource "aws_route53_record" "timesheets_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "timesheets.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.134"]
}

resource "aws_route53_record" "testwww_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "testwww.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.73"]
}

resource "aws_route53_record" "testsupport_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "testsupport.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.170"]
}

resource "aws_route53_record" "testmail_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "testmail.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.74"]
}

resource "aws_route53_record" "testignore_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "testignore.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["10.10.10.10"]
}

resource "aws_route53_record" "tester_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "tester.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.0.25"]
}

resource "aws_route53_record" "support_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "support.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.75"]
}

resource "aws_route53_record" "studnt15_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "studnt15.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.27"]
}

resource "aws_route53_record" "studnt14_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "studnt14.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.25"]
}

resource "aws_route53_record" "studnt13_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "studnt13.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.24"]
}

resource "aws_route53_record" "studnt12_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "studnt12.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.23"]
}

resource "aws_route53_record" "studnt11_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "studnt11.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.22"]
}

resource "aws_route53_record" "studnt10_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "studnt10.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.21"]
}

resource "aws_route53_record" "streetscene_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "streetscene.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.139"]
}

resource "aws_route53_record" "stagingprocesses_dot_manageatenancy_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-processes.manageatenancy.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.226"]
}

resource "aws_route53_record" "stagingprocesses_manageatenancy_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staging-processes-manageatenancy.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.226"]
}

resource "aws_route53_record" "staffroom_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staffroom.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.141"]
}

resource "aws_route53_record" "staffnews_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "staffnews.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["217.172.128.131"]
}

resource "aws_route53_record" "sportbookings_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sportbookings.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["212.46.129.196"]
}

resource "aws_route53_record" "smowm02_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "smowm02.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.35"]
}

resource "aws_route53_record" "smowm01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "smowm01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.25"]
}

resource "aws_route53_record" "smolib01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "smolib01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.89.11"]
}

resource "aws_route53_record" "smodns01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "smodns01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.53.42"]
}

resource "aws_route53_record" "sidem_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sidem.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.48"]
}

resource "aws_route53_record" "sftp_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sftp.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.65"]
}

resource "aws_route53_record" "servicedesk_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "servicedesk.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.237"]
}

resource "aws_route53_record" "selfservice_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "selfservice.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["152.114.220.121"]
}

resource "aws_route53_record" "securemail_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "securemail.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.72"]
}

resource "aws_route53_record" "secure_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "secure.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.54"]
}

resource "aws_route53_record" "sandboxapi2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sandboxapi2.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.93"]
}

resource "aws_route53_record" "sandboxapi_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "sandboxapi.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.109"]
}

resource "aws_route53_record" "repairsapitest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "repairsapitest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.106"]
}

resource "aws_route53_record" "remotemyoffice_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "remote-myoffice.hackney.gov.uk."
  type    = "A"
  ttl     = "60"
  records = ["156.61.16.83"]
}

resource "aws_route53_record" "reddot_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "reddot.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.10"]
}

resource "aws_route53_record" "recruitment_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "recruitment.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["213.138.109.152"]
}

resource "aws_route53_record" "rbox_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "rbox.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.190"]
}

resource "aws_route53_record" "qms_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qms.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.139"]
}

resource "aws_route53_record" "qlikview_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qlikview.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.88"]
}

resource "aws_route53_record" "qliksense2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qliksense2.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.92"]
}

resource "aws_route53_record" "qliksense_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qliksense.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.91"]
}

resource "aws_route53_record" "qlik_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "qlik.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.130"]
}

resource "aws_route53_record" "psrtest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "psrtest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.114"]
}

resource "aws_route53_record" "psr_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "psr.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.117"]
}

resource "aws_route53_record" "prt_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "prt.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.79"]
}

resource "aws_route53_record" "processes_dot_manageatenancy_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "processes.manageatenancy.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.227"]
}

resource "aws_route53_record" "processes_manageatenancy_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "processes-manageatenancy.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.227"]
}

resource "aws_route53_record" "pod9_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod9.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.19"]
}

resource "aws_route53_record" "pod8_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod8.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.18"]
}

resource "aws_route53_record" "pod7_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod7.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.17"]
}

resource "aws_route53_record" "pod6_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod6.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.16"]
}

resource "aws_route53_record" "pod5_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod5.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.15"]
}

resource "aws_route53_record" "pod4_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod4.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.14"]
}

resource "aws_route53_record" "pod3sc_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod3sc.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.76"]
}

resource "aws_route53_record" "pod3_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod3.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.75"]
}

resource "aws_route53_record" "pod2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod2.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.73"]
}

resource "aws_route53_record" "pod10_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod10.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.20"]
}

resource "aws_route53_record" "pod1_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pod1.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["86.17.5.72"]
}

resource "aws_route53_record" "planningdocs_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planningdocs.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.104"]
}

resource "aws_route53_record" "planningapps_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planningapps.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["185.38.149.156"]
}

resource "aws_route53_record" "planning_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planning.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.28"]
}

resource "aws_route53_record" "permits_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "permits.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.172"]
}

resource "aws_route53_record" "pcns_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pcns.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.154"]
}

resource "aws_route53_record" "pcbooking_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "pcbooking.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.38"]
}

resource "aws_route53_record" "parkingpermit_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "parkingpermit.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.66"]
}

resource "aws_route53_record" "parkingdisputes_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "parkingdisputes.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.152"]
}

resource "aws_route53_record" "parkingdb_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "parkingdb.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.140"]
}

resource "aws_route53_record" "parking_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "parking.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.97"]
}

resource "aws_route53_record" "outlookanywhere_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "outlookanywhere.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.161"]
}

resource "aws_route53_record" "oneaccounttest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "oneaccounttest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.38"]
}

resource "aws_route53_record" "ngwns_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ngwns.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.3.6"]
}

resource "aws_route53_record" "nccportal_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "nccportal.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.138"]
}

resource "aws_route53_record" "ncccallback_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ncccallback.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.90"]
}

resource "aws_route53_record" "ncc_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ncc.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.137"]
}

resource "aws_route53_record" "mywebmail_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mywebmail.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.35"]
}

resource "aws_route53_record" "mytoken_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mytoken.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.103"]
}

resource "aws_route53_record" "myofficetest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myofficetest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.53.221"]
}

resource "aws_route53_record" "myoffice_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myoffice.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.214", "156.61.16.213", "156.61.16.224", "156.61.16.223"]
}

resource "aws_route53_record" "myhackney_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myhackney.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.55"]
}

resource "aws_route53_record" "myapps1_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myapps1.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.79"]
}

resource "aws_route53_record" "myaccount_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "myaccount.hackney.gov.uk."
  type    = "A"
  ttl     = "1"
  records = ["156.61.16.68"]
}

resource "aws_route53_record" "museum_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "museum.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.58"]
}

resource "aws_route53_record" "mps2cctv_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mps2.cctv.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.59"]
}

resource "aws_route53_record" "mpscctv_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mps.cctv.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.51", "80.235.235.195"]
}

resource "aws_route53_record" "mosaic_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mosaic.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.115"]
}

resource "aws_route53_record" "mobiletest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mobiletest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.99"]
}

resource "aws_route53_record" "mobilesam_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mobilesam.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.80"]
}

resource "aws_route53_record" "mobilelive_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mobilelive.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.101"]
}

resource "aws_route53_record" "mobiledev_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mobiledev.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.100"]
}

resource "aws_route53_record" "mginternet_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mginternet.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.46"]
}

resource "aws_route53_record" "mgextranet_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mgextranet.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.78"]
}

resource "aws_route53_record" "membersupdate_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "membersupdate.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["217.172.128.131"]
}

resource "aws_route53_record" "map_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "map.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.30"]
}

resource "aws_route53_record" "manageatenancytest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "manageatenancy-test.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.226"]
}

resource "aws_route53_record" "maintenance_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "maintenance.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.172"]
}

resource "aws_route53_record" "m3_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "m3.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.65"]
}

resource "aws_route53_record" "localhost_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "localhost.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["127.0.0.1"]
}

resource "aws_route53_record" "licences_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "licences.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.172"]
}

resource "aws_route53_record" "library_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "library.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["81.144.190.114"]
}

resource "aws_route53_record" "legacy_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "legacy.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.35"]
}

resource "aws_route53_record" "lbhtstexccaht02_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhtstexccaht02_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.243"]
}

resource "aws_route53_record" "lbhtstexccaht01_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhtstexccaht01_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.242"]
}

resource "aws_route53_record" "lbhmosaicappt01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhmosaicappt01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.87"]
}

resource "aws_route53_record" "lbhmosaicappp02_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhmosaicappp02.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.53.231"]
}

resource "aws_route53_record" "lbhmdm01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhmdm01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.96"]
}

resource "aws_route53_record" "lbhexccahtp05nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhexccahtp05nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.239"]
}

resource "aws_route53_record" "lbhexccahtp05_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhexccahtp05_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.239"]
}

resource "aws_route53_record" "lbhexccahtp04_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhexccahtp04_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.243"]
}

resource "aws_route53_record" "lbhexccahtp03_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhexccahtp03_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.242"]
}

resource "aws_route53_record" "lbhexccaht02_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhexccaht02_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.241"]
}

resource "aws_route53_record" "lbhexccaht01_nat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhexccaht01_nat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.240"]
}

resource "aws_route53_record" "lbhdmzwscg03_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhdmzwscg03.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.23"]
}

resource "aws_route53_record" "lbhdmzwscg02_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhdmzwscg02.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.22"]
}

resource "aws_route53_record" "lbhdmzwscg01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhdmzwscg01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.21"]
}

resource "aws_route53_record" "lbhdmzweb01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhdmzweb01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.31"]
}

resource "aws_route53_record" "lbhbomgarappp01_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "lbhbomgarappp01.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.160"]
}

resource "aws_route53_record" "kofaxftptest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "kofaxftptest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.121"]
}

resource "aws_route53_record" "kofaxftp_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "kofaxftp.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.120"]
}

resource "aws_route53_record" "kimoffice_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "kimoffice.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.83"]
}

resource "aws_route53_record" "kemplb_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "kemplb.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.53.218"]
}

resource "aws_route53_record" "jobs_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "jobs.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.15"]
}

resource "aws_route53_record" "ivantidev_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ivanti-dev.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.239"]
}

resource "aws_route53_record" "intranet2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "intranet2.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["35.177.56.90"]
}

resource "aws_route53_record" "incomeapitest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "incomeapitest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.107"]
}

resource "aws_route53_record" "idox_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "idox.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.53"]
}

resource "aws_route53_record" "hwyscctv_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hwys.cctv.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.57"]
}

resource "aws_route53_record" "housingnews_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "housingnews.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["217.172.128.131"]
}

resource "aws_route53_record" "hackneyvc_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackneyvc.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.42"]
}

resource "aws_route53_record" "hackneylive_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackneylive.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.27.7"]
}

resource "aws_route53_record" "hackneyhero_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackneyhero.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.36"]
}

resource "aws_route53_record" "hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["104.198.14.52"]
}

resource "aws_route53_record" "goss_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "goss.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.103"]
}

resource "aws_route53_record" "ex2010owa_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ex2010owa.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.80"]
}

resource "aws_route53_record" "ex2010_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ex2010.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.161"]
}

resource "aws_route53_record" "ews_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "ews.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.161"]
}

resource "aws_route53_record" "etonattachments_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "etonattachments.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.44"]
}

resource "aws_route53_record" "eton_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "eton.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.44"]
}

resource "aws_route53_record" "epscctv_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "eps.cctv.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.50", "80.235.235.194"]
}

resource "aws_route53_record" "enforcement_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "enforcement.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["82.148.231.149"]
}

resource "aws_route53_record" "elicensing_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "elicensing.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.15"]
}

resource "aws_route53_record" "eforms_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "eforms.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.15"]
}

resource "aws_route53_record" "e5reportingsystem_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "e5reportingsystem.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["217.68.68.147"]
}

resource "aws_route53_record" "drs_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "drs.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.133"]
}

resource "aws_route53_record" "devsupport_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "devsupport.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.149"]
}

resource "aws_route53_record" "devscp_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "devscp.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.208"]
}

resource "aws_route53_record" "deviceenrollment_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "deviceenrollment.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.105"]
}

resource "aws_route53_record" "dev_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dev.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.10"]
}

resource "aws_route53_record" "devmanageatenancyapisandboxapi2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dev-manage-a-tenancy-api.sandboxapi2.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.93"]
}

resource "aws_route53_record" "desktopuat64bitad_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "desktopuat64bit.ad.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.83"]
}

resource "aws_route53_record" "desktop_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "desktop.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.95"]
}

resource "aws_route53_record" "declarationofinterest_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "declarationofinterest.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.238"]
}

resource "aws_route53_record" "contractors_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "contractors.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.181"]
}

resource "aws_route53_record" "childviewedocs_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "childviewedocs.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.85"]
}

resource "aws_route53_record" "chat_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "chat.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.180"]
}

resource "aws_route53_record" "centhack8_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack8.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.18"]
}

resource "aws_route53_record" "centhack7_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack7.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.17"]
}

resource "aws_route53_record" "centhack6_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack6.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.16"]
}

resource "aws_route53_record" "centhack5_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack5.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.15"]
}

resource "aws_route53_record" "centhack4_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack4.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.14"]
}

resource "aws_route53_record" "centhack3_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack3.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.13"]
}

resource "aws_route53_record" "centhack2_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack2.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.12"]
}

resource "aws_route53_record" "centhack1_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "centhack1.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.100.11"]
}

resource "aws_route53_record" "cedar_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "cedar.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.250.64"]
}

resource "aws_route53_record" "bomgar_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "bomgar.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.160"]
}

resource "aws_route53_record" "blogs_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "blogs.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["46.101.3.169"]
}

resource "aws_route53_record" "bellclubcctv_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "bellclub.cctv.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.106"]
}

resource "aws_route53_record" "autodiscover_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "autodiscover.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.161"]
}

resource "aws_route53_record" "apps_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "apps.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.10"]
}

resource "aws_route53_record" "api_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "api.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.108"]
}

resource "aws_route53_record" "adfsad_hackney_gov_uk_a" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "adfs.ad.hackney.gov.uk."
  type    = "A"
  ttl     = "3600"
  records = ["156.61.16.70"]
}
