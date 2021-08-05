import csv
import os
import random
import datetime


def gen_Money(max):
    return(random.randint(0,max))
def gen_Name():
    FirstName=["Trần","Nguyễn","Hoàng","Lê","Lý"]
    MiddleName=["Phúc","Văn","Lan","Thị","Minh"]
    LastName=['Lộc',"Nam","Vui","An","Đa","Ân","Can","Đan","Lâm","Lanh","Long","Kiệt"]
    return(random.choice(FirstName)+" "+random.choice(MiddleName)+" "+random.choice(LastName))
def gen_Day(minAge,maxAge):
    now=datetime.datetime.now()
    yearOfBirth=random.randint(now.year-maxAge,now.year-minAge)
    monthOfBirth=random.randint(1,12)
    day={"1":31,"2":28,"3":31,"4":30,"5":31,"6":30,"7":31,"8":31,"9":"30","10":31,"11":30,"12":31}
    dayOfBirth=random.randint(1,int(day[str(monthOfBirth)]))
    return(datetime.datetime(yearOfBirth,monthOfBirth,dayOfBirth))
print(gen_Day(18,90))