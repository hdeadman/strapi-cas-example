# strapi-cas-example
Demonstrate login to Strapi via CAS - 
- Generate CAS Overlay using CAS Intializr -
- Start CAS server from fresh overlay, copy in Strapi service definition.
- Start LDAP server (Samba AD) in Docker container for CAS to authenticate against (dummy user auth also available)
- Start a Strapi application with the user-permissions plugin CAS provider pre-configured in bootstrap.js
- Register strapi admin via curl
- Use Puppeteer script to login to CAS and then hit the Strapi CAS authentication URL to obtain a JWT. 


### Pre-requisites for running locally
- Java 11 JDK - to build and run CAS overlay (Gradle will bootstrap itself)
- Node - to run Strapi
- Yarn - to build Strapi
- Git - to clone strapi project
- Curl - to access CAS Intializr and generate CAS Overlay
- Bash - tested on Windows with msys2, also on Ubuntu via Github Actions
- Docker - to run LDAP Server (optional)

If using msys2 on windows, you have to add all of those tools to your path. 
Use the `./check_prereqs.sh` script to see if everything is available.

# Run CAS
```
./run-cas.sh
```
This uses the CAS Intializr to create a CAS Overlay project with support for OIDC. 
It then builds the CAS application using gradle, generates an SSL certificate for the CAS server, and runs the CAS server.
CAS will be running with a default in-memory dummy user repository with a single user with credentials: `casuser/Mellon`
The CAS "stub" repository will return a hard-coded e-mail address. 

This example also runs a Samba server (via Docker) to simulate and Active Directory LDAP server and includes the 
CAS `ldap` module to support login with users created in the sameple directory. Run the `ldap/run-ad-server.sh` script to start the directory which
will seed the directory with sample users and copy a trust store into the CAS server folder so CAS will trust the directory 
when doing `starttls` to the directory. See the `run-ad-server.sh` script for test users.

CAS will be accessible after startup at `https://localhost:8443/cas` 

CAS has lots of options for configuring attributes from different sources and they can be specific to individual apps
(called "services" in CAS). One of those sources could be a groovy script that returned attributes so a CAS admin should be 
able to control which attribute names are passed to Strapi and what they are called.

By default CAS returns attributes in an "attributes" map in the JSON but this `run-cas.sh` script can be run with `FLAT` as the 
first argument and CAS will return the attributes as top-level JSON attributes. 

# Run Strapi
```
./run-strapi.sh
```
This will clone strapi repository containing the CAS intregation code, build strapi via `yarn setup`, 
and run the getting started example via `yarn develop`. 
SSL validation is turned off so OIDC callback to CAS will work with self-signed certificate.

The user-permissions bootstrap.js file is copied in from `strapi-custom/bootstrap.js` with the CAS 
provider pre-enabled and configured for this example. 

# Manual steps
After strapi starts up, browse to `http://localhost:1337` and create an admin account and login to the admin console. (alternatively, call `./register_strapi_admin.sh`)

The following steps aren't necessary because the boostrap.js config for user-permissions was copied in 
to the example application with these settings already in place.

1. Click on `Settings -> Providers -> CAS`
2. Enter the following:
- Enable: `On`
- Client ID: `strapi`
- Client Secret: `strapisecret`
- Host URI(subdomain): `localhost:8443/cas`
3. Leave redirect URLs alone and click Save.

Normally you would access a CAS authenticated app and login so that when you hit strapi's login endpoint via XHR you 
would already be logged in and CAS SSO would log you in to strapi. 
In this example we just hit the `http://localhost:1337/connect/cas` endpoint in strapi, 
login to CAS, and see the JWT token that an app would send to strapi on subsequent requests as an HTTP `Authorization` header.

1. Browse to http://localhost:1337/connect/cas

2. Get redirected to CAS, plow through SSL warning

3. Login as `casuser` with password of `Mellon`

4. OIDC Happens

5. See JWT in browser

6. Use JWT as the value for the `Authorization` HTTP header on subsequent requests to strapi that require authentication. 

# Github Actions Workflow
This project has a Github Actions workflow that runs these tests and uses a puppeteer script to test the
authentication exchange.

# Optional steps
CAS returns attributes in a map called `attributes` by default. It can be run in `FLAT` mode using an option. 

Here is what the attributes in the response body look like by default (`NESTED`):
```
{"sub":"casuser","service":"http://localhost:1337/connect/cas/callback","auth_time":1615051264,"attributes":{"email":"casuser@apereo.org"},"id":"casuser","client_id":"strapi"}
```

Here is what the attributes look like in FLAT mode, which you can enable in this example by running `./run-cas.sh FLAT`
```
{"email":"casuser@apereo.org","sub":"casuser","service":"http://localhost:1337/connect/cas/callback","auth_time":1615052215,"id":"casuser","client_id":"strapi"}

```
To find out what your attributes look like in Strapi, you can add:
```
console.log('CAS Response Body: ' + JSON.stringify(body));
```
to `./strapi/packages/strapi-plugin-users-permissions/services/Providers.js` where the CAS body is parsed for the username and email. That Providers.js file can also exist as an extension in your strapi application: `extensions/users-permissions/services/Providers.js`. You shouldn't have to customize that in Strapi b/c CAS lets you control what attributes are returned to Strapi.
