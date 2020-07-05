def get_new_cases(selected_slug):
    import requests
    import pandas as pd
    from datetime import datetime, timedelta
    
    day_0 = datetime.now() - timedelta(days=15)
    from_date = day_0.strftime('%Y-%m-%dT00:00:00Z')

    yesterday = datetime.now() - timedelta(days=1)
    to_date = yesterday.strftime('%Y-%m-%dT00:00:00Z')

    cases_url = f"https://api.covid19api.com/country/{selected_slug}/status/confirmed?from={from_date}&to={to_date}"
    json_response = requests.get(url = cases_url).json()
    cases = pd.json_normalize(json_response)
    new_cases = cases.Cases.max() - cases.Cases.min()
    
    fourteen_days_ago = day_0 + timedelta(days=1)
    
    return fourteen_days_ago, yesterday, new_cases
