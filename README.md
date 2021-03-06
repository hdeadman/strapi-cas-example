# strapi-cas-example
Demonstrate login to Strapi via CAS

### Pre-requisites for running locally
- Docker - to run CAS Intializr
- Java 11 JDK - to build and run CAS overlay (Gradle will bootstrap itself)
- Node - to run Strapi
- Yarn - to build Strapi
- Git - to clone strapi project
- Curl - to access CAS Intializr and generate CAS Overlay
- Bash - tested on Windows with msys2, also on Ubuntu via Github Actions

If using msys2 on windows, you have to add all of those tools to your path. 
Use the `./check_prereqs.sh` script to see if everything is available.


# Run CAS
```
./run-cas.sh
```
This will run the CAS Intializr locally which will be used create a CAS Overlay project with support for OIDC. 
It will then proceed to build the CAS application using gradle, generate an SSL certificate for the CAS server, and run the CAS server.
CAS will be running with a default in-memory dummy user repository with a single user with credentials: `casuser/Mellon`
The CAS "stub" repository will return a hard-coded e-mail address. 

Normally CAS would be connected to LDAP or some other user repository but this is just testing the OIDC exchange with Strapi
and Strapi only needs a user with an email address.

CAS will be accessible after startup at `https://localhost:8443/cas` 

CAS has lots of options for configuring attributes from different sources and they can be specific to individual apps
(called "services" in CAS). One of those sources could be a groovy script that returned attributes so a CAS admin should be 
able to control which attribute names are passed to Strapi. 

By default CAS returns attributes in an "attributes" map in the JSON but this `run-cas.sh` script can be run with `FLAT` as the first argument 
and CAS will return the attributes as top-level JSON attributes. 

# Run Strapi
```
./run-strapi.sh
```
This will clone strapi repository containing the CAS intregation code, build strapi via `yarn setup`, 
and run the getting started example via `yarn develop`. 
SSL validation is turned off so OIDC callback to CAS will work with self-signed certificate.

# Manual steps
After strapi starts up, browse to `http://localhost:1337` and create an admin account and login to the admin console.

1. Click on `Settings -> Providers -> CAS`
2. and enter the following:
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


# Optional steps
CAS returns attributes in a map called `attributes` by default. It can be run in `FLAT` mode using an option. 

Here is what the attributes in the response body look like by default:
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
