# mini-orm-b4x
Version: 1.07.1

A mini object–relational mapping (ORM) that can be use for creating db schema and SQL queries.
It is suitable for Web API Template or any database system.
Currently it supports SQLite and MySQL.

# Usage example

## Initialize object
```
Dim DB1 As MiniORM
DB1.Initialize(SQL, "MySQL")
```

Note: Before calling DB1.Create and DB1.Insert, set AddAfterCreate and AddAfterInsert to True.
```
DB1.AddAfterCreate = True
DB1.AddAfterInsert = True
```

## Create table
```
DB1.Table = "tbl_category"
DB1.Columns.Add(DB1.CreateORMColumn2(CreateMap("Name": "category_name")))
DB1.UseTimestamps = True
DB1.Create
```

## Insert row (batch non query)
```
DB1.Columns = Array("category_name")
DB1.Parameters = Array("Hardwares")
DB1.Insert
DB1.Parameters = Array("Toys")
DB1.Insert
```

## Update row
```
DB1.Table = "tbl_products"
DB1.Columns = Array("category_id", "product_code", "product_name", "product_price")
DB1.Parameters = Array(NewCategoryId, Item.Get("Product Code"), Item.Get("Product Name"), Item.Get("Product Price"))
DB1.Id = Item.Get("id")
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
DB1.setWhereValue(Array("c.id = ?"), Array(CategoryId))
DB1.Query
Data = DB1.Results
```
