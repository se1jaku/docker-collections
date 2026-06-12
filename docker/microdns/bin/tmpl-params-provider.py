#!/usr/bin/env python3

import os
import json
import ipaddress


def load_home_cidr():
    home_cidr = os.getenv('HOME_CIDR')
    if not home_cidr:
        return

    net = ipaddress.ip_network(home_cidr, strict=False)
    if net.prefixlen != 21:
        raise ValueError("Only /21 CIDR blocks are supported.")

    smartdns_client_cidrs = []
    smartdns_client_cidrs.append(str(ipaddress.IPv4Network((int(net.network_address), 24))))
    smartdns_client_cidrs.append(str(ipaddress.IPv4Network((int(net.network_address) + 256 * 2, 23))))
    return {
        "smartdns_client_cidrs": smartdns_client_cidrs,
        "smartdns_server_groups": {
            "domestic": {
                "servers": [
                    "172.21.21.1"
                ],
                "tags": [
                    "domestic"
                ]
            }
        }
    }

def load_env():
    client_cidrs_str = os.getenv('SMARTDNS_CLIENT_CIDRS')
    client_cidrs = client_cidrs_str.split(',') if client_cidrs_str else []
    server_groups_str = os.getenv('SMARTDNS_SERVER_GROUPS')
    server_groups = json.loads(server_groups_str) if server_groups_str else {}
    return {
        "smartdns_client_cidrs": client_cidrs,
        "smartdns_server_groups": server_groups,
    }

def main():
    result = {}
    funcs = [load_env, load_home_cidr]
    for func in funcs:
        res = func()
        if res:
            result.update(res)

    # check
    if not result["smartdns_client_cidrs"]:
        raise ValueError("smartdns_client_cidrs is empty!")
    if not result["smartdns_server_groups"]:
        raise ValueError("smartdns_server_groups is empty!")

    print(json.dumps(result, indent=2, ensure_ascii=True))


if __name__ == "__main__":
    main()
