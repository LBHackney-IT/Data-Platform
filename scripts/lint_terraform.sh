#!/bin/bash

for TFFILE in $(find . -name '*.tf');
do
  tflint $TFFILE
done;
