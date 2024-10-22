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

- code created by reading api documentation

- slow (approx 1s start delay caused by python and plugins loading)

- requires python interpreter with dependencies (not a single binary)

Can the current OSC be improved?
--------------------------------

Well, no

- certain aspects can be improved

- huge code base required costly maintenance

- any improvement (change) breaks backwards compatibility making users "angry"

How to do it better
-------------------

- generate clients (sdk, cli, etc) for desired programming languages

  - multiple attempts using different existing artifacts as a source of truth failed

- start building OpenAPI for service APIs


Documentation
-------------

`gtema.github.io/openstack/cli.html <https://gtema.github.io/openstack/cli.html>`_

Installation
------------

- as binaries from GitHub

.. code:: console

  curl --proto '=https' --tlsv1.2 -LsSf https://github.com/gtema/openstack/releases/download/openstack_cli-v0.8.1/openstack_cli-installer.sh | sh

- Container 

.. code:: console

   docker pull ghcr.io/gtema/openstack:0.8.1

- Build locally

.. code:: console

   cargo install openstack_cli

Command syntax
--------------

.. code:: console

   osc <service> <resource> <subresource> [--parameters]

   osc <service> help

Auth
----

- `osc auth login`

- `osc auth show`

- `osc --os-cloud XXX auth show`


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


TUI
---

- Installation

.. code:: console

   curl --proto '=https' --tlsv1.2 -LsSf https://github.com/gtema/openstack/releases/download/openstack_tui-v0.1.5/openstack_tui-installer.sh | sh


- Running

.. code:: console

   ostui

   ostui --os-cloud XXX
