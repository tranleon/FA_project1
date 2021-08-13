# FA_project1
## Project Topic
### E-commerce/Retails
Sales/Customer analysis and trend prediction.

## Decsription of this project
This project is using for demo to FA about how to initialize a project and draft data pipeline.

## Purpose
Building the data pipeline

## Detail of Work
1. Design data pipeline [here](./docs/design.png "Architecture")
2. Ingest data from flat file
3. Extract, captured new and changed data
4. Load new and changed data onto Snowflake
5. Normalize and Denormalize data
6. Build data model
7. Visualize your data

## How to setup
1. Login into MSSQL and run [init_mssql.sql](./src/mssql/init_mssql.sql).
2. Authen SnowSQL and run [init_snowflake.sql](./src/Snowflake/init_snowfalke.sql).
3. [Download](https://sfc-repo.snowflakecomputing.com/snowsql/index.html) and install snowsql CLI.
4. Go to %USERPROFILE%\.snowsql\ to change login config for better automation, using [this document](https://docs.snowflake.com/en/user-guide/snowsql-config.html).
5. Generate data: `python Data_generator.py`, copy into resources/raw-folder.
6. Run /src/SSIS/Project1/Project1.sln, change "ProjectPath" variable to your project path.
7. Deploy Project1.sln on SQL Server.
