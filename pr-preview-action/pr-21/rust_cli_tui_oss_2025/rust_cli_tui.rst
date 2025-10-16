=======================================
OpenStack CLI and TUI rewritten in Rust
=======================================


OpenStack CLI and TUI in Rust generated from OpenAPI
----------------------------------------------------

:Date: 2025-10-18
:Author: Artem Goncharov


Agenda
------

- Why a new CLI

- How it is built

- Documentation

- Installation

- Walk through commands syntax

  - osc auth

  - osc api

- Auth caching

- TUI

Why new CLI
-----------

openstackclient is so slow and inconsistent. It requires too much maintenance
and monkey typing.


Can the current OSC be improved?
--------------------------------

. . .

Well, no

- certain aspects can be improved.

- huge code base requires costly maintenance.

- any improvement (change) breaks backwards compatibility making users "angry".

How to do it better
-------------------

- use compiled language.

- generate clients (sdk, cli, etc) for desired programming languages.

  - multiple attempts using different existing artifacts as a source of truth failed.

- continue improving OpenAPI for service APIs.


Documentation
-------------

`gtema.github.io/openstack/cli.html <https://gtema.github.io/openstack/cli.html>`_

Installation
------------

`github.com/gtema/openstack <https://github.com/gtema/openstack>`_

- as binaries from GitHub

.. code:: console

  curl --proto '=https' --tlsv1.2 -LsSf https://github.com/gtema/openstack/releases/latest/download/openstack_cli-installer.sh | sh

- Container 

.. code:: console

   docker pull ghcr.io/gtema/openstack:0.13.0

- Build locally

.. code:: console

   cargo install openstack_cli

Command syntax
--------------

.. code:: console

   osc <service> <resource> <subresource> [--parameters] <operation>

   osc <service> help

- similar style as of python-openstackclient

- `service` is present always (no `osc group list`)

- multi-word resources are always dash-separated (i.e. `application-credential`, `security-group`)

- ``--current-user|--user-id|--user-name``

- ``--current-project|--project-id|--project-name``


Auth
----

Explicit authentication commands.

- ``osc auth show``

- ``osc --os-cloud devstack auth show``

- ``TOKEN=$(osc auth login)``

- ``osc auth login --renew``

Extended auth
-------------

.. list-table::
   :header-rows: 1

   * - Command
     - Description
   * - ``osc ...`` 
     - Use $OS_CLOUD env or prompt user
   * - ``osc ... --os-cloud``
     - Request explicit cloud from `clouds.yaml`
   * - ``osc ... --os-cloud --os-project-name``
     - Override project scope keeping identity info
   * - ``osc ... --os-client-config-file``
     - Alternative path to `clouds.yaml`
   * - ``osc --cloud-config-from-env``
     - No ?? for unexpected results
   * - ``osc .. --auth-helper-cmd ./vault_read.sh``
     - helper to extract secrets from wherever.
   * - ``OS_CLIENT_CONFIG_PATH=~/private.yaml:~/work.yaml```
     - Combine multiple configs into single virtual tree
   * - ``auth_type: [v3websso,v4oidc,v4passkey,v4jwt]``
     - All "fancy" auth methods
  

Output format
-------------

Different ways to output the data.

.. code:: console

   osc auth show -o json

   osc auth show -o json --pretty

   osc auth show -o json | jq '.token.user'

   osc catalog list -o json | jq '.[] | select(.type=="identity")'

   osc compute flavor list -o wide

   osc compute flavor list -f id -f name

   osc compute flavor list --table-arrangement dynamic-full-width

Curl mode
---------

Send authenticated API requests.

.. code:: console

   osc api --help

   osc api <SERVICE_TYPE> <URL> [-m <METHOD>] [-H <HEADER>]

   osc --os-cloud devstack-admin api identity /identity/v3/projects --pretty

Auth caching
------------

.. code:: console

   ls ~/.osc

- Auth/authz is stored on FS.

- Single file caches all `authz` of single `authn`.

- Authomatic "rescoping" using any valid `authn`.

- Keyring support is planned.

Status based output coloring
----------------------------

For resources with the `state` column results are colored.

.. code:: console

    osc image image list

Output customization
--------------------

- custom columns

- column order

- column format

- command hints

- ``$XDG_CONFIG_HOME/osc/[config,views].yaml``

.. code::yaml

  views:
    compute.server:
      default_fields: [id, name, status, created, address, image, flavor, security_groups]
      fields:
        - name: id
          width: 38
        - name: hostId
          width: 38
        - name: flavor
          json_pointer: "/original_name"
        - name: image
          json_pointer: "/id"
     ...
  command_hints:
    auth:
      show:
        - "Auth token can be set to the shell variable with `TOKEN=$(osc auth login)`"
        - "A full authentication response can be seen with `osc auth show -o json --pretty`"
    object-store.object:
      delete:
        - "Container can be pruned with `osc object-store container prune [--prefix <PREFIX>] <CONTAINER>`"
     ...


TUI
---

- Inspired by k9s.

- Installation

.. code:: console

   curl --proto '=https' --tlsv1.2 -LsSf https://github.com/gtema/openstack/releases/latest/download/openstack_tui-installer.sh | sh


- Running

.. code:: console

   ostui

   ostui --os-cloud XXX

- Generated using OpenAPI (API communication 100%, UX - 1%).

- Automatically refreshes the token.

- Provides TUI based auth-helper (queries for the required auth data).

- Mostly "read" operations.

- Started adding "write" operations.

Demo
----

- Switching "connections".

- Changing scope within the current connection.

- Navigation and traversing through resources.

- Creation/deletion of the security group rule.

Views configuration
-------------------

Similarly to the OSC supports views customization ``$XDG_CONFIG_HOME/openstack_tui/[config,views].yaml``

.. code:: yaml

  # Mode keybindings in the following form
  #  <Mode>:
  #    <shortcut>:
  #       action: <ACTION TO PERFORM>
  #       description: <DESCRIPTION USED IN TUI>
  mode_keybindings:
    # Block Storage views
    BlockStorageBackups:
      "y":
        action: DescribeApiResponse
        description: YAML
    ComputeServers:
      "0":
        action:
          SetComputeServerListFilters: {}
        description: Default filters
        type: Filter
      "1":
        action:
          SetComputeServerListFilters: {"all_tenants": "true"}
        description: All tenants (admin)
        type: Filter
      "ctrl-d":
        action: DeleteComputeServer
        description: Delete
      "c":
        action: ShowServerConsoleOutput
        description: Console output

Views configuration - global keybindings
----------------------------------------

.. code:: yaml

  global_keybindings:
    "F1":
      action:
        Mode:
          mode: Home
          stack: false
      description: Home
    "F2":
      action: CloudSelect
      description: Select cloud
    ":":
      action: ApiRequestSelect
      description: Select resource
    "<F4>":
      action: SelectProject
      description: Select project
    "<ctrl-r>":
      action: Refresh
      description: Reload data

Views configuration - aliases and views
---------------------------------------

.. code:: yaml

  # Mode aliases
  # <ALIAS>: <MODE>
  mode_aliases:
    "aggregates (compute)": "ComputeAggregates"
    "application credentials (identity)": "IdentityApplicationCredentials"
    "backups": "BlockStorageBackups"
    "flavors": "ComputeFlavors"
  views:
    # Block Storage
    block_storage.backup:
      default_fields: [id, name, az, size, status, created_at]
    compute.server:
      default_fields: [id, name, flavor, status, created, updated]
      fields:
        - name: flavor
          json_pointer: "/original_name"

Roadmap
-------

- Add Keyring support and add integration for various "vaults".

- Rework `clouds.yaml` to contexts separating cloud from authn from authz.

- Add more resource relations.

- Automate more of the TUI generation.

End?
----

Thank you for the attention!

`github.com/gtema/openstack <https://github.com/gtema/openstack>`_

`gtema.github.io/openstack <https://gtema.github.io/openstack/index.html>`_
