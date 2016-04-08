{%- from 'syncthing/map.jinja' import syncthing with context %}

syncthing_service:
  service.dead:
    - name: syncthing
    - enable: False

syncthing_init:
  file.absent:
    - name: /etc/init/syncthing.conf
    - require:
      - service: syncthing_service

reload_upstart_for_syncthing:
  cmd.wait:
    - name: initctl reload-configuration
    - watch:
      - file: syncthing_init

{% if 'purge_files' in pillar %}
syncthing_data:
  file.absent:
    - name: {{ syncthing.datadir }}
    - require:
      - service: syncthing_service
{%   if 'purge_user' in pillar %}
    - require_in:
      - user: syncthing_user
{%   endif %}
{% endif %}

{% if 'purge_user' in pillar %}
syncthing_user:
  user.absent:
    - name: {{ syncthing.user }}
    - force: True
    - purge: {% if 'purge_files' in pillar %}True{% else %}False{% endif %}
{% endif %}

syncthing_archive:
  file.absent:
    - name: {{ syncthing.bindir }}
    - require:
      - service: syncthing_service

syncthing_update_mine:
  module.wait:
    - name: mine.update
    - watch:
      - service: syncthing_service
