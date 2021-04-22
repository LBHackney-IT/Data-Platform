resource "aws_route53_record" "txt_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "txt.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["google-site-verification=uzN7l8HlBoliAOGG6NeykRqOmoefE-q6hSVtBj-ZlAs"]
}

resource "aws_route53_record" "test_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "test.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["google-site-verification=pq9P_qPX13HaP9SrQX8VV6VUxpeH64w9ZmyuhK0MIBs"]
}

resource "aws_route53_record" "support_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "support.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["google-site-verification=L55smpw68AUdRsbQLOjWu3JcLWldnJpoELaG8hiju1M"]
}

resource "aws_route53_record" "spf3_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "spf3.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 ip4:5.153.254.68 ip4:185.3.164.117 ip4:217.68.71.26 ip4:217.68.71.27 ip4:34.252.75.139  ip4:34.250.4.133 ip4:205.201.128.0/20 ip4:198.2.128.0/18 ip4:148.105.8.0/21 include:spf.mandrillapp.com ~all"]
}

resource "aws_route53_record" "spf2_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "spf2.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 ip4:156.61.250.239 ip4:34.231.49.44 ip4:54.152.112.232 ip4:52.45.180.181 ip4:85.115.32.0/19 ip4:86.111.216.0/23 ip4:86.111.220.0/22 ip4:54.240.51.165 ip4:194.79.241.115 ip6:2002:9c3d:29f7::9c3d:29f7 include:recruitmail.com ~all"]
}

resource "aws_route53_record" "spf1_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "spf1.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 a ip4:63.146.199.0/24 ip4:204.14.232.0/22 ip4:195.244.16.20 ip4:81.144.190.98 ip4:83.222.226.128 ip4:212.140.253.0/24 ip4:78.153.223.178 ip4:212.21.101.140/24 ip4:205.138.36.10 ~all"]
}

resource "aws_route53_record" "postalireziq_domainkey_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "postal-ireziq._domainkey.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DKIM1; t=s; h=sha256; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQClCLd4b+gobVq/zLN7BUbbbgyyn\"\"slfLYnwzpVdjwtOPWXdGKEurfE2IhFLueen6m+p4/OPl4ymdEU8NxdtTMHoW2ZmfmDe3+iS/FS8/NLAvUpVfQKYf6WsWzPw7Zcy6O6A4OFezmrpa9EoHiUElYYyopwHS9lbj3R31r4EzCZbIQIDAQAB;"]
}

resource "aws_route53_record" "postalilowdm_domainkey_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "postal-ilowdm._domainkey.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DKIM1; t=s; h=sha256; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDXSlylopHtgaV52/husYDyWhljT9YaPNnS85cyGVLBXVfyFtsTdOwzlEsnJXW/tB15ifAueG+H9EOcWFV0uXyGljxLy8ROL5pnoXBN2z0Q4HMUXvHniIq5sIqx06HguhPh1PssOhXI0HGdJNp7bP3zHxqcoepx2xN2uiDpVHzQKwIDAQAB;"]
}

resource "aws_route53_record" "planning1test_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planning1.test.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["google-site-verification=K9XHX0OR2LNML0AAwGVKQW9IPo1PfsYi7gM6ImSbv3k"]
}

resource "aws_route53_record" "planning_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planning.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 include:spf.mandrillapp.com ?all", "google-site-verification=5d86huNIlhvnhgY4w7-UrlelJHqoLPgPIx2dujH4P7A"]
}

resource "aws_route53_record" "mandrill_domainkeyplanning_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mandrill._domainkey.planning.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrLHiExVd55zd/IQ/J/mRwSRMAocV/hMB3jXwaHH36d9NaVynQFYV8NaWi69c1veUtRzGt7yAioXqLj7Z4TeEUoOLgrKsn8YnckGs9i3B3tVFB+Ch/4mPhXWiNfNdynHWBcPcbJ8kjEQ2U8y78dHZj1YeRXXVvWob2OaKynO8/lQIDAQAB;"]
}

resource "aws_route53_record" "mandrill_domainkey_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mandrill._domainkey.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrLHiExVd55zd/IQ/J/mRwSRMAocV/hMB3jXwaHH36d9NaVynQFYV8NaWi69c1veUtRzGt7yAioXqLj7Z4TeEUoOLgrKsn8YnckGs9i3B3tVFB+Ch/4mPhXWiNfNdynHWBcPcbJ8kjEQ2U8y78dHZj1YeRXXVvWob2OaKynO8/lQIDAQAB;"]
}

resource "aws_route53_record" "hackney_gov_uk_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney.gov.uk.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["MS=5DDC360BF52E231628FB5655ED6560403B0F4B5A"]
}

resource "aws_route53_record" "hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["apple-domain-verification=6KqQjx1oCnzuaE8q", "apple-domain-verification=IaFIIGQcbfBVBwZA", "android-mdm-enroll=https://lbhmdm01.hackney.gov.uk/mobileenrollment/ld-androidenroll.aspx", "MS=5DDC360BF52E231628FB5655ED6560403B0F4B5A", "npnvkrcmj01epvsqguc78r9plm", "v=spf1 a  include:spf.mail.myaceni.co.uk include:spf1.hackney.gov.uk include:spf2.hackney.gov.uk include:spf3.hackney.gov.uk ~all", "amazonses:+65IPQ/qjsCwJfkm+20GMD5BrzifDic3gheEy7bavBg=", "yDf3IPmvTaYdUGVfAjWg5kXEwhLKo/1AjceXRYYoRvkJ+8BZy9jKEuBBR2yvr8A6wkHfz3URpOl0vNrEam3N5A==", "google-site-verification=L55smpw68AUdRsbQLOjWu3JcLWldnJpoELaG8hiju1M", "0kzJ28FjGoVFb6Fh2EZZJGp6/rSYUD79Ex4/s9cClBY=", "google-site-verification=v8MsRisD0QCGDI-7QcfA20sd6Ul1DgHwz8p3UD1UMHg", "LDLAUNCHPAD=https://lbhmdm01.hackney.gov.uk/launchpad.cloud", "google-site-verification=uzN7l8HlBoliAOGG6NeykRqOmoefE-q6hSVtBj-ZlAs", "QTIHH6FNHCELNQGB9I3D6L59QLCY8VWUL6N8PYXR", "_amazonses:FuZGCB0GXkXa7AeCgSCBLcBhTiu25xcfGZok3wGx6/Q=", "globalsign-domain-verification=qKrH5g2bU2luBr1lYJH4wMgheANOFIMmphTitsAQxj", "OSIAGENTREGURL=https://lbhmdm01.hackney.gov.uk/mobileenrollment/ld-iosenroll.aspx"]
}

resource "aws_route53_record" "google_domainkey_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "google._domainkey.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAylj+g9kX4dhjb9vYnfM8TGeB4bd4PvsYBcuUMsiT9kwiQvl/6hiRzVu0nusxjWd9DNOGD3JlBJfwUuqSWEE/XvIHn/Nj\"\"VGc5X3pNP9sUjLSSaoeNNS7Ui+QUttQ0pIHegft3fES9QT949XGlYV+5zoDzdN5wvO4dnIWjShZXcKQKX25fbKnr0dyH6hgUSUt4pf/IMGn2JM5a3HZnONIMtFx2EMz4Q8S7ydXxxHdWeeZHbks\"\"+Re0hBtAPztWs3o+poSGHMAheCwZ9Bmsv4RQB/kU66nNFZwwjdJqf6kyGJNzfhbeZPtqzjfpsrHtKquzM826G4sVc/cbNjm15mzrayQIDAQAB"]
}

resource "aws_route53_record" "dwpcis_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "dwp-cis.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["QuoVadis=5c956c9-bfd8-4ec9-acbf-7c7e761d14d6"]
}

resource "aws_route53_record" "_domainkeyplanning_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_domainkey.planning.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrLHiExVd55zd/IQ/J/mRwSRMAocV/hMB3jXwaHH36d9NaVynQFYV8NaWi69c1veUtRzGt7yAioXqLj7Z4TeEUoOLgrKsn8YnckGs9i3B3tVFB+Ch/4mPhXWiNfNdynHWBcPcbJ8kjEQ2U8y78dHZj1YeRXXVvWob2OaKynO8/lQIDAQAB;"]
}

resource "aws_route53_record" "_dmarc_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_dmarc.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DMARC1;p=none;rua=mailto:dmarcreports@hackney.gov.uk"]
}

resource "aws_route53_record" "_amazonses_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_amazonses.hackney.gov.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["+65IPQ/qjsCwJfkm+20GMD5BrzifDic3gheEy7bavBg=", "FuZGCB0GXkXa7AeCgSCBLcBhTiu25xcfGZok3wGx6/Q="]
}

resource "aws_route53_record" "_acmechallengedeviceenrollment_hackney_gov_uk_txt" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_acme-challenge.deviceenrollment.hackney.gov.uk"
  type    = "TXT"
  ttl     = "60"
  records = ["GFiA8nuOIq2S4peaxs-oUW1xW_WdKIIoNMn68Mt2OFE"]
}
