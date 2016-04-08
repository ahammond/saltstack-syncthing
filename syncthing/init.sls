{%- from 'syncthing/map.jinja' import syncthing with context %}
{%- from 'storage/map.jinja' import storage with context %}

{# Disabled: https://github.com/saltstack/salt/issues/27646 #}
{# set syncthing_grains = salt['mine.get']('syncthing:status:myID', 'grains.items', expr_form='grain') #}
{% set syncthing_grains = {} %}
{% for host, grains in salt['mine.get']('*', 'grains.items') | dictsort %}
{%   if grains.get('syncthing', {}).get('status', {}).get('myID', False) %}
{%     do syncthing_grains.update({host: grains}) %}
{%   endif %}
{% endfor -%}

syncthing_archive:
  archive.extracted:
    - name: {{ syncthing.installdir }}
    - source: http://{{ storage.server_ip }}/rpms/syncthing/{{ syncthing.download_file }}.tar.gz
    - source_hash: sha256={{ syncthing.download_sha256 }}
    - archive_format: tar
    - tar_options: z
    - if_missing: {{ syncthing.bindir }}

syncthing_user:
  user.present:
    - name: {{ syncthing.user }}
    - gid_from_name: True
    - system: True
    - password: \!
    - home: {{ syncthing.homedir }}

syncthing_data:
  file.directory:
    - name: {{ syncthing.datadir }}
    - user: {{ syncthing.user }}
    - group: {{ syncthing.group }}
    - mode: '3755'
    - makedirs: True
    - require:
      - user: {{ syncthing.user }}

{% for folder, _ in syncthing.folders | dictsort %}
syncthing_data_{{ folder }}:
  file.directory:
    - name: {{ syncthing.datadir }}/{{ folder }}
    - user: {{ syncthing.user }}
    - group: {{ syncthing.group }}
    - mode: '3755'
    - require:
      - file: {{ syncthing.datadir }}
    - require_in:
      - service: syncthing_service
{% endfor %}

{% set syncthing_config_dir = syncthing.homedir + '/.config/syncthing' %}
syncthing_config_dir:
  file.directory:
    - name: {{ syncthing_config_dir }}
    - user: {{ syncthing.user }}
    - group: {{ syncthing.group }}
    - makedirs: True
    - require:
      - user: {{ syncthing.user }}

syncthing_config:
  file.managed:
    - name: {{ syncthing_config_dir }}/config.xml
    - source: salt://syncthing/files/config.xml
    - template: jinja
    - makedirs: True
    - user: {{ syncthing.user }}
    - group: {{ syncthing.group }}
    - context:
      syncthing: {{ syncthing }}
      syncthing_grains: {{ syncthing_grains }}
    - require:
      - file: syncthing_config_dir

syncthing_init:
  file.managed:
    - name: /etc/init/syncthing.conf
    - source: salt://syncthing/files/init.conf
    - template: jinja
    - context:
      syncthing: {{ syncthing }}
    - require:
      - archive: syncthing_archive
      - user: syncthing_user

reload_upstart_for_syncthing:
  cmd.wait:
    - name: initctl reload-configuration
    - watch:
      - file: syncthing_init

syncthing_service:
  service.running:
    - name: syncthing
    - enable: True
    - require:
      - file: syncthing_init
      - file: syncthing_data
    - watch:
      - file: syncthing_config

syncthing_update_mine:
  module.wait:
    - name: mine.update
    - watch:
      - service: syncthing_service
