# strapi-cas-example
Demonstrate login to Strapi via CAS

### Pre-requisites for running locally
Docker - to run CAS Intializr
Java 11 JDK - to build and run CAS overlay (Gradle will bootstrap itself)
Node - to run Strapi
Yarn - to build Strapi
Git - to clone strapi project
Curl - to access CAS Intializr and generate CAS Overlay
Bash - tested on Windows with msys2, also on Ubuntu via Github Actions


# Run CAS
```
./run-cas.sh
```
This will run the CAS Intializr locally which will be used create a CAS Overlay project with support for OIDC. 
It will them proceed to build the CAS application using gradle, generate a certificate for the CAS server, and run the CAS server.
CAS will be running with a default in-memory dummy login: casuser/Mellon
The CAS "stub" repository will return a hard-coded e-mail address. 

Normally CAS would be connected to LDAP or some other user repository but this is just testing the OIDC exchange with Strapi. 

CAS will be accessible after startup at `https://localhost:8443/cas` 


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

Normally you would access a CAS authenticated app and login so that when you hit strapi via XHR you would already be logged 
in and CAS SSO would log you in to strapi. In this example we just hit the `http://localhost:1337/connect/cas` endpoint in strapi, 
login to CAS and see the JWT token that an app would send to strapi on subsequent requests as an HTTP header.

1. Browse to http://localhost:1337/connect/cas

2. Get redirected to CAS, plow through SSL warning

3. Login as `casuser` with password of `Mellon`

4. OIDC Happens

5. See JWT 

6. Use JWT as the value for the `Authorization` HTTP header on subsequent requests to strapi that require authentication. 
