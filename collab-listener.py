#!/bin/env python

from kafka import KafkaConsumer
from json import loads
import subprocess
import os
import functools
import requests
import timeit

TOPIC = os.environ['KAFKA_TOPIC']
GROUPID = os.environ['KAFKA_GROUP_ID']
BOOTSTRAP = os.environ['KAFKA_BOOTSTRAP_SERVER']
LOGBOOK_URI = os.environ['LOGBOOK_URI']

# flush all prints
print = functools.partial(print, flush=True)

print( f"Listening on topic {TOPIC} at {BOOTSTRAP}..." )

consumer = KafkaConsumer(
    os.environ['KAFKA_TOPIC'],
    # auto_offset_reset='earliest',
    # enable_auto_commit=True,
    # group_id=os.environ['KAFKA_GROUP_ID'],
    value_deserializer=lambda m: loads(m.decode('utf-8')),
    bootstrap_servers=os.environ['KAFKA_BOOTSTRAP_SERVER'].split(',')
)

def setfacl( userids, directory ):

    acl = [ f'u:{u}:r-x,default:u:{u}:r-x' for u in userids ]
    cmd = f"setfacl -R --set user::rwx,group::rwx,other::---,default:mask:rwx,default:other:---,{','.join(acl)}  {directory}"
    print( f'  {cmd}' )
    output = subprocess.check_output( cmd, shell=True, stderr=subprocess.STDOUT, ).decode(encoding="utf-8")
    s = True if output == '' else False
    return s

def wrapper(func, *args, **kwargs):
    def wrapped():
        return func(*args, **kwargs)
    return wrapped


for message in consumer:

    #print(message.value)

    op = message.value['CRUD']
    directory = message.value['experiment_name']
    prefix = message.value['experiment_name'][0:6]
    directory = os.environ['EXP_DIR'] + '/' + prefix + '/' +  message.value['experiment_name'] + '_' + message.value['instrument'] + '/'

    m = message.value['value']
    print( f"Permissions update on directory {directory} {op} with {m['players']} by {m['requestor']}" )

    if len(m['players') == 0:
      print( f"No users defined!" )
      continue

    # get current
    output = subprocess.check_output(
        f'getfacl {directory}', shell=True, stderr=subprocess.STDOUT,
    )
    #print(f"{output}")
    current_users = [ u.split(':')[1] for u in output.decode("utf-8").splitlines() if u.startswith('user:') and not '::' in u ]
    #print(f"GETFACL: {current_users}")

    # format new users
    users = [ u.split(':')[-1] for u in m['players'] if u.startswith('uid:') ]
    #print(f"SET TO USERS {users}")

    # get uids from names
    names = '&'.join( [ f'uid={user}' for user in users ] )
    url = f'{LOGBOOK_URI}/cryoem-data/lgbk/ws/get_matching_uids?{names}'
    response = requests.get(url, auth=(os.environ['USERNAME'].strip(), os.environ['PASSWORD'].strip())).json()
    user_map = {}
    for u in response['value']:
        user_map[ u['uid'] ] = u['uidNumber']
    userids = [ user_map[u] for u in users ]
    print(f"  current: {current_users}\tnew ->\t{userids}")

    wrapped = wrapper( setfacl, userids, directory )
    t = timeit.timeit(wrapped, number=1)
    print( f'  done in {int(t)}s' )

    print()
