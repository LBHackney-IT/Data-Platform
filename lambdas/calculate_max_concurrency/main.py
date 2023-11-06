def calculate_max_concurrency(available_ips: int, ips_per_job: int) -> int:
    return int(available_ips / ips_per_job)


def lambda_handler(event, context):
    available_ips = event["available_ips"]
    ips_per_job = event["ips_per_job"]
    max_concurrency = calculate_max_concurrency(available_ips, ips_per_job)
    return {"max_concurrency": max_concurrency}


if __name__ == "__main__":
    lambda_handler("event", "lambda_context")
