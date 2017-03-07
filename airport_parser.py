' Creates a CSV file containing just large and medium large_airports'
import csv
import pprint

with open('airports.csv', 'rb') as csv_file:
    READER = csv.DictReader(csv_file)
    # fields we want
    # filter out the reader so it only contains medium and large large_airports
    large_airports = []
    keys = set(['name', 'iata_code', 'iso_country', 'municipality', 'iso_region'])
    for row in READER:
        if row['iata_code'] == 'LAX':
            pprint.pprint(row)
        airport_type = row['type']
        if  airport_type == 'large_airport' or airport_type == 'medium_airport'\
            and row['scheduled_service'] == 'yes':
            large_airports.append({k:v for k,v in row.iteritems() if k in keys})
    for i in range(15):
        pprint.pprint(large_airports[i])
    print len(large_airports)
    # wr
    with open('large_airports.csv', 'wb') as output_file:
        dict_writer = csv.DictWriter(output_file, large_airports[0].keys())
        dict_writer.writeheader()
        dict_writer.writerows(large_airports)
