=======================
OpenStack OpenAPI specs
=======================

Building up OpenAPI specs for OpenStack APIs
--------------------------------------------

:Date: 2024-05-15
:Author: Artem Goncharov


Agenda
------

- Introduction

- OpenStack API "features"

- Designing OpenAPI for OpenStack

- CodeGenerator

- How OpenAPI specs can be used |crab|


What is OpenAPI
---------------

The OpenAPI Specification, previously known as the Swagger Specification, is a
specification for a machine-readable interface definition language for
describing, producing, consuming and visualizing web services.

. . .

Version 3.1.0
~~~~~~~~~~~~~

OpenAPI version 3.1.0, released in 2021, includes JSON schema alignment what
allows it to be applied for every API with JSON schema.

OpenAPI Example
---------------

.. code:: yaml

   openapi: 3.1.0
   info:
     version: 1.0.0
     title: Sample API
     description: A sample API to illustrate OpenAPI concepts
   paths:
     /list:
       get:
         description: Returns a list of stuff
         request:
           headers:
             ..
           content:
             ..
         responses:
           '200':
             headers:
               ..
             content:
               application/json:
                 schema:
                   description: Stuff items list
                   type: array
                   items:
                     type: string
                     description: I am the stuff item

What is OpenAPI good for
------------------------

- Machine readable API contract
- API documentation consistent with the service code
- Generation of API clients
- Enables API security testing
- Ease API integration into 3rd party frameworks (i.e. API Gateway)

. . .

- **Open** *your* **API** (make it consumable)

OpenStack API
-------------

- Every service is exposing their **own individual** API
- **Strongly deviating** despite API-SIG effort
- **Non-declarative**

. . .

- **Not directly OpenAPI compatible**

Dynamic headers
---------------

Some services (i.e. Swift) support dynamic (not pre-defined) headers to
operate on resource metadata:

.. code:: console

   $> curl -i $publicURL/marktwain/goodbye -X POST -H "X-Object-Meta-Book: GoodbyeColumbus"

. . .

.. danger::

   OpenAPI requires all supported request and response headers to be
   described explicitly (name, data type, description)

`Microversion <https://specs.openstack.org/openstack/api-sig/guidelines/microversion_specification.html>`__
-----------------------------------------------------------------------------------------------------------

“API Microversions” allow changes to the API while preserving backward
compatibility. The basic idea is that a user has to explicitly ask for their
request to be treated with a particular version of the API.

So breaking changes can be added to the API without breaking users who don’t
specifically ask for it.

.. code:: console

   $> curl -i $publicURL/volumes -X POST -H "OpenStack-API-Version: volume 3.70" ...

. . .

.. danger::

   OpenAPI does not support different operations based on the
   passed headers

RPC style actions
-----------------

Few OpenStack services rely on the RPC like actions where operation is routed
based on the body.

.. code:: console

   $> curl -i $publicURL/servers/fake_id/action -X POST -d '
       {
           "lock": {"locked_reason": "I don't want to work"}
       }
   '

RPC style actions
-----------------

.. image:: server-actions.png

. . .

.. danger::

   OpenAPI does not support different operations based on the
   request body

So now what?
------------

“X-” extensions
---------------

OpenAPI allows *X-custom* extensions

.. code:: yaml

   paths:
     /servers:
       put:
         ...
         x-openstack: 
           foo: bar


Dynamic headers
---------------

Custom OpenAPI parameter serialization based on regex (similar to parameter serialization)

.. code:: yaml

   paths:
     /foo:
       put:
         ...
         parameters:
           - in: header
             name: X-Account-Meta-*
             schema:
               type: string
             x-openstack:
               style: regex

Microversions
-------------

JSON schema ``oneOf`` with ``x-openstack`` extension and custom discriminator (polymorphism)

.. code:: yaml

   components:
     schemas:
       VolumesCreateRequest:
         oneOf:
           - $ref: '#/components/schemas/VolumesCreate_30'
           - $ref: '#/components/schemas/VolumesCreate_313'
           - $ref: '#/components/schemas/VolumesCreate_347'
           - $ref: '#/components/schemas/VolumesCreate_353'
         x-openstack:
           discriminator: microversion
       VolumesCreate_313:
         ...
         x-openstack:
           min-ver: 3.13
           max-ver: 3.46
       ...

RPC style Actions
-----------------

JSON schema ``oneOf`` with ``x-openstack`` extension and custom discriminator

.. code:: yaml

   components:
     schemas:
       server_actions:
         oneOf:
           - $ref: #/components/schemas/action_foo
           - $ref: #/components/schemas/action_bar
         x-openstack:
           discriminator: action
       action_foo:
         ...
         x-openstack:
           action-name: foo
       action_bar:
         ...
         x-openstack:
           action-name: bar

Actions + microversions
-----------------------

Just a combination of above methods.

.. code:: yaml

   components:
     schemas:
       server_actions:
         oneOf:
           - $ref: #/components/schemas/action_foo
           - $ref: #/components/schemas/action_bar
         x-openstack:
           discriminator: action
       action_foo:
         oneOf:
           - $ref: #/components/schemas/action_foo_21
           - $ref: #/components/schemas/action_foo_22
         x-openstack:
           action-name: foo
           discriminator: microversion

Constraints
-----------

- Strict body definition for certain microversion (no merging or individual
  parameters)

- Query parameters may be combined for operation marking microversion
  constraints

.. code:: yaml

   ...
       parameters:
         new_param:
           in: query
           name: foo_by_bar
           description: Filter foos by bars (new in microversion 2.45)
           schema:
             type: string
           x-openstack:
             min-ver: 2.45

And what’s next?
----------------

Let's build OpenAPI specs from service sources
----------------------------------------------

- Inspect source code of services

- Some services have json schema attached to the controllers

- Services use different frameworks (wsgi + routes, pecan, flask, WSME, etc)

- Response descriptions mostly missing

  ==> `CodeGenerator <https://opendev.org/openstack/codegenerator>`__

CodeGenerator
-------------

- OpenAPI specs by inspecting source code of services

- Rust SDK

- Rust CLI

- Python openstackclient

- Ansible modules

- …

OpenStack supported services
----------------------------

-  Nova (compute)
-  Cinder (block-storage)
-  Glance (image)
-  Neutron (network) + plugins
-  Keystone (identity)
-  Octavia (load-balancer)
-  Placement

Nova
----

- |check| Routes
- |check| Request data
- |check| Microversion info
- |check| Actions
- |ncheck| Query parameters
- |ncheck| Response schemas

Cinder
------

- |check| Routes
- |plusmn| Request data
- |plusmn| Microversion info
- |check| Actions
- |ncheck| Query parameters
- |ncheck| Response schema

Glance
------

- |check| Routes
- |plusmn| Request data
- |plusmn| Query parameters
- |plusmn| Response schema

Keystone
--------

- |check| Routes
- |plusmn| Request data
- |ncheck| Query parameters
- |ncheck| Response schema

Neutron
-------

- |plusmn| Routes
- |plusmn| Request data
- |plusmn| Query parameters
- |plusmn| Response schema

Octavia
-------

- |plusmn| Routes
- |plusmn| Request data
- |ncheck| Query parameters
- |check| Response schema

Challenges
----------

- No naming conventions

- Unified behavior for non-standard service functionality is hard

- Used JSON schema libraries have **limited** validation of the schema errors

- OpenAPI validation still **does not** catch all of the JSON schema errors

  => CodeGeneration catches **lot** of schema errors

.. code:: json

   "type": "object",
   "properties": {
     "schema_version": {"name": {"type": "string"}}
   }

Small Survey
------------

Who:

. . .

- Uses python-openstackclient

. . .

- Isn't satisfied with its performance?

. . .

- having issues with API and client doing things differently

. . .

- likes/doesn't an attempt to normalize OpenStack services

. . .

- wants a small binary cli to skip dependency hell

. . .

- frustrated with malfunctioning automation and missing bypass capabilities


Rust Tooling 🦀💖
-----------------

`https://github.com/gtema/openstack<https://github.com/gtema/openstack>`_

. . .

- SDK

  - sync

  - async

. . .

- CLI

.. code:: console

   $> osc --os-cloud devstack compute server list

   +------------------+-------+---------+
   | id               | name  | status  |
   +------------------+-------+---------+
   | aaed1db9-***-*** | s**** | ACTIVE  |
   | c080769c-***-*** | w**** | ACTIVE  |
   | 28aef686-***-*** | y**** | ACTIVE  |
   | 3c178e63-***-*** | h**** | ACTIVE  |
   | b62f9988-***-*** | 3**** | ACTIVE  |
   | 1b129bad-***-*** | s**** | SHUTOFF |
   +------------------+-------+---------+
   

Benchmark
---------

- Scalability

- Sustainability

- Efficiency

------

.. list-table::
   :header-rows: 1

   * - Test
     - OSC (python)
     - OSC (Rust)
   * - `catalog list` 
     - 1.54s 
     - 68ms
   * - `flavor list`
     - 2.6s
     - 830ms
   * - `server list` (empty)
     - 1.8s
     - 210ms
   * - `server list` (10 entries)
     - 4.0s 
     - 709ms
   * - `image list`
     - 2.4s 
     - 560ms
   * - `network list`
     - 1.8s
     - 330ms
   * - `volume list`
     - 1.9s 
     - 270ms
   * - `container list` 
     - 1.3s
     - 370ms
   * - `object list` (3200 files)
     - 2.4s 
     - 1.0s
   * - `object list` (10000 files)
     - 3.8s 
     - 1.7s

Rust tooling
------------

- 10,000loc maintains 500,000+ loc Rust tooling

- Unix philosophy: "do one thing well"

- Awesome performance

- Compiled binary

- Unavoidable consistency (matching to the API functionality)

- ...

. . . 

- Private project, `sponsoring <https://github.com/sponsors/gtema>`_ is
  very |smileyheart|

Next Steps
----------

-  Improve OpenStack pipeline for handling specs
-  Improve OpenStack services to add missing schema
-  Continue extending generator targets (i.e. TUI, GopherCloud, OpenTofu)
-  Central api gateway using OpenAPI specs

   -  improved central logging
   -  central API metrics capture
   -  throttling, Anti-DDoS, etc

-  Security scanning of the APIs
-  Replace OpenStack API-Ref (documentation)

Thank you
---------

Links:
~~~~~~

- `https://opendev.org/openstack/codegenerator/ <https://opendev.org/openstack/codegenerator/>`_

- `https://github.com/gtema/openstack <https://github.com/gtema/openstack>`_

- `https://gtema.github.io/openstack-openapi/ <https://gtema.github.io/openstack-openapi/>`_


Q&A
---


.. |plusmn| unicode:: U+2757 .. PLUS-MINUS SIGN
.. |check| unicode:: U+02705 .. Heavy check
.. |ncheck| unicode:: U+0274C .. Heavy X
.. |heart| unicode:: U+1F496 .. Heart
.. |heartribbon| unicode:: U+1F49D .. Heart with ribbon
.. |smileyheart| unicode:: U+1F970 .. Smiley with hearts
.. |crab| unicode:: U+1F980 .. Crab
