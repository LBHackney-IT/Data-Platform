variable "worksheets" {
  type = map(
    object({
      header_row_number = number
      worksheet_name    = string
    })
  )
  default = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "1"
    }
  }
}
