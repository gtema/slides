====================================
OpenStack Keystone rewritten in Rust
====================================

What do we get if we rewrite Keystone in Rust
=============================================

:Date: 2025-03-28
:Author: Artem Goncharov


Agenda
------

- What I was working on

- Keystone library for Rust

- Adding API

- Performance

- Way forward


What I was working on
---------------------

`Blog post <https://gtema.github.io/posts/rethinking-openstack-auth-authz/>`_

- OpenStack users (CSP customers) are not having possibility to establish user
  federation (ldap, oidc) or similar without involving administrators.

- Federation using oidc is managed outside of Keystone itself (typically by
  mod_auth_oidc module) what limits integration capabilities.

- It is not trivially possible to reuse single external IdP by different
  customers while being themselves in a control of such integration.

- Modification of oidc federation requires restart of Keystone.

- Lack of SCIM support

- Lack of an easy possibility to easily exchange JWT for an OpenStack token.

- Lack of fine-granular access control. Adding a new role dramatically
  complicates policy management.

- Lack of possibility to integrate external authorization systems. This is
  often necessary when OpenStack is just one offering in the service portfolio
  of the CSP.

- Lack of service accounts concept.


Keystone library for Rust
-------------------------

- AuthN/Z are complex

- Python libs for OIDC/Scim are rare and often unmaintained

- A standalone component (Keystone extension) addressing Federation issues (like federation authentication)

- SDK/CLI/TUI for OpenStack in Rust already exists and is useful (i.e. proxy to Keystone)

- Library for Keystone is necessary

  - issuing a token touches nearly every angle of Keystone: user, project,
    domain, role, assignments, Fernet, etc

  - direct access to the database is unavoidable

- CRUD for resource provider

- CRUD for identity provider

- CRUD for assignments provider

- cRud for catalog provider

- Fernet (decrypt/encrypt), msgpack (encode/decode)


Performance 
-----------

- password hashing is slow, on purpuse

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

   token = "gAAAAABnuDa_xLN1n9DrJyv-uDfODPvksisW9zUMirxT3vtyqwSNRQCoNLL2sOMiCCeE5ov6YdeZInzweIo0RObSVt0tma4qoQKHZr03pxYBi_drdvs2NWpxiwxyJDwdW8wsRo3Hmke-FNpG3Chq56WhW3mPQiTFPCNDg7anrYZN3sRxRd4ijuU"


.. code:: console

   Mac
   ------------------------------------------ benchmark 'group-name': 1 tests ------------------------------
   Name (time in us)         Min       Max     Mean  StdDev   Median     IQR  Outliers  OPS (Kops/s)  Rounds
   ---------------------------------------------------------------------------------------------------------
   test_fast             71.7640  124.9313  77.4613  3.8331  77.9629  4.7684    165;14       12.9097     685
   ---------------------------------------------------------------------------------------------------------

   Linux
   -------------------------------------------- benchmark 'group-name': 1 tests ---------------------------------
   Name (time in us)          Min       Max      Mean   StdDev    Median      IQR  Outliers  OPS (Kops/s)  Rounds
   --------------------------------------------------------------------------------------------------------------
   test_fast             206.4705  315.6662  218.3426  11.8152  215.5304  11.6825     52;21        4.5800     498
   --------------------------------------------------------------------------------------------------------------


.. code:: console

   Linux
   =====
   fernet token/project    time:   [8.8575 µs 9.1288 µs 9.4079 µs]

   Mac
   ===
   fernet token/project    time:   [3.1311 µs 3.1386 µs 3.1465 µs]

Mac numbers can not be compared with Linux

- list users

Passkey (SecurityKey) auth Demo
-------------------------------

Disclaimer: 

- Passkey != SecurityKey

- Passkey != Passkey (Apple != Android != Windows)

- WebAuthN - lib maintainers admit pink glasses off

