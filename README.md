# MiniORMUtils-B4X
Version: 5.60

A mini object–relational mapping (ORM) that can be use for creating db schema and SQL queries. \
It is suitable for Web API Template or any database system. \
Currently it supports **SQLite** (for B4A, B4i and B4J), **MariaDB** and **MySQL** (B4J only).

<img src="https://github.com/pyhoon/MiniORMUtils-B4X/blob/main/miniorm.png" width="300" />

# Usage examples
## Initialize object
```b4x
Dim DB As MiniORM
DB.Initialize
```

## Initialize object (no execute)
```b4x
DB.Initialize
DB.DbType = DB.SQLITE
DB.QueryExecute = False
DB.Table = "categories"
Log(DB.Statement)
```

## Set file name for SQLite
```b4x
DB.Settings.DBFile = "app.db"
```

## Set MiniORMSettings for MySQL
```b4x
DB.Initialize
Dim MS As MiniORMSettings
MS.Initialize
MS.DBType = DB.MYSQL
MS.JdbcUrl = "jdbc:mysql://{DbHost}:{DbPort}/{DbName}?characterEncoding=utf8&useSSL=False"
MS.Driver = "com.mysql.cj.jdbc.Driver"
MS.DBName = "app"
MS.DbHost = "localhost"
MS.User = "root"
MS.Password = "password"
DB.Settings = MS
```

## Check database exists
```b4x
#If MySQL Or MariaDB
Wait For (DB.ExistAsync) Complete (DbFound As Boolean)
#Else
Dim DbFound As Boolean = DB.Exist
#End If
If DbFound Then
	LogColor($"${DB.DBType} database found!"$, COLOR_BLUE)
	DB.Open
Else
	LogColor($"${DB.DBType} database not found!"$, COLOR_RED)
	CreateDatabase
End If
```

## Create database
```b4x
#If MySQL Or MariaDB
Wait For (DB.CreateDatabaseAsync) Complete (Success As Boolean)
#Else
Dim Success As Boolean = DB.CreateSQLite
#End If
```

## Connect to database
```b4x
DB.Open
```

## Create table (text only columns)
```b4x
DB.Table = "categories"
DB.Columns = Array("category_code", "category_name")
DB.Create
```

## Create table (with column definitions)
```b4x
DB.Table = "products"
DB.Columns.Add(CreateMap("N": "category_id", "T": DB.INTEGER))
DB.Columns.Add(CreateMap("N": "product_code", "S": 12))
DB.Columns.Add(CreateMap("N": "product_name"))
DB.Columns.Add(CreateMap("N": "product_price", "T": DB.DECIMAL, "S": "10,2", "D": 0.0))
DB.Columns.Add(CreateMap("N": "product_image", "T": DB.BLOB))
DB.Foreign = "category_id"
DB.References("categories", "id")
DB.Create
```

## Insert rows
```b4x
DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
DB.Inserts = Array(2, "T001", "Teddy Bear", 99.9)
DB.Inserts = Array(1, "H001", "Hammer", 15.75)
DB.Inserts = Array(2, "T002", "Optimus Prime", 1000)
```

## Execute NonQuery batch
```b4x
Wait For (DB.ExecuteBatchAsync) Complete (Success As Boolean)
If Success Then
    Log("Database is created successfully!")
Else
    Log("Database creation failed!")
End If
DB.Close
```

## Select all rows
```b4x
DB.Table = "categories"
DB.Query
```

## Return single row
```b4x
DB.Find(3)
If DB.Found Then
    Log(DB.First)
End If
```

## Read rows
```b4x
Dim Data As List = DB.Results
```

## Update row
```b4x
DB.Table = "products"
DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
DB.Id = 2
DB.Save2 = Array(Category_Id, Product_Code, Product_Name, Product_Price)
```

## Soft delete row
```b4x
DB.Id = 3
DB.SoftDelete
```

## Permanent delete row
```b4x
DB.Id = 4
DB.Delete
```

## Batch delete rows
```b4x
DB.Destroy(Array(2, 3))
```

## Return number of rows in query results
```b4x
Dim Rows As Int = DB.RowCount
```

## Filter by conditions
```b4x
DB.Table = "products"
DB.Conditions = Array("category_id = ?", "product_price > ?")
DB.Parameters = Array(2, 50)
DB.OrderBy = CreateMap("id": "DESC")
```

## Join tables
```b4x
DB.Table = "products p"
DB.Columns = Array("p.*", "c.category_name")
DB.Join("LEFT", "categories c", Array("p.category_id = c.id"))
DB.WhereParam("c.id = ?", CategoryId)
```

## Show query logs
```b4x
DB.ShowExtraLogs = True
```

## Add query to batch
```b4x
DB.QueryAddToBatch = True
```
