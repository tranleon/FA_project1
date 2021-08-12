import csv
import random
import datetime
import pandas as pd
import requests
from faker import Faker
faker = Faker()

def gen_Money(max):
    return(random.randint(0,max))

def gen_Customer_CSV(rowNum):
    time_stamp = datetime.datetime.now().strftime("%Y_%m_%d-%I_%M_%S_%p")
    # crawl territory data
    url = "http://www.nationsonline.org/oneworld/US-states-by-area.htm"
    r = requests.get(url)
    dfs = pd.read_html(r.text)
    df = dfs[2][["State","Census Region"]]
    state_division_dict = {}
    for i in range(len(df)):
        state_division_dict[df.iloc[i,0]] = df.iloc[i,1]
    csvfile = open(f'CustomerData-{time_stamp}.csv','w', newline='')
    csvwriter = csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["CustomerID","FirstName","LastName","Address","City","State","Territory","DayOfBirth","Gender","ModifiedDate"])
    for i in range(1,rowNum+1): 
        if(random.randint(0,1)==0):
            gender = "Male"
            firstname = faker.first_name_male()
            lastname = faker.last_name_male()
        else:
            gender = "Female"
            firstname = faker.first_name_female()
            lastname = faker.last_name_female()
        state = faker.state()
        territory = state_division_dict[state]    
        csvwriter.writerow([i,firstname,lastname,faker.street_address(),faker.city(),state,territory,
                            faker.date_of_birth(minimum_age=18, maximum_age=65),gender,datetime.datetime.now()])
    csvfile.close()
    print("Fake customer data: Done!")

def gen_Product_CSV(rowNum):
    time_stamp = datetime.datetime.now().strftime("%Y_%m_%d-%I_%M_%S_%p")
    csvfile = open(f'ProductData-{time_stamp}.csv','w', newline='')
    csvwriter = csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["ProductID","ProductName","ProductNumber","StandardCost","ListPrice","ProductCategory","ModifiedDate"])
    for i in range(1,rowNum+1):
        StandardCost = gen_Money(10000)
        ListPrice = StandardCost+gen_Money(1000)
        Category = random.choices(["Clothing","Novelty Items","Toys","Packing Materials",
                                   "Accessories","Sports","Personal Care"], 
                                weights=[6,4,1,3,7,1,3], k=1)[0] 
        csvwriter.writerow([i,faker.text(max_nb_chars=20),faker.license_plate(),
                            StandardCost,ListPrice,Category,datetime.datetime.now()])
    csvfile.close()
    print("Fake product data: Done!")

def gen_BillDetail_CSV(rowNum, customerNum, productNum):
    time_stamp = datetime.datetime.now().strftime("%Y_%m_%d-%I_%M_%S_%p")
    csvfile = open(f'BillData-{time_stamp}.csv','w', newline='')
    csvwriter = csv.writer(csvfile,delimiter=',',quotechar='"',quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["BillDetailID","BillHeaderID","OrderDate","CustomerID","ProductID","OrderQty","ModifiedDate"])
    j = 1
    date = datetime.datetime(2010,1,1)
    customerid = faker.random_int(1,customerNum)
    for i in range(1,rowNum+1):
        csvwriter.writerow([i,j,date,customerid,faker.random_int(1,productNum),
                            int(faker.random_int(1,20)*(1+i/rowNum)),datetime.datetime.now()]) # Increasing OrderQty
        if faker.boolean(chance_of_getting_true=33):
                j += 1
                customerid = faker.random_int(1,customerNum)
                if faker.boolean(chance_of_getting_true=(3-2*(i/rowNum))): # Increasing Bill per Day
                    date = date + datetime.timedelta(days=1)
    csvfile.close()
    print("Fake bill data: Done!")
                   
Cus_num=10000
Prod_num=1000
BDetail_num=1000000

gen_Customer_CSV(Cus_num)
gen_Product_CSV(Prod_num)
gen_BillDetail_CSV(BDetail_num,Cus_num,Prod_num)