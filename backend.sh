#!/bin/bash
LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
mkdir -p $LOGS_FOLDER
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USERID=$(id -u)

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo" Please login with root user privileges" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e "$2 is $R FAILED.. $N" | tee -a $LOG_FILE
        exit1
    else 
        echo -e "$2 is $G SUCCESSFULL..$N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at $(date)" | tee -a $LOG_FILE

CHECK_ROOT


dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "disable default nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "enable nodejs:20"

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then  
    echo -e "expense user not exist... $G CREATING $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating expense user"
else
    echo -e "expense user already exists.. $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip  &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/*  #Remove the existing code
unzip /tmp/backend.zip  &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service 

#load the data before running backend
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL client"

mysql -h mysql.mansoor.fun -uroot -pExpenseApp@1 < /app/schema/backend.sql 
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarted backend"
