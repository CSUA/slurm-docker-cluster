 #!/bin/sh
# Redirect output to stderr.
exec 1>&2
# enable user input
exec < /dev/tty

regexp=$(cat mysql_password.txt)
# CHECK
if test $(git diff --cached | grep $regexp | wc -l) != 0
then
  exec git diff --cached | grep -ne $regexp
  read -p "There are some occurrences of the mysql password at your modification. Are you sure want to continue? (y/n)" yn
  echo $yn | grep ^[Yy]$
  if [ $? -eq 0 ]
  then
    exit 0; #THE USER WANTS TO CONTINUE
  else
    exit 1; # THE USER DONT WANT TO CONTINUE SO ROLLBACK
  fi
fi
