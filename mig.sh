#!/bin/bash

echo "enter your login"

read login

echo "enter your password"

read password

echo "enter your db name"

read dbname

echo "enter ip:port your remote db"

read ip


curl http://$login:$password@$ip/$dbname/_all_docs?include_docs=true > $dbname.json

echo "your json file saved" 