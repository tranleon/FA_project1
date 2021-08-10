import csv
import os
import random
import datetime
from faker import Faker
faker = Faker()


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
    csvwriter.writerow(["IdCustomer","FirstName","LastName","Address","City","Country","DayOfBirth","Gender","ModifiedDate"])
    for i in range(0,rowNum): 
        if(random.randint(0,1)==0):
            gender="Male"
            firstname=faker.first_name_male()
            lastname=faker.last_name_male()
        else:
            gender="Female"
            firstname=faker.first_name_female()
            lastname=faker.last_name_female()
        csvwriter.writerow([i,firstname,lastname,faker.address(),faker.city(),faker.country(),gen_Day1(18,90),gender,datetime.datetime.now()])
##def gen_ProductCategory_CSV(rowNum):
    ##csvfile=open('ProductCategory.csv','w')
    ##csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    ##csvwriter.writerow(["IdProductCategory","Name","ModifiedDate"])
    ##for i in range(0,rowNum):
        ##csvwriter.writerow([i,faker.text(max_nb_chars=20)],datetime.datetime.now())

def gen_Product_CSV(rowNum):
    csvfile=open('Product.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["IdProduct","ProductName","ProductNumber","Standard","ListPrice","ProductCategory","ModifiedDate"])
    for i in range(0,rowNum):
        StandardCost=gen_Money(10000)
        ListPrice=StandardCost+gen_Money(1000)
        csvwriter.writerow([i,faker.text(max_nb_chars=20),faker.license_plate(),StandardCost,ListPrice,faker.text(max_nb_chars=20),datetime.datetime.now()])

def gen_BillHeader_CSV(rowNum,NumOfRef):
    csvfile=open('BillHeader.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["IdBillHeader","CustomerID","SubTotal","TaxAmt","Freight","TotalDue","ModifiedDate"])
    for i in range(0,rowNum):
        csvwriter.writerow([i,NumOfRef,0,gen_Money(50),gen_Money(50),0,datetime.datetime.now()])
    #Subtotal=sum(BillDetail.LineTotal)
    #TotalDue=SubTotal+TaxAmt+Freight
def gen_BillDetail_CSV(rowNum,NumOfRef):
    csvfile=open('BillDetail.csv','w')
    csvwriter=csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["IdBillDetail","BillHeaderID","OrderQty","ProductID","UnitPrice","UnitPriceDiscount","LineTotal","ModifiedDate"])
    for i in range(0,rowNum):
        csvwriter.writerow([i,NumOfRef["Bill"],random.randint(1,30),NumOfRef["Product"],0,gen_Money(50),0,datetime.datetime.now()])
    #UnitPrice=Product.ListPrice
    #LineTotal=(UnitPrice-UnitPriceDiscount)*OrderQty
Cus_num=10000
Prod_num=100000
ProdCate_num=100
BHeader_num=1000000
BDetail_num=5000000
gen_Customer_CSV(Cus_num)
##gen_ProductCategory_CSV(ProdCate_num)
gen_Product_CSV(Prod_num)
gen_BillHeader_CSV(BHeader_num,Cus_num)
gen_BillDetail_CSV(BDetail_num,{"Bill":BHeader_num,"Product":Prod_num})