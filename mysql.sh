#!/bin/bash 

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USERID=$(id -u)

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then 
        echo -e "$R please run this script with root privileges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R FAILED..$N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is  $G SUCCESSFULL.. $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE
CHECK_ROOT 

dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "Installing MySQL server"  

systemctl enable mysqld &>>$LOG_FILE 
VALIDATE $? "Enabled MySQL server"   

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Started MySQL server" 

mysql -h mysql.mansoor.fun -u root -pExpenseApp -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
 then 
    echo -e "$Y MySQL root password is not setup, setting now $N" | tee -a $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
    VALIDATE $? "Setting up root password"
else 
    echo -e "MySQL root password is already set-up $Y Skipping... $N" | tee -a $LOG_FILE
fi