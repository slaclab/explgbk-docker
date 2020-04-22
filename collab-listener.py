#!/bin/env python

from kafka import KafkaConsumer
from json import loads
import subprocess
import os
import functools

TOPIC = os.environ['KAFKA_TOPIC']
GROUPID = os.environ['KAFKA_GROUP_ID']
BOOTSTRAP = os.environ['KAFKA_BOOTSTRAP_SERVER']

# flush all prints
print = functools.partial(print, flush=True)

print( f"Listening on topic {TOPIC} at {BOOTSTRAP}..." )

consumer = KafkaConsumer(
    os.environ['KAFKA_TOPIC'],
    # auto_offset_reset='earliest',
    # enable_auto_commit=True,
    # group_id=os.environ['KAFKA_GROUP_ID'],
    value_deserializer=lambda m: loads(m.decode('utf-8')),
    bootstrap_servers=[os.environ['KAFKA_BOOTSTRAP_SERVER']]
)


for message in consumer:

    print(message.value)

    op = message.value['CRUD']
    directory = message.value['experiment_name']
    directory = '.'

    m = message.value['value']
    print( f"Permissions update on directory {directory} NEED INSTRUMENT {op} with {m['players']} by {m['requestor']}" )

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

    print(f"  {current_users}\t->{users}")
    
    add_users = set(users) - set(current_users)
    add = [ 'u:%s:rx' % u for u in add_users ]
    if len(add_users) > 0:
        cmd = "setfacl %s -Rm o::---  %s -Rdm o::---  %s" % (' '.join( [ '-Rm %s'%u for u in add] ), ' '.join( [ '-Rdm %s'%u for u in add] ), directory )
        print(f"  ADD: {cmd}")

    del_users = set(current_users) - set(users)
    delete = [ 'u:%s'%u for u in del_users ]
    if len(del_users) > 0:
        cmd = "setfacl %s  %s  %s" % (' '.join( [ '-Rx %s'%u for u in delete] ), ' '.join( [ '-Rdx %s'%u for u in delete] ), directory )
        print(f"  DEL: {cmd}")

    print()
