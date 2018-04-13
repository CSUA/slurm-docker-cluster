 #!/bin/sh
# Redirect output to stderr.
exec 1>&2
# enable user input
exec < /dev/tty

echo "Re-adding the passwords to the docker-composes"
make password
