def get_population(selected_iso):
    import requests
    from xml.etree import ElementTree
    
    population_url = f"http://api.worldbank.org/v2/country/{selected_iso}/indicator/SP.POP.TOTL"
    response = requests.get(url = population_url)
    tree = ElementTree.fromstring(response.content)

    year_population = {}
    for data in tree.findall('{http://www.worldbank.org}data'):
        year = int(data.find('{http://www.worldbank.org}date').text)
        population = int(data.find('{http://www.worldbank.org}value').text)
        year_population[year] = population
    
    nearest_year = max(year_population, key=int)
    nearest_population = year_population[nearest_year]
    
    
    return nearest_year, nearest_population
