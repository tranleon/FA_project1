import csv
import random
import datetime
import pandas as pd
from distutils.dir_util import copy_tree
from faker import Faker
import os
fake = Faker()


def install_and_import(package):
    import importlib
    try:
        importlib.import_module(package)
    except ImportError:
        import pip
        pip.main(['install', package])
    finally:
        globals()[package] = importlib.import_module(package)


install_and_import('pandas')
install_and_import('faker')
install_and_import('lxml')


def gen_Money(max):
    return (random.randint(0, max))


def gen_Customer_CSV(rowNum):
    raw_path = os.path.dirname(__file__) + '/' + 'rawdata'
    # crawl territory data
    print(raw_path)
    dfs = pd.read_html(
        "https://github.com/cphalpert/census-regions/blob/master/us%20census%20bureau%20regions%20and%20divisions.csv")
    df = dfs[0][["State", "Division"]]
    state_division_dict = {}
    for i in range(len(df)):
        state_division_dict[df.iloc[i, 0]] = df.iloc[i, 1]
    csvfile = open(f'{raw_path}\CustomerData.csv', 'w', newline='')
    csvwriter = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(["CustomerID", "Account", "FirstName", "LastName", "Address",
                        "City", "State", "Territory", "DayOfBirth", "Gender"])
    account = [fake.unique.ascii_email() for i in range(rowNum)]
    for i in range(1, rowNum + 1):
        if (random.randint(0, 1) == 0):
            gender = "Male"
            firstname = fake.first_name_male()
            lastname = fake.last_name_male()
        else:
            gender = "Female"
            firstname = fake.first_name_female()
            lastname = fake.last_name_female()
        state = fake.state()
        territory = state_division_dict[state]
        csvwriter.writerow([i, account[i - 1], firstname, lastname, fake.street_address(), fake.city()
                               , state, territory, fake.date_of_birth(minimum_age=18, maximum_age=65), gender])
    csvfile.close()
    print("Fake customer data: Done!")


def gen_Product_CSV(rowNum):
    productnumber = [fake.unique.bothify(text='???-###') for i in range(rowNum)]
    raw_path = os.path.dirname(__file__) + '/' + 'rawdata'
    csvfile = open(f'{raw_path}\Product.csv', 'w', newline='')
    csvwriter = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(
        ["ProductID", "ProductNumber", "ProductName", "StandardCost", "ListPrice", "ProductCategory"])
    for i in range(1, rowNum + 1):
        StandardCost = gen_Money(10000)
        ListPrice = StandardCost + gen_Money(1000)
        Category = random.choices(["Clothing", "Novelty Items", "Toys", "Packing Materials",
                                   "Accessories", "Sports", "Personal Care"],
                                  weights=[6, 4, 1, 3, 7, 1, 3], k=1)[0]
        csvwriter.writerow([i, productnumber[i - 1], fake.text(max_nb_chars=20),
                            StandardCost, ListPrice, Category])
    csvfile.close()
    print("Fake product data: Done!")


def gen_BillDetail_CSV(rowNum, customerNum, productNum):
    raw_path = os.path.dirname(__file__) + '/' + 'rawdata'
    csvfile = open(f'{raw_path}\BillData.csv', 'w', newline='')
    csvwriter = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    csvwriter.writerow(
        ["BillDetailID", "OrderDate", "CustomerID", "ProductID", "OrderQty"])
    for i in range(1,rowNum+1):
        csvwriter.writerow([i,fake.date_between(start_date='-5y', end_date='-1y'),random.randint(1, customerNum),random.randint(1, productNum),random.randint(1,10)])
    csvfile.close()

    print("Fake bill data: Done!")


Cus_num = 21
Prod_num = 20
BDetail_num = 1100

gen_Customer_CSV(Cus_num)
gen_Product_CSV(Prod_num)
gen_BillDetail_CSV(BDetail_num, Cus_num, Prod_num)
copy_tree('./rawdata', './workfolder')
