#!/usr/bin/env python

from __future__ import absolute_import
import logging
import psutil
import requests
import salt.utils.decorators

DEFAULT_REQUEST_TIMEOUT = 0.1
DEFAULT_API_PORT = '8384'

s = requests.Session()

def _get_syncthing_api(endpoint):
    log = logging.getLogger(__name__)
    # pillar_data = __pillar__.get('syncthing', {}).get('lookup', {})
    pillar_data = {'apikey': 'RpdzTGYfwwpC7dW4VhjMMlVNFXp394L1', }
    if not 'apikey' in pillar_data:
        log.error("__pillar__['syncthing']['lookup'] missing apikey entry: %r", pillar_data)
        return {}
    uri = 'http://127.0.0.1:' + pillar_data.get('port', DEFAULT_API_PORT) + '/rest/' + endpoint
    try:
        r = s.get(uri, timeout=DEFAULT_REQUEST_TIMEOUT, headers={'X-API-Key': pillar_data['apikey']})
    except requests.exceptions.ReadTimeout:
        raise
    except requests.exceptions.RequestException, e:
        log.warn('Syncthing grain depends on the syncthing api. However, we failed to get %s: %r', uri, e)
        return {}
    if 200 != r.status_code:
        log.warn('Syncthing grain depends on the syncthing api. However, we got %d when going to %s: %r', r.status_code, uri, r)
        return {}
    try:
        res = r.json()
    except Exception, e:        # disgusting, but I don't know which json library will be decoding
        log.error('Failed to decode %s: %r', r.text, e)
        return {}
    return res

def data():
    '''
    Gather data about the local syncthing instance, if any.

    :maintainer:    Andrew Hammond <ahammond@anchorfree.com>
    :maturity:      new
    :depends:       python-requests,python-psutil
    :platform:      all
    '''

    log = logging.getLogger(__name__)

    # check to see if syncthing is running before querying.
    for pid in psutil.pids():
        try:
            p = psutil.Process(pid)
        except psutil.NoSuchProcess:
            continue
        if p.name().startswith('syncthing'):
            break
    else:
        log.debug('Syncthing process not found.')
        return {}

    stdata = {}
    try:
        for last_path in ['status', 'version']:
            stdata.update({last_path: _get_syncthing_api('system/' + last_path)})
        return {'syncthing': stdata}
    except requests.exceptions.ReadTimeout:
        return {}
