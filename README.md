# MiniORMUtils-B4X
Version: 1.09

A mini object–relational mapping (ORM) that can be use for creating db schema and SQL queries.
It is suitable for Web API Template or any database system.
Currently it supports **SQLite** and **MySQL** (B4J).

# Usage example

## Initialize object
```
Dim MDB As MiniORM
MDB.Initialize(CreateDBConnection, DBEngine)
MDB.ShowExtraLogs = True
MDB.UseTimestamps = True
MDB.AddAfterCreate = True
MDB.AddAfterInsert = True
```
Note: Before calling DB1.Create and DB1.Insert, set AddAfterCreate and AddAfterInsert to True.

## Create table
```
MDB.Table = "tbl_category"
MDB.Columns.Add(MDB.CreateORMColumn2(CreateMap("Name": "category_name")))
MDB.Create
```

## Insert rows
```
MDB.Columns = Array("category_name")
MDB.Parameters = Array As String("Hardwares")
MDB.Insert
MDB.Parameters = Array As String("Toys")
MDB.Insert
```

## Execute NonQuery Batch
```
Wait For (MDB.ExecuteBatch) Complete (Success As Boolean)
If Success Then
    Log("Database is created successfully!")
Else
    Log("Database creation failed!")
    Log(LastException)
End If
DBConnector.DBClose
```

## Select All Rows
```
DB1.Table = "tbl_category"
DB1.Query
Dim Items As List
Items.Initialize
If DB1.RowCount > 0 Then Items = DB1.Results
```

## Update row
```
DB1.Table = "tbl_products"
DB1.Columns = Array("category_id", "product_code", "product_name", "product_price")
DB1.Parameters = Array As String(Category_Id, Product_Code, Product_Name, Product_Price)
DB1.Save
```

## Soft delete row
```
DB1.Id = 3
DB1.SoftDelete
```

## Permanent delete row
```
DB1.Id = 4
DB1.Delete
```

## Batch delete rows
```
DB1.Destroy(Array As Int(2, 3))
```

## Return number of rows in query results
```
Dim Rows As Int = DB1.RowCount
```

## Return single row
```
Dim Data As Map = DB1.Find(2)
```

## Return multiple rows
```
Dim Data As List
Data.Initialize
DB1.Table = "tbl_products"
DB1.Where = Array("category_id = ?")
DB1.Parameters = Array As String(2)
DB1.OrderBy = CreateMap("id": "DESC")
DB1.Query
Data = DB1.Results
```

## Join tables
```
DB1.Table = "tbl_products p"
DB1.Select = Array("p.*", "c.category_name")
DB1.Join = DB1.CreateORMJoin("tbl_category c", "p.category_id = c.id", "")
DB1.setWhereValue(Array("c.id = ?"), Array(CategoryId))
DB1.Query
Data = DB1.Results
```
