=======================================
OpenStack Keystone - Improving Security
=======================================

Reworking AuthN and AuthZ with Keystone-NG
------------------------------------------


:Date: 2025-10-19
:Author: Artem Goncharov

Agenda
------

- Introduction

- WebAuthN support (a.k.a. passkeys)

- Reworked federation

  - OIDC directly in Keystone

  - JWT login

  - Workload authorization

  - Restricted tokens and Service Accounts

- Features pipeline

- Q&A


Introduction
------------

**We want to let OpenStack users (CSP customers) to have control over user federation without involving administrators.**

- Federation using oidc is managed outside of Keystone itself.

- It is not trivially possible to reuse single external IdP by different
  customers.

- Modification of oidc federation requires restart of Keystone.

- Lack of SCIM (System for Cross-domain Identity Management) support.

- Exchange JWT for an OpenStack token.

- Lack of fine-granular access control (role explosion).

- Integrate external authorization systems. This is often necessary when
  OpenStack is just one offering in the service portfolio of the CSP.

- Lack of service accounts concept.

Keystone-NG
-----------

`https://github.com/gtema/keystone <https://github.com/gtema/keystone>`_

Started as a "keystone" library in Rust.

Evolved into standalone Keystone implementation with APIv4 focus.

New authn and authz implemented there to be (ideally) fully compatible to python
Keystone.

Can be deployed parallel to the python Keystone:

.. code:: config

   ProxyPass "/identity/v4" http://localhost:8080/v4 retry=0
   ProxyPass "/identity/v3" "unix:/var/run/uwsgi/keystone-api.socket|uwsgi://uwsgi-uds-keystone-api/v3" retry=0


WebAuthN support
----------------

.. image:: webauthn_auth.svg
   :height: 500px

WebAuthN support - demo
-----------------------

.. code:: yaml

  devstack-admin-passkey:
    auth_type: v4passkey
    auth:
      auth_url: https://devstack.v6.rocks/identity
      user_id: <USER_ID>
      project_domain_name: Default
      project_name: admin
    region_name: RegionOne

.. code:: console

   # Register the new passkey
   osc identity4 user passkey register --current-user --description yubikey

   # Authenticate with the passkey
   osc auth show

Reworked federation
-------------------

- Reimplemented from scratch trying not to break existing support.

- Identity providers and mappings are managed through the API

- Domain binding through IdP, mapping, or claims

- Single auth with Keystone being RP for the authorization code flow

- Claims bound supported both in IdP and mapping

- JWT login (with workload federation support - no more hardcoded passwords)

.. code:: console

   # List all (visible) IDPs
   osc --os-cloud devstack-admin identity4 federation identity-provider list

   # List all (visible) mappings
   osc --os-cloud devstack-admin identity4 federation mapping list

IdP and mapping sharing
-----------------------

**Reworked IDP - domain mapping enables new scenarios:**

- Common IdP (i.e. Keycloak, GitHub)

- "private" (i.e. Okta) bound to certain domains.

IdP binding
-----------

**domain_id set on IdP level**

- all mappings and authenticated users belong to domain.

- can only be seen by the domain users.

*typical usecase: customer's own Okta tenant.*

Mapping binding
---------------

**domain_id set on the Mapping level**

- shared IdP with the specific mappings.

- all authenticated users belong to the domain.

- can only be seen by the domain users.

- can be used to differentiate different domains served by the global IdP
  (Google, Keycloak, etc).

- requires careful control of the `bound_claims`.

*typical use-case: JWT login.*

Claims based binding
--------------------

**domain_id as the claim value**

- user<->domain relation identified by the authentication information.

*typical use-case: single Keycloak realm with users in groups (group =
domain).*


Federaition demo
----------------

.. code:: console

   # Login with the private OKTA IDP
   osc --os-cloud devstack-oidc-okta auth show

   # Login with the shared Keycloak and scope
   osc --os-cloud devstack-oidc-kc-shared identity4 federation identity-provider list

   # Login with the JWT issued by KC with scope
   osc --os-cloud devstack-jwt-kc1 --auth-helper-cmd ./kc_auth_helper.sh auth show

   # Login with the mapping bound to the project
   osc --os-cloud devstack-oidc-kc-jwt --auth-helper-cmd ./kc_auth_helper.sh auth show


Workload federation
-------------------

**No more hardcoded secrets for Zuul/GitHub/GitLab/etc!**

- For every external system a dedicated IdP must be registered.

- Mapping with `bound_claims`, `bound_audiences`, etc

- JWT is exchanged for Keystone token with fixed/requested scope and eventual
  restrictions.

- GitHub actions, GitLab CI, Zuul jobs authenticate to OpenStack without
  hardcoded credentials.

.. code:: console

   osc --os-cloud devstack-admin identity4 federation mapping show 8f783428-3956-4478-a32c-f4f55afd252b

   curl -X POST -H "Authorization: bearer <JWT>" -H "openstack-mapping: github" https://devstack.v6.rocks/identity/v4/federation/identity_providers/<IDP_ID>/jwt


`https://github.com/gtema/keystone-github-test/pull/1/ <https://github.com/gtema/keystone-github-test/pull/1/>`_

Workload federation - JWT exchange (GitHub example)
---------------------------------------------------

.. code:: yaml

  name: GH federation

  on:
    pull_request:

  # Grant permission for the job to request an OIDC token
  permissions:
    id-token: write
    contents: read

  jobs:
    test-validator:
      runs-on: ubuntu-latest
      steps:

        - name: test-validator
          id: get_token
          run: |
            TOKEN_JSON=$(curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
            "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=github-jwt")

            TOKEN=$(echo $TOKEN_JSON | jq -r .value)
            echo "token=$TOKEN" >> $GITHUB_OUTPUT

        - name: Use the Token
          run: |
            curl -f "https://devstack.goncharov.v6.rocks/identity/v4/federation/identity_providers/9f8237fa457d4fe8b1ce4530b86a074c/jwt" \
              -X POST -H "authorization: bearer ${{ steps.get_token.outputs.token }}" -H "openstack-mapping: github"

Restricted token
----------------

**A new Keystone token payload to further improve federated authn security.**

- Binds project with roles.

- Possibly binds the user_id.

- Does not require roles to be granted to the actor/scope explicitly.

- Controls `allow_rescope` and `allow_renew`.

- A prerequisite for Service Accounts.

Restricted token - continue
---------------------------

- May be further extended with individual policy rules to implement
  fine-granular permissions beyond roles.

- Federation mapping can point at the token_restriction "policy".

- `allow_rescope = false` prevents token rescoping.

- `allow_renew = false` prevents toking renewal (getting token from token).

- "user" authenticated through the mapping with restriction gets isolated
  permissions.

.. code:: console

   # Login with JWT using the restricted mapping
   osc --os-cloud devstack-jwt-kc-restricted --auth-helper-cmd ./kc_auth_helper_org2_user2.sh auth show

   # List user role assignments
   osc --os-cloud devstack-admin identity role-assignment list --user-id 0c6fb78d3acd476ea1b348d2b7ac6824

   # Get the auth token
   TOKEN=$(osc --os-cloud devstack-jwt-kc-restricted --auth-helper-cmd ./kc_auth_helper_org2_user2.sh auth login)

   # Check the token renew
   curl -i  -X POST -H "Content-Type: application/json"  -d '
   { "auth": {
       "identity": {
         "methods": ["token"],
         "token": {
           "id": "'$TOKEN'"
         }
       }
     }
   }'   "https://devstack.goncharov.v6.rocks/identity/v4/auth/tokens" ; echo

Couldn't we just accept the JWT in OpenStack services:
------------------------------------------------------

- Current policies require scope and roles information

- How to "revoke" trust

- How to "disable" domain/project/user

- How to provide endpoint catalog

- No other cloud is doing so

Service Accounts
----------------

**Service Account is a "user" that does not have credentials.**

- Does not map to the "human", but rather to technical systems.

- Certain similarity with application credentials.

- Can only login through federated login (JWT) issued by trusted issuers.

- Gets predefined permissions with elevation control.

API policy using Open Policy Agent
----------------------------------

**Policy enforcement is done with Open Policy Agent.**

- full request and authn data part of the context. For the list every query
  parameter.

- `show` is evaluated with the requested object in the context.

- `update` gets current and updated object in the context.

- `delete` gets current state in the context.

*Example: prevent server update/deletion with the tag "prod" without special role.*

Policies can differ for different domains. Long-run - customer managed policy injects. 

Next features
-------------

- Complete token restrictions.

- Service accounts.

- Make 2fa eforcement on the domain level, rather than the user level.

- Add TLS as 2fa on the domain level.

- IP Whitelist for auth on the domain level?

- SCIM server functionality


End?
----

Thank you for showing interest!

`https://github.com/gtema/keystone <https://github.com/gtema/keystone>`_
