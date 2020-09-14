#!/bin/bash

rclone sync /home/deaxo/Documents/ mega:hosting.ua
curl -s -X POST https://api.telegram.org/bot1001500810:AAEg1DAZLMvKgBXQ8e4YY-lmE-Bn4RXEff8w/sendMessage -d chat_id=-3934297331 -d text='Backup done!'
