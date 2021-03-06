#!/bin/bash
DATA='{"email":"admin@example.org","password":"P@ssw0rd","firstname":"Strapi","lastname":"Admin"}'
echo $DATA > .admin.txt
cat .admin.txt
curl -X POST -H "Content-Type: application/json" http://localhost:1337/admin/register-admin --data @./.admin.txt
rm .admin.txt
