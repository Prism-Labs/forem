from duneanalytics import DuneAnalytics, DuneAnalyticsException
import sys
import re
import argparse
import json

QUERY_REGEX = r"https://duneanalytics.com/queries/([0-9]+)"
QUERY_REGEX2 = r"https://dune.xyz/queries/([0-9]+)"
EMBED_REGEX = r"https://dune.xyz/embeds/([0-9]+)"

def validate_dune_url(url):
    result = re.match(QUERY_REGEX, url)
    if (result):
        return ('QUERY', int(result.group(1)))

    result = re.match(QUERY_REGEX2, url)
    if (result):
        return ('QUERY', int(result.group(1)))

    result = re.match(EMBED_REGEX, url)
    if (result):
        return ("EMBED", int(result.group(1)))

    return false


def main(args):
    username = args.username
    password = args.password
    url = args.url

    url_validity = validate_dune_url(url)
    if not url_validity:
        print(json.dumps({ 'error' : "Invalid Dune URL" }, indent=4))
        return

    (url_type, query_id) = url_validity

    # initialize client
    dune = DuneAnalytics(username, password, raise_exception=True)

    try:
        # try to login
        dune.login()
        # fetch token
        dune.fetch_auth_token()
        # fetch query result id using query id
        result_id = dune.query_result_id(query_id=query_id)
        # fetch query result
        data = dune.query_result(result_id)
        print(json.dumps(data, indent=4))
    except DuneAnalyticsException as e:
        print(json.dumps({ 'error' : e.message, 'response': e.response.json() if e.response else "" }, indent=4))
        return   

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('url', help='Dune Analytics URL')
    parser.add_argument('--username', required=True, help='Username for the Dune Analytics Account')
    parser.add_argument('--password', required=True, help='Password for the Dune Analytics Account')

    args = parser.parse_args()

    main(args)

