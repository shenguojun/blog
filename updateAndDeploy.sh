#!/bin/bash

echo -e "\033[0;32mUpdating submodules...\033[0m"

cd public
git pull
cd ..
cd themes/beautifulhugo
git pull

# Come Back up to the Project Root
cd ../..
echo -e "\033[0;32mUpdating project...\033[0m"
git pull
./deploy.sh