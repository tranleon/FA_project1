import csv
import os
import random
import datetime
import faker from Faker


def gen_Money(max):
    return(random.randint(0,max))
def gen_Name1():
    FirstName=["Trần","Nguyễn","Hoàng","Lê","Lý"]
    MiddleName=["Phúc","Văn","Lan","Thị","Minh"]
    LastName=['Lộc',"Nam","Vui","An","Đa","Ân","Can","Đan","Lâm","Lanh","Long","Kiệt"]
    return(random.choice(FirstName)+" "+random.choice(MiddleName)+" "+random.choice(LastName))
def gen_Day1(minAge,maxAge):
    now=datetime.datetime.now()
    yearOfBirth=random.randint(now.year-maxAge,now.year-minAge)
    monthOfBirth=random.randint(1,12)
    day={"1":31,"2":28,"3":31,"4":30,"5":31,"6":30,"7":31,"8":31,"9":"30","10":31,"11":30,"12":31}
    dayOfBirth=random.randint(1,int(day[str(monthOfBirth)]))
    return(datetime.datetime(yearOfBirth,monthOfBirth,dayOfBirth))
def gen_Reference(rowNum):
    return(random.randint(0,rowNum))

def gen_Customer_CSV(rowNum):
    csvfile=open('Customer.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow("Id","FirstName","LastName","Address","City","Country","DayOfBirth","Gender",)
    for i in range(0,rowNum): 
        if(random.randint(0,1)==0):
            gender="Male"
            firstname=faker.first_name_male()
            lastname=faker.last_name_male()
        else:
            gender="Female"
            firstname=faker.first_name_female()
            lastname=faker.last_name_female()
        csvwriter.writerow(i,firstname,lastname,faker.address(),faker.city(),faker.country(),gen_Day1(18,90),gender)
def gen_ProductCategory_CSV():
    csvfile=open('ProductCategory.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow()

def gen_Product_CSV(rowNum):
    csvfile=open('Product.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow("Id","ProductName","ProductNumber","Standard","ListPrice")

def gen_BillHeader_CSV(rowNum):
    csvfile=open('BillHeader.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow("id","")
    for i in range(0,rowNum):
        csvwriter.writerow()