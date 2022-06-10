from unittest import TestCase
import os
import json
import requests
import botocore.session
from botocore.stub import Stubber

BASE_URL = "https://hackneyreports.icasework.com/getreport?"

