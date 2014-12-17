# README #

### What does this repository contain? ###

* Custom Saltstack grain for Syncthing
* Saltstack SLS for Syncthing (Coming Soon, Under Development)

### How do I get set up? ###

* Place syncthing.py in _grains into /srv/salt/_grains. The _grains folder should be under your file_roots
* Adjust port in syncthing.py if necessary
* Do a salt '*' saltutil.sync_grains to sync your grains with your minions
* Do a salt '*' grains.items to see if syncthing shows up

### Comming Soon ###

* Saltstack SLS for Syncthing