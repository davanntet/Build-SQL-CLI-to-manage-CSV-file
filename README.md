# Welcome to My Sqlite
***

## Task
This project is an implementation of a simple SQLite-like database system in Ruby. It allows you to perform basic SQL operations such as SELECT, INSERT, UPDATE, DELETE, and JOIN on CSV files treated as database tables. The project consists of two main parts:

- A class called MySqliteRequest that builds and executes queries.
- A command-line interface (CLI) to run SQL-like commands interactively.

## Description
The goal of this project is to simulate an SQLite query system using Ruby. The system allows users to perform SQL operations on CSV files by building and executing queries in a progressive manner using the MySqliteRequest class. The system can handle:

- SELECT queries to retrieve data.
- INSERT queries to add new records.
- UPDATE queries to modify existing records.
- DELETE queries to remove records.
- JOIN queries to combine data from two tables.
- WHERE conditions to filter records.
- ORDER clauses to sort records.
Each row in the CSV files is treated as a record, and every record must have an ID.

## Installation
There is no specific installation, all you need to have, is Ruby installed on your system.

## Usage
- Once you have started the CLI with:
```
ruby my_sqlite_cli.rb
```
- To quit CLI:
```
quit
```

Example:
 - select * from moives
 - select Film,Year from moives
 - select Film,Year from moives where Year=2009
 - select Film,Year from moives order by Year
 - select * from moives where Year=2009 order by AudienceScore
 - select * from moives where Year=2009 order by AudienceScore desc
 - select * from moives join moives1 on moives.ID=moives1.ID
 - select * from moives join moives1 on moives.ID=moives1.ID where id=6 
 - select * from moives join moives1 on moives.ID=moives1.ID order by Year
 - select * from moives join moives1 on moives.ID=moives1.ID order by Year desc
 - delect from moives where ID=6
 - update moives set Film=Spiderman where ID=6
 - insert into moives values(31, "AnotherMovie", "Action", "Warner", 120, 4.1223, 60, "$100.25", 2011)


### The Core Team

- Author: Un Sreypich & Tet Davann
<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt='Qwasar SV -- Software Engineering School's Logo' src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px' /></span>
