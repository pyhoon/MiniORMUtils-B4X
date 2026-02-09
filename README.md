# MiniORMUtils-B4X
Version: 4.00

A mini object–relational mapping (ORM) that can be use for creating db schema and SQL queries. \
It is suitable for Web API Template or any database system. \
Currently it supports **SQLite** for (B4A, B4i and B4J), **MariaDB** and **MySQL** (B4J only).

<img src="https://github.com/pyhoon/MiniORMUtils-B4X/blob/main/miniorm.png" width="300" />

# Usage example

## Initialize object
```b4x
Private DB As MiniORM
Private MS As ORMSettings

DB.Initialize
MS.Initialize
MS.DBType = "SQLite"
MS.DBFile = "data.db"
MS.DBDir = File.DirApp
DB.Settings = MS

If DB.Exist Then
	LogColor($"${MS.DBType} database found!"$, COLOR_BLUE)
	DB.Open
Else
	LogColor($"${MS.DBType} database not found!"$, COLOR_RED)
	CreateDatabase
End If
```
Note: Before calling DB.Create and DB.Insert, set DB.QueryAddToBatch = True

## Create database
```b4x
#If MySQL Or MariaDB
Wait For (DB.CreateDatabaseAsync) Complete (Success As Boolean)
#Else
Dim Success As Boolean = DB.InitializeSQLite
#End If
```

## Create table
```b4x
DB.Table = "tbl_category"
DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "category_name")))
DB.Create
```

## Insert rows
```b4x
DB.Columns = Array("category_name")
DB.Insert2(Array("Hardwares"))
DB.Insert2(Array("Toys"))
```

## Execute NonQuery Batch
```b4x
Wait For (DB.ExecuteBatch) Complete (Success As Boolean)
If Success Then
    Log("Database is created successfully!")
Else
    Log("Database creation failed!")
End If
DB.Close
```

## Select All Rows
```b4x
DB.Table = "tbl_category"
DB.Query
Dim Items As List = DB.Results
```

## Update row
```b4x
DB.Table = "tbl_products"
DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
DB.Id = 2
DB.Save2(Array(Category_Id, Product_Code, Product_Name, Product_Price))
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

## Return single row
```b4x
Dim Data As Map = DB.Find(2)
```

## Return multiple rows
```b4x
DB.Table = "tbl_products"
DB.Where = Array As String("category_id = ?")
DB.Parameters = Array(2)
DB.OrderBy = CreateMap("id": "DESC")
DB.Query
Dim Data As List = DB.Results
```

## Join tables
```b4x
DB.Table = "tbl_products p"
DB.Select = Array("p.*", "c.category_name")
DB.Join = DB.CreateJoin("tbl_category c", "p.category_id = c.id", "")
DB.WhereParam("c.id = ?", CategoryId)
DB.Query
Dim Data As List = DB.Results
```
