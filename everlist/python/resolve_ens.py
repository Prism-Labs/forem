import sys
import re
import argparse
import json
from web3 import Web3
from ens import ENS

ENS_REGEX = r"^.*.eth$"

def validate_ens(ens):
    result = re.match(ENS_REGEX, ens)
    return True if (result) else False

def main(args):
    ens = args.ens

    ens_validity = validate_ens(ens)
    if not ens_validity:
        print(json.dumps({ 'error' : "Invalid ENS" }, indent=4))
        return

    try:
        w3 = Web3(Web3.WebsocketProvider('wss://eth-mainnet.alchemyapi.io/v2/ZH_QdCROYPrh9R96kb5kDW9jvNKfbneh'))
        ns = ENS.fromWeb3(w3)

        address = ns.address(ens)
        data = {
            'ens': ens,
            'address': address
        }
        print(json.dumps(data, indent=4))
    except Exception as e:
        print(json.dumps({ 'error' : e.message, 'response': e.response.json() if e.response else "" }, indent=4))
        return   

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ens', help='ENS')

    args = parser.parse_args()

    main(args)

