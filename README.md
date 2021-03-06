# strapi-cas-example
Demonstrate login to strapi via CAS

### Pre-requisites
Docker - to run CAS Intializr
Java 11 - to build and run CAS
Node - to run strapi
Yarn - to build strapi
Git - to clone strapi
Curl - to access CAS Intializr and generate CAS Overlay
Bash - tested on Windows with msys2


# Run CAS
```
run-cas.sh
```
This will run the CAS Intializr locally which will be used create a CAS Overlay project with support for OIDC. It will them proceed to build the CAS application using gradle, generate a certificate for the CAS server, and run the CAS server.
CAS will be running with a default in-memory dummy login: casuser/Mellon
The CAS "stub" repository will return a hard-coded e-mail address. 

Normally CAS would be connected to LDAP or some other user repository but this is just testing the OIDC exchange with Strapi. 

CAS will be accessible at `https://localhost:8443/cas` 


# Run Strapi
```
run-strapi.sh
```
This will clone strapi repository containing the CAS intregation code, build strapi, and run the getting started example. 

After strapi starts up, create an admin account and login to the admin console.

Click on `Settings -> Providers -> CAS`
and enter the following:
Enable: `On`
Client ID: `strapi`
Client Secret: `strapisecret`
Host URI(subdomain): `localhost:8443/cas`

Leave redirect URLs alone and click Save.

Normally you would access a CAS authetnicated app and login so that when you hit strapi via XHR you would already be logged 
in and CAS SSO would log you in to strapi. In this case we will just hit the /connect/cas endpoint in strapi, login and 
see the JWT token that an app would send to strapi on subsequent requests as an HTTP header.

Browse to http://localhost:1337/connect/cas

Get redirected to CAS, plow through SSL warning, login as `casuser` with password of `Mellon`

OIDC Happens

See JWT 


