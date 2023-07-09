# mini-orm
A mini object–relational mapping (ORM) that can be use to scaffold database schema and build SQL queries

# Usage example

## Initialize object
```
    Dim con As SQL = Main.DB.GetConnection

    Dim db1 As ORM
    db1.Initialize(con)
    db1.Table = "tbl_products"
```

## Create table
```
    Dim fields As List
    fields.Initialize
    Dim Col1 As ORMColumn = db1.CreateORMColumn("category_id", db1.INTEGER, "", "", False, False)
    Dim Col2 As ORMColumn = db1.CreateORMColumn("product_code", db1.VARCHAR, "", "", True, False)
    Dim Col3 As ORMColumn = db1.CreateORMColumn("product_name", db1.VARCHAR, "", "", True, False)
    Dim Col4 As ORMColumn = db1.CreateORMColumn("product_price", db1.DECIMAL, "", "'0.00'", True, False)
    fields.AddAll(Array(Col1, Col2, Col3, Col4))
    db1.Table = "product"
    db1.Create(fields, True)
    db1.Foreign("category_id", "id", "tbl_category", "", "")
    db1.Execute

```

## Insert row
```
    db1.DataColumn = CreateMap("category_id": 2, "product_code": "T003", "product_name": "YoYo", "product_price": 9.25)
    db1.Save
```

## Update row
```
    db1.DataColumn = CreateMap("category_id": 2, "product_code": "T004", "product_name": "Remote Control Car", "product_price": 56.5, "modified_date": DateTime.Now)
    db1.Where = Array("id = ?")
    db1.Parameters = Array(4)
    db1.Save
```

## Soft delete row
```
    db1.Where = Array("id = ?")
    db1.Parameters = Array(4)
    db1.SoftDelete
```

## Permanent delete row
```
    db1.Where = Array("id = ?")
    db1.Parameters = Array(4)
    db1.Delete
```

## Batch delete rows
```
    db1.Destroy(Array As Int(2, 3))
```

## Return single row
```
    Utility.ReturnSuccess(db1.First, 200, Response)
```
```
    Utility.ReturnSuccess(db1.Find(2), 200, Response)
```
```
    Utility.ReturnSuccess(CreateMap("count": db1.Count), 200, Response)
```

## Return multiple rows
```
    db1.Where = Array("category_id = ?")
    db1.Parameters = Array(2)
    db1.OrderBy = CreateMap("id": "ASC")
    db1.Query

    Utility.ReturnSuccess2(db1.Results, 200, Response)
```
