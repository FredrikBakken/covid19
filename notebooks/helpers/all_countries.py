def get_all_countries():
    import requests
    
    countries_url = "https://api.covid19api.com/countries"
    json_request = requests.get(url = countries_url).json()
    df = parse_json(json_request, None, keys=['Country', 'Slug', 'ISO2'])
    
    return df


def parse_json(json_request, field, keys):
    """
    json_request: requests.get().json() variable
    field: specific field wanted from json
    keys: the underlying json data contained 
    in the field
    
    returns pd.DataFrame with keys as columns
    """
    
    import pandas as pd
    
    df_d = {}
    lst_lst = [[] for i in range(len(keys))]
    
    if field is not None:
        json_request = json_request[field]
            
    for lst, key in zip(lst_lst, keys):
        for item in range(len(json_request)):
            lst.append(json_request[item][key])
            
        df_d[key] = lst
    
    return pd.DataFrame(df_d)
