from dateutil.relativedelta import *
import boto3
import datetime
import json
import os

def lambda_handler(event, context):
    
    cost_explorer_client = boto3.client('ce')
    
    end = datetime.date.today().replace(day=1)
    start = end + relativedelta(months=-3)
    
    start = start.strftime("%Y-%m-%d")
    end = end.strftime("%Y-%m-%d")
    
    response = cost_explorer_client.get_cost_and_usage(
        Granularity='MONTHLY',
        Metrics=[
            'UnblendedCost',
        ],
        TimePeriod={
            'Start': start,
            'End': end,
        },
    )
    
    avg = 0
    
    for result in response['ResultsByTime']:
        total = result['Total']
        cost = total['UnblendedCost']
        amount = int(float(cost['Amount']))
        avg = avg + amount
    
    avg = int(avg/3)
    budget = str(avg)
        
    log({
        'average': avg,
        'budget': budget,
        'end': end,
        'level': 'debug',
        'start': start,
    })
    
    budget_client = boto3.client('budgets')
    
    accountId = os.environ['AccountId']

    budget_client.update_budget(
        AccountId=accountId,
        NewBudget={
            'BudgetName': 'actual-cost-budget',
            'BudgetType': 'COST',
            'BudgetLimit':{
                'Amount' : f'{budget}',
                'Unit': 'USD'
            }, 
        'TimeUnit': 'MONTHLY'
        }
    )

    budget_client.update_budget(
        AccountId=accountId,
        NewBudget={
            'BudgetName': 'forecast-cost-budget',
            'BudgetType': 'COST',
            'BudgetLimit':{
                'Amount' : f'{budget}',
                'Unit': 'USD'
            }, 
        'TimeUnit': 'MONTHLY'
        }
    )


def log(msg):
     print(json.dumps(msg), flush=True)
