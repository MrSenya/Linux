#!/bin/bash

block_ip (){
#echo "block !!!"
for i in {1..24};
do
echo "---Block on VH${i}---";
ssh vh${i} csf -td  ${ip} 998600;
done
exit 0
}

unblock_ip (){
#echo "unblock !!!"
for i in {1..24};
do
echo "---UnBlock on VH${i}---";
ssh vh${i} csf -tr ${ip} ;
done
exit 0
}

csf_restart () {
#echo "restart !!!"
for i in {1..24};
do
echo "---Restart on VH${i}---";
ssh vh${i} csf -r ;
done
exit 0
}

printf ' [b] Block ip`s\n [u] Unblock ip`s\n [r] Restart csf\n > '
read var

case $var in
     b)
          csf="block_ip"
          ;;
     u)
          csf="unblock_ip"
          ;;
     r)
          csf_restart
          ;;
     *)
          echo "Pls try again  !"
          exit 0
          ;;
esac

read -p "Specify ip - " ip
if [ -z "${ip}" ]; then
echo "Var is empty ! "
else
${csf}
fi
