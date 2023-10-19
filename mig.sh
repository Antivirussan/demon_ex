#!/bin/bash

echo "enter your login"

read login

echo "enter your password"

read name

echo "enter your db name"

read dbname

echo "enter ip your remote"

read ip


curl http://$login:$password@$ip:5984/$dbname/_all_docs?include_docs=true > $dbname.json

echo "your json file saved at" $pwd