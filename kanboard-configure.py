#!/usr/bin/python3

import os

def escape(value):
    if value == 'true':
        return value
    elif value == 'false':
        return value
    elif value == 'null':
        return value
    elif value.isdigit():
        return value
    else:
        return "'%s'" % value


print('<?php')
for key, value in os.environ.items() :
    if key.startswith('KANBOARD_'):
        kbdef = key[9:]
        print("define('%s', %s);" % (kbdef, escape(value)))
