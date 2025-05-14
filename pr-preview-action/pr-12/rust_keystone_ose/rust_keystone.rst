====================================
OpenStack Keystone rewritten in Rust
====================================

Promising gain from the rewrite of Keystone in Rust
===================================================

:Date: 2025-05-14
:Author: Artem Goncharov


Agenda
------

- What I was working on

- Auth in Keystone

- Extending Keystone using Rust

- Performance

- Way forward


What I was working on
---------------------

- Allow users manage their Identity federation (ldap, oidc)

- Federation in Keystone is managed by proxy software (typically by
  mod_auth_oidc module or mod_shibboleth)

- Modification of federation requires restart of Keystone.

- Lack of SCIM (System for Cross-domain Identity Management) support

- Exchange JWT for an OpenStack token

- Lack of fine-granular access control (role explosion)

- Integrate external authorization systems.

- Lack of service accounts concept.

API Authentication
------------------

.. image:: api_auth.svg
   :height: 600px

Authentication methods
----------------------

- Username/password

- Username/password + MFA

- Application credentials

- Token (rescope)

- OIDC

- External

- Oauth1

- Saml2

- x509

Authentication vs authorization
-------------------------------

- Authentication (who am I)

  - Username
  - password
  - application credentials
  - ...

- Authorization (what do I want to do)

  - project_id
  - domain_id
  - system

.. warning::

   Keystone token is bound to a requested scope


Keystone library for Rust
-------------------------

- AuthN/Z are complex

- Good python libs for OIDC/Scim are rare and mostly unmaintained

- A standalone component (Keystone extension) offers best flexibility

- SDK/CLI/TUI for OpenStack in Rust already exists and is useful (i.e. proxy to Keystone)

- Library for Keystone is necessary

  - issuing a token touches nearly every angle of Keystone: user, project,
    domain, role, assignments, Fernet, etc

  - direct access to the database is unavoidable

- Fernet (decrypt/encrypt), msgpack (encode/decode)


Adding API to the lib
---------------------

Technically just peanuts compared to the lib itself

- token validation

- policy (not done yet)

- convert API request into the backend structure

- invoke backend method

- convert backend response to the API response

- oidc auth is not trivial though (it is more the CRUD)


Performance 
-----------

- password hashing is slow, on purpose

- decrypt token

.. code:: python

   import pytest

   from keystone.token.providers.fernet.core import Provider
   from keystone.token.provider import Manager
   import keystone.conf
   from keystone.conf import configure

   CONF = keystone.conf.CONF

   @pytest.fixture(scope="session", autouse=True)
   def execute_before_any_test():
       configure(CONF)

   @pytest.mark.benchmark(group="group-name", timer=time.time, disable_gc=True, warmup=False)
   def test_fast(benchmark):
       manager = Manager()
       fernet = Provider()
       result = benchmark(lambda: fernet.validate_token(token))
       assert result

   token = "gAAAAABnuDa_xLN1n9DrJyv-uDfOD...."

====

Python

.. code:: console

   Linux
   =====
   -------------------------------------------- benchmark 'group-name': 1 tests ---------------------------------
   Name (time in us)          Min       Max      Mean   StdDev    Median      IQR  Outliers  OPS (Kops/s)  Rounds
   --------------------------------------------------------------------------------------------------------------
   test_fast             206.4705  315.6662  218.3426  11.8152  215.5304  11.6825     52;21        4.5800     498
   --------------------------------------------------------------------------------------------------------------

   Mac
   ===
   ------------------------------------------ benchmark 'group-name': 1 tests ------------------------------
   Name (time in us)         Min       Max     Mean  StdDev   Median     IQR  Outliers  OPS (Kops/s)  Rounds
   ---------------------------------------------------------------------------------------------------------
   test_fast             71.7640  124.9313  77.4613  3.8331  77.9629  4.7684    165;14       12.9097     685
   ---------------------------------------------------------------------------------------------------------


Rust

.. code:: console

   Linux
   =====
   fernet token/project    time:   [8.8575 µs 9.1288 µs 9.4079 µs]

   Mac
   ===
   fernet token/project    time:   [3.1311 µs 3.1386 µs 3.1465 µs]

Note: Mac numbers can not be compared with Linux


Get Users (Python)
------------------

.. image:: get_users_py.png
   :height: 600px


Get Users (Rust)
------------------

.. image:: get_users_rust.png
   :height: 600px

Get Users (Python, 32 cores)
----------------------------

.. image:: get_users_py_server.png
   :height: 600px

Get Users (Rust, 32 cores)
--------------------------

.. image:: get_users_rust_server.png
   :height: 600px


Overall sample performance improvement
--------------------------------------

- python openstackclient + python Keystone

.. code-block:: console

   ❯ hyperfine 'openstack --os-cloud dev-keystone user list'
   Benchmark 1: openstack --os-cloud dev-keystone user list
     Time (mean ± σ):     622.5 ms ±  64.5 ms    [User: 269.4 ms, System: 41.5 ms]
     Range (min … max):   591.5 ms … 800.8 ms    10 runs

- rust openstackclient (osc) + python Keystone

.. code-block:: console

   ❯ hyperfine 'osc --os-cloud dev-keystone identity user list'
   Benchmark 1: osc --os-cloud dev-keystone identity user list
     Time (mean ± σ):     107.6 ms ±  84.8 ms    [User: 6.0 ms, System: 3.3 ms]
     Range (min … max):    78.8 ms … 348.8 ms    10 runs

- rust openstackclient (osc) + rust Keystone

.. code-block:: console

   ❯ hyperfine 'osc --os-cloud dev-keystone-rust identity user list'
   Benchmark 1: osc --os-cloud dev-keystone-rust identity user list
     Time (mean ± σ):      15.0 ms ±   1.5 ms    [User: 5.6 ms, System: 2.8 ms]
     Range (min … max):    12.6 ms …  27.1 ms    123 runs


=> 40x+ time improvement


Security Key auth
-----------------

.. image:: webauthn_auth.svg
   :height: 800px

OIDC auth
---------

.. image:: oidc.svg
   :height: 800px

Roadmap
-------

- Make KeystoneNG additional deployment component (integrated with Rust OSC)

- take care of advanced auth:

  - customer managed IdP 

  - Scim

  - JWT auth (workload identity federation)

  - security key

- overtake Auth and token validation

- continuous closing of the functional gaps to Keystone


Links:

- `https://github.com/gtema/keystone <https://github.com/gtema/keystone>`_

- `https://github.com/gtema/openstack <https://github.com/gtema/openstack>`_
