# mini-orm-b4x
Version: 0.08

A mini object–relational mapping (ORM) that can be use for creating db schema and SQL queries.

# Usage example

## Initialize object
```
    Dim con As SQL = Main.DB.GetConnection ' SQLite or MySQL Pool
    Dim DB1 As ORM
    DB1.Initialize(con)
    DB1.Engine = "MySQL"
```

## Create table
```
    DB1.Table = "tbl_products"
    DB1.Columns.Add(DB1.CreateORMColumn2(CreateMap("Name": "category_id", _
    "Type": DB1.INTEGER)))
    DB1.Columns.Add(DB1.CreateORMColumn2(CreateMap("Name": "product_code", _
    "Length": "12")))
    DB1.Columns.Add(DB1.CreateORMColumn2(CreateMap("Name": "product_name")))
    DB1.Columns.Add(DB1.CreateORMColumn2(CreateMap("Name": "product_price", _
    "Type": DB1.DECIMAL, _
    "Length": "10,2", _
    Default": "0.00")))
    DB1.UseTimestamps = True
    DB1.Foreign("category_id", "id", "tbl_category", "", "")
    DB1.Create
    Wait For (DB1.ExecuteBatch) Complete (Success As Boolean)
    If Success Then		
    	Log("Database is created successfully!")
    Else
    	Log("Database creation failed!")
    End If
    DB1.Close
```
Note: Set `AddAfterCreate = True` before using `Create`

## Insert row (batch non query)
```
    DB1.Columns = Array("category_id", "product_code", "product_name", "product_price")
    DB1.Parameters = Array(2, "T001", "Teddy Bear", 99.9)
    DB1.Insert
```
Note: Set `AddAfterInsert = True` before using `Insert`

## Update row
```
    DB1.Table = "tbl_products"
    DB1.Columns = Columns
    DB1.Parameters = Values
    DB1.Where = Array("id = ?")
    DB1.UpdateModifiedDate = True
    DB1.Save
```

## Soft delete row
```
    DB1.Where = Array("id = ?")
    DB1.Parameters = Array(4)
    DB1.SoftDelete
```

## Permanent delete row
```
    DB1.Where = Array("id = ?")
    DB1.Parameters = Array(4)
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
    Dim Data As Map = DB1.First
```
```
    Dim Data As Map = DB1.Find(2)
```

## Return multiple rows
```
    Dim Data As List
    Data.Initialize
    DB1.Table = "tbl_products"
    DB1.Where = Array("category_id = ?")
    DB1.Parameters = Array(2)
    DB1.OrderBy = CreateMap("id": "ASC")
    DB1.Query
    Data = DB1.Results
```

## Join tables
```
    DB1.Table = "tbl_products p"
    DB1.Select = Array("p.*", "c.category_name")
    DB1.Join = DB1.CreateORMJoin("tbl_category c", "p.category_id = c.id", "")
    DB1.Where = Array("c.category_name = ?")
    DB1.Parameters = Array(value)
    DB1.Query
    Data = DB1.Results
```
