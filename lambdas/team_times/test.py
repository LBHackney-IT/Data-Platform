import unittest
from io import StringIO
import xml.etree.ElementTree as ET
import csv
from team_times.main import xml_to_csv


class TestXMLToCSVConversion(unittest.TestCase):
    def test_xml_to_csv_conversion(self):
        xml_data = """<?xml version="1.0" encoding="utf-8"?>
<TimeSheet>
    <Employee>
        <USERID>921</USERID>
        <DEPARTMENT>Parking Services</DEPARTMENT>
        <NAME>tom</NAME>
        <SURNAME>tiddy</SURNAME>
        <EMAIL>tom.tiddy@kjhfdg.com</EMAIL>
        <STAFFTYPE>Permanent</STAFFTYPE>
        <SUBMITTED>True</SUBMITTED>
        <DATE>28/02/2024</DATE>
        <OPTION1>In The Office</OPTION1>
        <OPTION2></OPTION2>
        <STARTTIME>09:00:00</STARTTIME>
        <STARTBREAK>13:00:00</STARTBREAK>
        <ENDBREAK>13:30:00</ENDBREAK>
        <ENDTIME></ENDTIME>
        <OPTIONVAUE>0:00</OPTIONVAUE>
        <TOTALTIME></TOTALTIME>
    </Employee>
</TimeSheet>"""

        expected_csv = StringIO()
        writer = csv.writer(expected_csv)
        headers = [
            "USERID",
            "DEPARTMENT",
            "NAME",
            "SURNAME",
            "EMAIL",
            "STAFFTYPE",
            "SUBMITTED",
            "DATE",
            "OPTION1",
            "OPTION2",
            "STARTTIME",
            "STARTBREAK",
            "ENDBREAK",
            "ENDTIME",
            "OPTIONVAUE",
            "TOTALTIME",
        ]
        writer.writerow(headers)
        row = [
            "921",
            "Parking Services",
            "tom",
            "tiddy",
            "tom.tiddy@kjhfdg.com",
            "Permanent",
            "True",
            "28/02/2024",
            "In The Office",
            "",
            "09:00:00",
            "13:00:00",
            "13:30:00",
            "",
            "0:00",
            "",
        ]
        writer.writerow(row)
        expected_csv.seek(0)

        actual_csv = xml_to_csv(xml_data)
        self.assertEqual(actual_csv.getvalue().strip(), expected_csv.getvalue().strip())


if __name__ == "__main__":
    unittest.main()
