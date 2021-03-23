# 2. Ingest Google Sheets Data

Date: 2021-03-23

## Status

Accepted

## Context

Hackney currently have datasets distributed over a number of different Google Sheets Documents due their data recovery
efforts. We need to get this information pulled into the data platform for processing.

## Decision

We will use a python based AWS Glue Job in conjunction with the gspread python library to pull the data onto platform

## Consequences

Having the code sit with AWS Glue makes the data import easier to keep consistent with the rest of the platform but
leaves us dependent on being able to import the gspread library into the AWS Glue job and requires that we access
credentials from Google Workspace
