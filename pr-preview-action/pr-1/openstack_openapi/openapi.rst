OpenStack OpenAPI specs
=======================

Building up OpenAPI specs for OpenStack APIs

What is OpenAPI
---------------

The OpenAPI Specification, previously known as the Swagger
Specification, is a specification for a machine-readable interface
definition language for describing, producing, consuming and visualizing
web services.

Version 3.1.0
~~~~~~~~~~~~~

OpenAPI version 3.1.0, released in 2021, includes JSON schema alignment
what allows it to be applied for every API with JSON schema.

What is OpenAPI good for
------------------------

-  machine readable API contract
-  API documentation consistent with the service code
-  generation of API clients
-  enables API security testing
-  ease API integration into 3rd party frameworks (i.e. API Gateway)

OpenStack API
-------------

-  Every service is exposing their own individual API
-  APIs are heavily unstandardized despite API-SIG effort
-  non-declarative
-  not directly OpenAPI compatible

Dynamic headers
---------------

Some services (i.e. Swift) support dynamic (not pre-defined) headers to
operate on resource metadata:

.. code:: console

   curl -i $publicURL/marktwain/goodbye -X POST -H "X-Object-Meta-Book: GoodbyeColumbus"

------

.. danger::

   OpenAPI requires all supported request and response headers to be
   described explicitly (name, data type, description)

`Microversion <https://specs.openstack.org/openstack/api-sig/guidelines/microversion_specification.html>`__
-----------------------------------------------------------------------------------------------------------

   “API Microversions” allow changes to the API while preserving
   backward compatibility. The basic idea is that a user has to
   explicitly ask for their request to be treated with a particular
   version of the API.

   So breaking changes can be added to the API without breaking users
   who don’t specifically ask for it.

.. code:: console

   curl -i $publicURL/volumes -X POST -H "OpenStack-API-Version: volume 3.70" ...

.. danger::

   OpenAPI does not support different operations based on the
   passed headers

RPC style actions
-----------------

Few OpenStack services rely on the RPC like actions where operation is
routed based on the body.

.. code:: console

   curl -i $publicURL/servers/fake_id/action -X POST -d '
       {
           "lock": {"locked_reason": "I don't want to work"}
       }
   '


RPC style actions
-----------------

.. image:: server-actions.png

.. danger::

   OpenAPI does not support different operations based on the
   request body

So now what?
------------

“X-” extensions
---------------

OpenAPI allows x-custom extensions

.. code:: yaml

   paths:
     /servers:
       put:
         ...
         x-openstack: 
           foo: bar


Dynamic headers
---------------

Custom OpenAPI parameter serialization based on regex

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

JSON schema ``oneOf`` with ``x-openstack`` extension and custom
discriminator

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
           max-ver: 3.47
       ...

RPC Actions
-----------

JSON schema ``oneOf`` with ``x-openstack`` extension and custom
discriminator

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

- strict body definition for certain microversion (no merging or individual parameters)
- query parameters combined for operation marking microversion constraints

And what’s next?
----------------

Building OpenAPI specs from service sources
-------------------------------------------

-  inspect source code of services
-  most services have json schemas attached to the controllers
-  services use different frameworks (wsgi + routes, pecan, flask, etc)
-  response descriptions mostly missing

==> `CodeGenerator <https://opendev.org/openstack/codegenerator>`__

Nova schemas
------------

Cinder schemas
--------------

Keystone schemas
----------------

Neutron schemas
---------------

Octavia schemas
---------------

CodeGenerator
-------------

A project that supports following targets:

-  OpenAPI specs by inspecting services
-  Rust SDK
-  Rust CLI
-  Python openstackclient
-  Ansible modules
-  …

OpenStack supported services
----------------------------

-  Nova (compute)
-  Cinder (block-storage)
-  Glance (image)
-  Neutron (network) + plugins
-  Keystone (identity)
-  Octavia (load-balancer)
-  Placement

Challenges
----------

- standard behavior for non-standard service API behavior
- no naming conventions

Next Steps
----------

-  improve OpenStack pipeline of specs handling
-  improve OpenStack services to add missing schemas
-  continue extending generator targets (i.e. TUI)
-  central api gateway using OpenAPI specs

   -  improved central logging
   -  central API metrics capture

-  security scanning of the APIs
-  replace OpenStack API-Ref


Challenges
----------

- JSON schema does not catch all of the schema errors
- OpenAPI validation does not catch all of the JSON schema errors
=> CodeGeneration catches lot of unrelevant schema errors
