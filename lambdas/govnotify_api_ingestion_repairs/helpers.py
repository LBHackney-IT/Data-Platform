# GovNotify queries to retrieve
api_queries = ['notifications', 'received_text_messages']
api_queries_dict = {
    'notifications': {'query': client.get_all_notifications(include_jobs=True),
                      'file_name': 'notifications'},
    'received_text_messages': {'query': client.get_received_texts(),
                               'file_name': 'received_text_messages'}
}