===============================
OpenStack CLI rewritten in Rust
===============================

A new CLI in Rust generated automatically
=========================================

:Date: 2024-10-30
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

- 173,000 loc openstackclient

- 183,000 loc openstacksdk

- code created by humans reading api documentation and reimplementing functionalty

- slow (approx 1s start delay caused by python and plugins loading)

- requires python interpreter with dependencies (not a single binary)

Can the current OSC be improved?
--------------------------------

. . .

Well, no

- certain aspects can be improved

- huge code base requires costly maintenance

- any improvement (change) breaks backwards compatibility making users "angry"

How to do it better
-------------------

- use compilable language

- generate clients (sdk, cli, etc) for desired programming languages

  - multiple attempts using different existing artifacts as a source of truth failed

- start building OpenAPI for service APIs


Documentation
-------------

`gtema.github.io/openstack/cli.html <https://gtema.github.io/openstack/cli.html>`_

Installation
------------

`github.com/gtema/openstack <https://github.com/gtema/openstack>`_

- as binaries from GitHub

.. code:: console

  curl --proto '=https' --tlsv1.2 -LsSf https://github.com/gtema/openstack/releases/download/openstack_cli-v0.8.2/openstack_cli-installer.sh | sh

- Container 

.. code:: console

   docker pull ghcr.io/gtema/openstack:0.8.2

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

Auth
----

- ``osc auth show``

- ``osc --os-cloud devstack auth show``

- ``osc auth login``

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
  

Output format
-------------

.. code:: console

   osc auth show -o json

   osc auth show -o json --pretty

   osc auth show -o json | jq '.token.user'

   osc catalog list -o json | jq '.[] | select(.type=="identity")'

Curl mode
---------

.. code:: console

   osc api --help

   osc api <SERVICE_TYPE> <URL> [-m <METHOD>] [-H <HEADER>]

   osc api identity auth/projects --pretty

Auth caching
------------

`Documentation <https://gtema.github.io/openstack/auth.html#caching>`_

.. code:: console

   ls ~/.osc

- Auth/authz is stored on FS

- Single file caches all `authz` of single `auth`

- Keyring support will be added in future


Image tutorial
--------------

- wget https://github.com/cirros-dev/cirros/releases/download/0.6.3/cirros-0.6.3-x86_64-disk.img
- qemu-img info cirros-0.6.3-x86_64-disk.img
- osc image image create --container-format bare --disk-format qcow2 --name test-cirros --min-disk 1 --min-ram 64
- osc image image show test-cirros
- osc image image upload 113d89a9-5847-4b87-97f5-52c466dc9109 --file cirros-0.6.3-x86_64-disk.img
- osc image image set 113d89a9-5847-4b87-97f5-52c466dc9109 --property foo=bar
- osc image image set 113d89a9-5847-4b87-97f5-52c466dc9109 --property bar=baz -o json --pretty
- osc image image download 113d89a9-5847-4b87-97f5-52c466dc9109 --file test-cirros.qcow2
- osc image image delete 113d89a9-5847-4b87-97f5-52c466dc9109

Swift tutorial
--------------

- osc object-store container list
- osc object-store container create test
- osc object-store object upload --file cirros-0.6.3-x86_64-disk.img test my-cirros-image
- echo "dummy" | osc object-store object upload test some-other-data
- osc object-store object download test some-other-data
- osc object-store object list test
- osc object-store object list test -o wide
- osc object-store container prune test --prefix some
- osc object-store container delete test
- osc object-store container prune test
- osc object-store container delete test

TUI
---

- Inspired by k9s

- Installation

.. code:: console

   curl --proto '=https' --tlsv1.2 -LsSf https://github.com/gtema/openstack/releases/download/openstack_tui-v0.1.6/openstack_tui-installer.sh | sh


- Running

.. code:: console

   ostui

   ostui --os-cloud XXX

Shortcuts
---------

.. list-table:: Shortcuts

   * - Shortcut
     - Description
   * - `<:>`
     - Switch to the resource
   * - `<F2>`
     - Switch cloud
   * - `<F4>`
     - Switch project (authz)
   * - <↑> | <↓> | <PageUp> | <PageDown> | <Home> | <End>
     - Navigate or scroll
   * - <↹>
     - Switch panes
