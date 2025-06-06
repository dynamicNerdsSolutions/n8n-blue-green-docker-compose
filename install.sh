mkdir -p /etc/caddy/sites-enabled

#prompt for the url to use while not valid in a do while loop and store it in a variable
url=""
while [[ ! "$url" =~ ^[a-zA-Z0-9.-]+$ ]]; do
  read -p "Enter the url to use: (example: n8n.example.com)" url
  if [[ "$url" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    break
  else
    echo "Invalid url"
  fi
done

#use the url to generate the projectname in snake case
projectname=$(echo "$url" | sed 's/\./_/g' | sed 's/-/_/g')

#copy the caddyfile into one with the projectname in the name
echo "Copying Caddyfile to ${projectname}"
cp caddy/Caddyfile caddy/${projectname}

#replace the url in the caddyfile
echo "Replacing url in ${projectname} Caddyfile"
#initial value is automation.MY_DOMAIN.TLD
sed -i "s/automation.MY_DOMAIN.TLD/${url}/g" caddy/${projectname}

echo "Moving Caddyfile to /etc/caddy/sites-enabled/${projectname}"
mv caddy/${projectname} /etc/caddy/sites-enabled/${projectname}

#store the projectname in a .caddypath file
touch .caddypath
echo "/etc/caddy/sites-enabled/${projectname}" > .caddypath



echo "Validating /etc/caddy structure"
#Check if a Caddyfile exists
if [ ! -f /etc/caddy/Caddyfile ]; then
  echo "Caddyfile does not exist, creating default"
  #write an import on top of the file
  touch /etc/caddy/Caddyfile
  echo "import /etc/caddy/sites-enabled/*" > /etc/caddy/Caddyfile
else 
  echo "Caddyfile exists"
  #check if the import is present
  echo "Checking if import sites-enabled is present"
  if ! grep -q "import /etc/caddy/sites-enabled/*" /etc/caddy/Caddyfile; then
    echo "Import sites-enabled is not present, adding it"
    #add an import on top of the file with a break line
    sed -i '1i\import /etc/caddy/sites-enabled/*' /etc/caddy/Caddyfile
    echo "Import added"
  else 
    echo "Import is present, skipping"
  fi
fi

#check if caddy is running
if ! systemctl is-active --quiet caddy; then
  echo "Caddy is not running, starting it"
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable --now caddy
else
  echo "Caddy is running, reloading"
  sudo systemctl reload caddy
fi

echo "Setting up n8n storage folder..."
#check if n8n_storage folder exists
if [ ! -d "n8n_storage" ]; then
  echo "n8n storage folder does not exist, creating it"
  mkdir -p n8n_storage/custom
  echo "n8n storage folder created"
else
  echo "n8n storage folder already exists"
  echo "Checking if n8n_storage/custom folder exists..."
  #check if custom folder exists
  if [ ! -d "n8n_storage/custom" ]; then
    echo "n8n_storage/custom folder does not exist, creating it"
    mkdir -p n8n_storage/custom
    echo "n8n_storage/custom folder created"
  else
    echo "n8n_storage/custom folder already exists"
  fi
fi
echo "Setting permissions..."
sudo chown -R 1000:1000 n8n_storage
sudo chmod -R 755 n8n_storage
echo "Permissions set"

echo "Done!"