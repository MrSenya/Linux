#!/bin/bash

echo -n "Введите внутрений номер сервера: "
read server

#figlet -f 'Slant Relief' '${server}' -w 300 > /var/www/html/install/bash_banner
cp /root/mss/script/reinstall_unix_template.sh /var/www/html/install/${server}.sh

echo "************************************************************************"
echo "Ссылка для скачивания скрипта: http://localhost/install/${server}.sh"
echo "************************************************************************"

