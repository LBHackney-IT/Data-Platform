#!/usr/bin/env bash

set -euo pipefail

readonly plan_path="${1:-plan.out}"
readonly maximum_size=10240

failed=0

policy_sizes=$(
  terraform show -json "$plan_path" |
    jq -r '
      .resource_changes[]?
      | select(.type == "aws_ssoadmin_permission_set_inline_policy")
      | select(.change.after != null)
      | if (
          .change.after_unknown.inline_policy? == true
          or (.change.after.inline_policy | type) != "string"
        )
        then [.address, "unknown", 0]
        else [
          .address,
          "known",
          (.change.after.inline_policy | gsub("\\s"; "") | utf8bytelength)
        ]
        end
      | @tsv
    '
)

if [[ -n "$policy_sizes" ]]; then
  while IFS=$'\t' read -r address status size; do
    if [[ "$status" == "unknown" ]]; then
      echo "::error title=SSO inline policy size unknown::${address} has an unknown inline_policy value, so its size cannot be checked."
      failed=1
    elif ((size > maximum_size)); then
      echo "::error title=SSO inline policy too large::${address} contains ${size} non-whitespace UTF-8 bytes; the AWS maximum is ${maximum_size}."
      failed=1
    else
      echo "${address}: ${size} non-whitespace UTF-8 bytes"
    fi
  done <<<"$policy_sizes"
fi

exit "$failed"
