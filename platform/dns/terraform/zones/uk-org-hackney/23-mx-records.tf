resource "aws_route53_record" "test_hackney_gov_uk_mx" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "test.hackney.gov.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["10 alt3.aspmx.l.google.com", "10 alt4.aspmx.l.google.com", "1 aspmx.l.google.com", "5 alt1.aspmx.l.google.com", "5 alt2.aspmx.l.google.com"]
}

resource "aws_route53_record" "securedata_hackney_gov_uk_mx" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "securedata.hackney.gov.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["50 mail2.cableinet.net", "10 ms1.hackney.gov.uk", "20 ms2.hackney.gov.uk"]
}

resource "aws_route53_record" "planning_hackney_gov_uk_mx" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "planning.hackney.gov.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["20 30504431.in2.mandrillapp.com", "10 30504431.in1.mandrillapp.com"]
}

resource "aws_route53_record" "mail_hackney_gov_uk_mx" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "mail.hackney.gov.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["20 ms2.hackney.gov.uk", "50 mail2.cableinet.net", "10 ms2.hackney.gov.uk"]
}

resource "aws_route53_record" "hackney_gov_uk_mx" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "hackney.gov.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["10 alt4.aspmx.l.google.com", "1 aspmx.l.google.com", "5 alt1.aspmx.l.google.com", "10 alt3.aspmx.l.google.com", "5 alt2.aspmx.l.google.com"]
}

resource "aws_route53_record" "gw_hackney_gov_uk_mx" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "gw.hackney.gov.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["10 ms1.hackney.gov.uk", "50 mail2.cableinet.net", "20 ms2.hackney.gov.uk"]
}
