# MiniORMUtils-B4X
Version: 2.00

A mini object–relational mapping (ORM) that can be use for creating db schema and SQL queries.
It is suitable for Web API Template or any database system.
Currently it supports **SQLite** and **MySQL** (B4J).

# Usage example

## Initialize object
```
Dim Info As ConnectionInfo
Info.Initialize
info.DBType = "SQLite"
Info.DBFile = "data.db"

Dim Conn As ORMConnector
Conn.Initialize(Info)

Dim DB As MiniORM
DB.Initialize(Conn.DBOpen, Info.DBType)
DB.UseTimestamps = True
DB.QueryAddToBatch = True
```
Note: Before calling DB.Create and DB.Insert, set QueryAddToBatch to True.

## Create table
```
DB.Table = "tbl_category"
DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "category_name")))
DB.Create
```

## Insert rows
```
DB.Columns = Array("category_name")
DB.Insert2(Array As String("Hardwares"))
DB.Insert2(Array As String("Toys"))
```

## Execute NonQuery Batch
```
Wait For (DB.ExecuteBatch) Complete (Success As Boolean)
If Success Then
    Log("Database is created successfully!")
Else
    Log("Database creation failed!")
End If
DB.Close
```

## Select All Rows
```
DB.Table = "tbl_category"
DB.Query
Dim Items As List = DB.Results
```

## Update row
```
DB.Table = "tbl_products"
DB.Columns = Array As String("category_id", "product_code", "product_name", "product_price")
DB.Id = 2
DB.Save2(Array As String(Category_Id, Product_Code, Product_Name, Product_Price))
```

## Soft delete row
```
DB.Id = 3
DB.SoftDelete
```

## Permanent delete row
```
DB.Id = 4
DB.Delete
```

## Batch delete rows
```
DB.Destroy(Array As Int(2, 3))
```

## Return number of rows in query results
```
Dim Rows As Int = DB.RowCount
```

## Return single row
```
Dim Data As Map = DB.Find(2)
```

## Return multiple rows
```
DB.Table = "tbl_products"
DB.Where = Array As String("category_id = ?")
DB.Parameters = Array As String(2)
DB.OrderBy = CreateMap("id": "DESC")
DB.Query
Dim Data As List = DB.Results
```

## Join tables
```
DB.Table = "tbl_products p"
DB.Select = Array("p.*", "c.category_name")
DB.Join = DB.CreateJoin("tbl_category c", "p.category_id = c.id", "")
DB.Where3("c.id", CategoryId)
DB.Query
Dim Data As List = DB.Results
```
