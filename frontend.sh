#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%h-%m-%s)
mkdir -p LOGS_FOLDER
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USER_ID=$(id -u)

CHECK_ROOT(){
    if [ $USER_ID -ne 0 ]
    then 
        echo -e " $R Please login with root user privilages $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $? -ne 0 ]
    then 
        echo -e "$2 is $R FAILED..$N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$2 is $G SUCCESSFULL.. $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling Nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend application code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting Frontend code"

systemctl restart nginx 
VALIDATE $? "Restarting nginx"





