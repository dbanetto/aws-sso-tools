#!/usr/bin/env python3

import boto3

import json
import os
from pathlib import Path
from os import path
import datetime
from dateutil.parser import parse


def get_dot_aws_dir_path():
    return path.join(Path.home(), ".aws")


def is_expired(expires_at_str):
    expires_at = parse(expires_at_str)
    now = datetime.datetime.now().astimezone()

    return now > expires_at


def get_cached_sso_details():
    found = False
    dot_aws_path = get_dot_aws_dir_path()
    sso_path = path.join(dot_aws_path, "sso", "cache")

    for file_name in os.listdir(sso_path):
        if not file_name.endswith("json") or "botocore-client-id" in file_name:
            continue

        found = True

        with open(path.join(sso_path, file_name)) as cache_file:
            cache_json = json.load(cache_file)

            if is_expired(cache_json["expiresAt"]):
                continue

            return (cache_json["accessToken"], cache_json["region"], cache_json['startUrl'])

    if found:
        print("No valid sso cache found")
    else:
        print("No sso cache found")


def get_sso_accounts(token, region):
    sso_client = boto3.client("sso", region_name=region)

    list_accounts = sso_client.get_paginator("list_accounts")

    accounts = []

    for result in list_accounts.paginate(accessToken=token):
        accounts.extend(result["accountList"])

    return accounts


def get_sso_roles_for_account(token, region, account_id):
    sso_client = boto3.client("sso", region_name=region)

    list_accounts = sso_client.get_paginator("list_account_roles")

    roles = []

    for result in list_accounts.paginate(accessToken=token, accountId=account_id):
        roles.extend(result["roleList"])

    return roles


def print_role_config(role, region, start_url):

    role_name = role['roleName']
    account_id = role['accountId']
    # Could make this better by using the account alias
    profile_name = "-".join([role_name, account_id])

    print("\n".join([
        f"[profile {profile_name}]",
        f"sso_start_url = {start_url}",
        f"sso_region = {region}",
        f"sso_account_id = {account_id}",
        f"sso_role_name = {role_name}"
    ]))
    print()


def main():
    token, region, start_url = get_cached_sso_details()

    accounts = get_sso_accounts(token, region)

    roles = []
    for account in accounts:
        roles.extend(get_sso_roles_for_account(token, region, account['accountId']))

    for role in roles:
        print_role_config(role, region, start_url)


if __name__ == "__main__":
    main()
