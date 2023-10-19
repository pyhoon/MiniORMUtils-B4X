B4J=true
Group=Modules
ModulesStructureVersion=1
Type=Class
Version=9.71
@EndOfDesignText@
' Mini Object-Relational Mapper (ORM) class
' Version 0.08
Sub Class_Globals
	Public SQL As SQL
	Public INTEGER As String = "INTEGER"
	Public DECIMAL As String = "NUMERIC"
	Public VARCHAR As String = "TEXT"
	Public ORMTable As ORMTable
	Public ORMResult As ORMResult
	Private DBColumns As List
	Private DBParameters As List
	Private DBEngine As String
	Private DBTable As String
	Private DBStatement As String
	Private DBPrimaryKey As String
	Private DBForeignKey As String
	Private DBGroupBy As String
	Private DBOrderBy As String
	Private DBLimit As String
	Private Condition As String
	Private BlnFirst As Boolean
	Private BlnUseTimestamps As Boolean
	Private BlnUseTimestampsWithUserId As Boolean
	Private BlnUpdateModifiedDate As Boolean
	Private BlnAddAfterCreate As Boolean
	Private BlnAddAfterInsert As Boolean
	Private DateTimeMethods As Map
	Private const COLOR_RED As Int = -65536			'ignore
	Private const COLOR_GREEN As Int = -16711936	'ignore
	Private const COLOR_BLUE As Int = -16776961		'ignore
	Private const COLOR_MAGENTA As Int = -65281		'ignore
	Type ORMTable (ResultSet As ResultSet, RowCount As Int, Results As List, Row As Map, First As Map)
	Type ORMColumn (ColumnName As String, ColumnType As String, ColumnLength As String, DefaultValue As String, Nullable As Boolean, AutoIncrement As Boolean)
	Type ORMFilter (Column As String, Operator As String, Value As String)
	Type ORMJoin (Table2 As String, OnConditions As String, Mode As String)
	Type ORMResult (Tag As Object, Columns As Map, Rows As List)
End Sub

Public Sub Initialize (mSQL As SQL)
	SQL = mSQL
	DateTimeMethods = CreateMap(91: "getDate", 92: "getTime", 93: "getTimestamp")
End Sub

Public Sub Close
	SQL.Close
End Sub

Public Sub setEngine (mEngine As String)
	DBEngine = mEngine
	Select DBEngine
		Case "MySQL"
			INTEGER = "int"
			DECIMAL = "decimal"
			VARCHAR = "varchar"
		Case "SQLite"
			INTEGER = "INTEGER"
			DECIMAL = "NUMERIC"
			VARCHAR = "TEXT"
	End Select
End Sub

Public Sub getEngine As String
	Return DBEngine
End Sub

Public Sub setTable (mTable As String)
	DBTable = mTable
	Reset
End Sub

Public Sub getTable As String
	Return DBTable
End Sub

Public Sub setColumns (mColumns As List)
	DBColumns = mColumns
End Sub

Public Sub getColumns As List
	Return DBColumns
End Sub

Public Sub setUpdateModifiedDate (Value As Boolean)
	BlnUpdateModifiedDate = Value
End Sub

Public Sub setUseTimestamps (Value As Boolean)
	BlnUseTimestamps = Value
End Sub

Public Sub setUseTimestampsWithUserId (Value As Boolean)
	BlnUseTimestampsWithUserId = Value
End Sub

Public Sub setAddAfterCreate (Value As Boolean)
	BlnAddAfterCreate = Value
End Sub

Public Sub setAddAfterInsert (Value As Boolean)
	BlnAddAfterInsert = Value
End Sub

Public Sub Reset
	DBStatement = $"SELECT * FROM ${DBTable}"$
	Condition = ""
	DBPrimaryKey = ""
	DBForeignKey = ""
	DBColumns.Initialize
	DBParameters.Initialize
	BlnUseTimestamps = False
	BlnUseTimestampsWithUserId = False
	BlnUpdateModifiedDate = False
End Sub

Public Sub First As Map
	Return ORMTable.First
End Sub

Public Sub Find (id As Int) As Map
	Reset
	setWhere(Array($"id = ${id}"$))
	Query
	If ORMTable.Row.IsInitialized Then
		Return ORMTable.Row
	Else
		Return CreateMap()
	End If
End Sub

' Returns number of rows in the result
Public Sub getRowCount As Int
	Return ORMTable.RowCount
End Sub

Public Sub setSelect (Columns As List)
	Dim AC As Boolean ' Add Comma
	Dim SB As StringBuilder
	SB.Initialize
	For Each Col In Columns
		If AC Then SB.Append(",")
		SB.Append(" " & Col)
		AC = True
	Next
	DBStatement = DBStatement.Replace($"SELECT * FROM"$, "SELECT" & SB.ToString & " FROM")
End Sub

Public Sub setRawSQL (RawSQLQuery As String)
	DBStatement = RawSQLQuery
End Sub

Public Sub Results As List
	Return ORMTable.Results
End Sub

Public Sub setGroupBy (Col As Map)
	If Col.IsInitialized Then
		Dim sb As StringBuilder
		sb.Initialize
		For Each k As String In Col.Keys
			If sb.Length > 0 Then sb.Append(", ")
			sb.Append(k)
		Next
		DBGroupBy = $" GROUP BY ${sb.ToString}"$
	End If
End Sub

Public Sub setOrderBy (Col As Map)
	If Col.IsInitialized Then
		Dim sb As StringBuilder
		sb.Initialize
		For Each k As String In Col.Keys
			If sb.Length > 0 Then sb.Append(", ")
			If Col.Get(k).As(String).EqualsIgnoreCase("DESC") Then
				sb.Append(k & " " & Col.Get(k))
			Else
				sb.Append(k)
			End If
		Next
		DBOrderBy = $" ORDER BY ${sb.ToString}"$
	End If
End Sub

Public Sub Create
	Dim sb As StringBuilder
	sb.Initialize
	For Each col As ORMColumn In DBColumns
		If sb.Length > 0 Then sb.Append(",").Append(CRLF)
		sb.Append(col.ColumnName)
		sb.Append(" ")
		If DBEngine.EqualsIgnoreCase("MySQL") Then
			Select col.ColumnType
				Case INTEGER
					sb.Append(INTEGER)
				Case DECIMAL
					sb.Append(DECIMAL)
				Case VARCHAR
					sb.Append(VARCHAR)
				Case Else
					sb.Append(VARCHAR)
			End Select
			If col.ColumnLength.Length > 0 Then 
				sb.Append("(").Append(col.ColumnLength).Append(")")
			End If
		End If
		If DBEngine.EqualsIgnoreCase("SQLite") Then
			sb.Append(col.ColumnType)
		End If
		
		If Not(col.Nullable) Then sb.Append(" NOT NULL")
		If col.ColumnType = INTEGER Then
			If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append(col.DefaultValue)			
		Else If col.ColumnType = DECIMAL Then
			If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append("'").Append(col.DefaultValue).Append("'")
		Else ' VARCHAR
			If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append(QUOTE).Append(col.DefaultValue).Append(QUOTE)
		End If
	Next
	
	' Add Created_Date and Modified_Date columns by default if set to True
	'If BlnUseTimestamps Then
	'	sb.Append(",").Append(CRLF)
	'	sb.Append("created_date INTEGER DEFAULT (strftime('%s000', 'now', 'localtime')),").Append(CRLF) ' SQLite
	'	sb.Append("modified_date INTEGER,").Append(CRLF)
	'	sb.Append("deleted_date INTEGER,")
	'End If
	
	Select DBEngine
		Case "MySQL"
			If BlnUseTimestamps Then
				sb.Append(",").Append(CRLF)
				If BlnUseTimestampsWithUserId Then
					sb.Append("created_by int(11) DEFAULT 1,").Append(CRLF)
					sb.Append("modified_by int(11),").Append(CRLF)
					sb.Append("deleted_by int(11),").Append(CRLF)
				End If
				sb.Append("created_date timestamp DEFAULT CURRENT_TIMESTAMP,").Append(CRLF)
				sb.Append("modified_date datetime DEFAULT NULL,").Append(CRLF)
				sb.Append("deleted_date datetime DEFAULT NULL,")
			Else
				sb.Append(",").Append(CRLF)
			End If
		Case "SQLite"
			If BlnUseTimestamps Then
				sb.Append(",").Append(CRLF)
				If BlnUseTimestampsWithUserId Then
					sb.Append("created_by INTEGER DEFAULT 1,").Append(CRLF)
					sb.Append("modified_by INTEGER,").Append(CRLF)
					sb.Append("deleted_by INTEGER,").Append(CRLF)
				End If
				sb.Append("created_date TEXT DEFAULT (datetime('now', 'localtime')),").Append(CRLF)
				sb.Append("modified_date TEXT,").Append(CRLF)
				sb.Append("deleted_date TEXT,")
			Else
				sb.Append(",").Append(CRLF)
			End If
	End Select

	Dim cmd As StringBuilder
	cmd.Initialize
	cmd.Append($"CREATE TABLE ${DBTable} ("$)
	' id created by mandatory
	If DBEngine.EqualsIgnoreCase("MySQL") Then
		'If DBPrimaryKey.Length > 0 Then
		'	cmd.Append($"id INT(11) NOT NULL,"$).Append(CRLF)
		'Else
		cmd.Append($"id INT(11) NOT NULL AUTO_INCREMENT,"$).Append(CRLF)
		'End If
	End If
	If DBEngine.EqualsIgnoreCase("SQLite") Then
		cmd.Append($"id INTEGER,"$).Append(CRLF)
	End If
	cmd.Append(sb.ToString)
	' Pimary key id created by default
	cmd.Append(CRLF)
	If DBPrimaryKey.Length > 0 Then
		cmd.Append(DBPrimaryKey)
	Else
		If DBEngine.EqualsIgnoreCase("MySQL") Then
			cmd.Append($"PRIMARY KEY(id)"$)
		End If
		If DBEngine.EqualsIgnoreCase("SQLite") Then
			cmd.Append($"PRIMARY KEY(id AUTOINCREMENT)"$)
		End If
	End If
	If DBForeignKey.Length > 0 Then
		cmd.Append(",")
		cmd.Append(CRLF)
		cmd.Append(DBForeignKey)
	End If
	cmd.Append(")")
	DBStatement = cmd.ToString
	If BlnAddAfterCreate Then AddQuery 'AddQuery2
End Sub

' Replace default primary key
Public Sub Primary (mKeys() As String)
	If mKeys.Length < 1 Then Return
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("PRIMARY KEY").Append(" (")
	For i = 0 To mKeys.Length - 1
		If i > 0 Then sb.Append(", ")
		sb.Append(mKeys(i))
	Next
	sb.Append(")")
	DBPrimaryKey = sb.ToString
End Sub

' Insert new foreign keys
Public Sub Foreign (mKey As String, mReferences As String, mOnTable As String, mOnDelete As String, mOnUpdate As String)
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append( $"FOREIGN KEY (${mKey}) REFERENCES ${mOnTable} (${mReferences})"$ )
	If mOnDelete.Length > 0 Then sb.Append( " ON DELETE " & mOnDelete )
	If mOnUpdate.Length > 0 Then sb.Append( " ON UPDATE " & mOnUpdate )
	DBForeignKey = sb.ToString
End Sub

Public Sub Execute
	SQL.ExecNonQuery(DBStatement)
End Sub

Public Sub ExecuteBatch As ResumableSub
	Dim SenderFilter As Object = SQL.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	Return Success
End Sub

Public Sub AddQuery
	'LogColor(DBStatement & " " & DBParameters, COLOR_MAGENTA)
	Dim Param As Object = CopyObject(DBParameters)
	SQL.AddNonQueryToBatch(DBStatement, Param)
	'SQL.AddNonQueryToBatch(DBStatement, DBParameters) ' Bugs fixed
End Sub

Public Sub AddQuery2
	'LogColor(DBStatement, COLOR_BLUE)
	SQL.AddNonQueryToBatch(DBStatement, Null)
End Sub

' Make a copy of an object
Public Sub CopyObject (obj As Object) As Object
	Dim ser As B4XSerializator
	Return ser.ConvertBytesToObject(ser.ConvertObjectToBytes(obj))
End Sub

Public Sub setParameters (Params As List)
	DBParameters = Params
End Sub

Public Sub setLimit (Value As String)
	DBLimit = Value
End Sub

Public Sub setJoin (OJoin As ORMJoin)
	Dim JOIN As String = " JOIN "
	If OJoin.Mode <> "" Then JOIN = " " & OJoin.Mode & " "
	Append(JOIN & OJoin.Table2 & " ON " & OJoin.OnConditions)
End Sub

Public Sub Query
	Try
		If Condition.Length > 0 Then DBStatement = DBStatement & Condition
		If DBGroupBy.Length > 0 Then DBStatement = DBStatement & DBGroupBy
		If DBOrderBy.Length > 0 Then DBStatement = DBStatement & DBOrderBy
		If DBLimit.Length > 0 Then DBStatement = DBStatement & $" LIMIT ${DBLimit}"$ ' Limit 10, 10 <-- second parameter is OFFSET
		
		'Log(DBStatement)
		'Log(DBParameters)
		
		If DBParameters.IsInitialized Then
			If DBParameters.Size > 0 Then
				Dim RS As ResultSet = SQL.ExecQuery2(DBStatement, DBParameters)
			Else
				Dim RS As ResultSet = SQL.ExecQuery(DBStatement)
			End If
		Else
			Dim RS As ResultSet = SQL.ExecQuery(DBStatement)
		End If

		ORMTable.Initialize
		ORMTable.Results.Initialize
		ORMTable.ResultSet = RS
		Dim jrs As JavaObject = RS
		Dim rsmd As JavaObject = jrs.RunMethod("getMetaData", Null)
		Dim cols As Int = RS.ColumnCount
      
		Dim res As ORMResult
		res.Initialize
		res.Columns.Initialize
		res.Rows.Initialize
		res.Tag = Null 'without this the Tag properly will not be serializable.
      
		For i = 0 To cols - 1
			res.Columns.Put(RS.GetColumnName(i), i)
		Next
      
		BlnFirst = True
		Do While RS.NextRow ' And limit > 0
			Dim row(cols) As Object
			Dim map1 As Map
			map1.Initialize
			For i = 0 To cols - 1
				Dim ct As Int = rsmd.RunMethod("getColumnType", Array(i + 1))
				'check whether it is a blob field
				If ct = -2 Or ct = 2004 Or ct = -3 Or ct = -4 Then
					row(i) = RS.GetBlob2(i)
				Else if ct = 2 Or ct = 3 Then
					row(i) = RS.GetDouble2(i)
				Else If DateTimeMethods.ContainsKey(ct) Then
					Dim SQLTime As JavaObject = jrs.RunMethodJO(DateTimeMethods.Get(ct), Array(i + 1))
					If SQLTime.IsInitialized Then
						row(i) = SQLTime.RunMethod("getTime", Null)
					Else
						row(i) = Null
					End If
				Else
					row(i) = jrs.RunMethod("getObject", Array(i + 1))
				End If
				map1.Put(RS.GetColumnName(i), row(i))
			Next
			res.Rows.Add(row)
			ORMTable.RowCount = res.Rows.Size
          
			ORMTable.Row = map1
			ORMTable.Results.Add(map1)
			If BlnFirst Then
				ORMTable.First = map1 ' row
				BlnFirst = False
			End If
		Loop
		ORMResult = res
	Catch
		Log(LastException)
	End Try
	'ORMResult = res
	Condition = ""
	DBParameters.Initialize
End Sub

Public Sub getScalar As Object
	If Condition.Length > 0 Then DBStatement = DBStatement & Condition
	If DBParameters.Size > 0 Then
		Return SQL.ExecQuerySingleResult2(DBStatement, DBParameters)
	Else
		Return SQL.ExecQuerySingleResult(DBStatement)
	End If
End Sub

Public Sub Insert
	Dim sb As StringBuilder
	Dim vb As StringBuilder
	sb.Initialize
	vb.Initialize
	For Each col As String In DBColumns
		If sb.Length > 0 Then
			sb.Append(", ")
			vb.Append(", ")
		End If
		sb.Append(col)
		vb.Append("?")
	Next
	Dim cmd As String = $"INSERT INTO ${DBTable} (${sb.ToString}) VALUES (${vb.ToString})"$
	DBStatement = cmd
	If BlnAddAfterInsert Then AddQuery
End Sub

Public Sub Save
	Dim BlnNew As Boolean
	If Condition.Length > 0 Then
		Dim sb As StringBuilder
		sb.Initialize
		Dim cmd As String = $"UPDATE ${DBTable} SET "$
		For Each col As String In DBColumns
			If sb.Length > 0 Then sb.Append(", ")
			sb.Append(col & " = ?")
		Next
		cmd = cmd & sb.ToString
		If BlnUpdateModifiedDate Then
			cmd = cmd & ", modified_date = DateTime('now', 'localtime')"
		End If
		cmd = cmd & Condition
		Condition = ""
	Else
		Dim sb, vb As StringBuilder
		sb.Initialize
		vb.Initialize
		For Each col As String In DBColumns
			If sb.Length > 0 Then
				sb.Append(", ")
				vb.Append(", ")
			End If
			sb.Append(col)
			vb.Append("?")
		Next
		Dim cmd As String = $"INSERT INTO ${DBTable} (${sb.ToString}) SELECT ${vb.ToString}"$
		BlnNew = True
	End If
	DBStatement = cmd
	If DBParameters.Size > 0 Then
		SQL.ExecNonQuery2(cmd, DBParameters)
	Else
		SQL.ExecNonQuery(cmd)
	End If
	' Return new row
	If BlnNew Then
		DBStatement = $"SELECT * FROM ${DBTable}"$
		setWhere(Array("id = ?"))
		setParameters(Array(getLastInsertID))
		Query
		DBParameters.Clear
	End If
End Sub

Public Sub getLastInsertID As Object
	Select DBEngine.ToUpperCase
		Case "MYSQL"
			Dim cmd As String = "SELECT LAST_INSERT_ID()"
		Case "SQLITE"
			Dim cmd As String = "SELECT LAST_INSERT_ROWID()"
		Case Else ' "SQLITE"
			Dim cmd As String = "SELECT LAST_INSERT_ROWID()"
	End Select
	Return SQL.ExecQuerySingleResult(cmd)
End Sub

Public Sub setWhere (mStatements As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each statement In mStatements
		If sb.Length > 0 Then sb.Append(" AND ") Else sb.Append(" WHERE ")
		sb.Append(statement)
	Next
	Condition = Condition & sb.ToString
End Sub

Public Sub Append (strSQL As String) As String
	DBStatement = DBStatement & strSQL
	Return DBStatement
End Sub

Public Sub ToString As String
	Return DBStatement
End Sub

Public Sub Delete
	Dim cmd As String = $"DELETE FROM ${DBTable}"$
	If Condition.Length > 0 Then cmd = cmd & Condition
	If DBParameters.Size > 0 Then
		SQL.ExecNonQuery2(cmd, DBParameters)
	Else
		SQL.ExecNonQuery(cmd)
	End If
	Condition = ""
End Sub

Public Sub Destroy (ids() As Int)
	If ids.Length < 1 Then Return
	Dim cmd As String
	For i = 0 To ids.Length - 1
		cmd = $"DELETE FROM ${DBTable} WHERE id = ?"$
		SQL.AddNonQueryToBatch(cmd, Array(ids(i)))
	Next
	Dim SenderFilter As Object = SQL.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	Log("NonQuery: " & Success)
End Sub

Public Sub SoftDelete
	Dim cmd As String = $"UPDATE ${DBTable} SET deleted_date = strftime('%s000', 'now', 'localtime')"$
	If Condition.Length > 0 Then cmd = cmd & Condition
	SQL.ExecNonQuery(cmd)
End Sub

'Tests whether the given table exists (extracted from DBUtils)
Public Sub TableExists (TableName As String) As Boolean
	Dim cmd As String = $"SELECT count(name) FROM sqlite_master WHERE type = 'table' AND name = ? COLLATE NOCASE"$
	Dim count As Int = SQL.ExecQuerySingleResult2(cmd, Array As String(TableName))
	Return count > 0
End Sub

Public Sub CreateORMColumn2 (Props As Map) As ORMColumn
	Dim t1 As ORMColumn
	t1.Initialize
	t1.ColumnName = ""
	If DBEngine.EqualsIgnoreCase("MySQL") Then
		t1.ColumnType = "varchar"
	End If
	If DBEngine.EqualsIgnoreCase("SQLite") Then
		t1.ColumnType = VARCHAR
	End If
	
	t1.ColumnLength = 255
	t1.DefaultValue = ""
	t1.Nullable = True
	t1.AutoIncrement = False
	
	For Each Key As String In Props.Keys
		Select Key.ToLowerCase
			Case "ColumnName".ToLowerCase, "Name".ToLowerCase
				t1.ColumnName = Props.Get(Key)
			Case "ColumnType".ToLowerCase, "Type".ToLowerCase
				t1.ColumnType = Props.Get(Key)
			Case "ColumnLength".ToLowerCase, "ColumnSize".ToLowerCase, "Length".ToLowerCase, "Size".ToLowerCase
				t1.ColumnLength = Props.Get(Key)
			Case "DefaultValue".ToLowerCase, "Default".ToLowerCase
				t1.DefaultValue = Props.Get(Key)
			Case "Nullable".ToLowerCase, "Null".ToLowerCase
				t1.Nullable = Props.Get(Key)
			Case "AutoIncrement".ToLowerCase
				t1.AutoIncrement = Props.Get(Key)
			Case Else
				t1.ColumnName = Key
		End Select
	Next
	Return t1
End Sub

Public Sub CreateORMColumn (ColumnName As String, ColumnType As String, ColumnLength As String, DefaultValue As String, Nullable As Boolean, AutoIncrement As Boolean) As ORMColumn
	Dim t1 As ORMColumn
	t1.Initialize
	t1.ColumnName = ColumnName
	t1.ColumnType = ColumnType
	t1.ColumnLength = ColumnLength
	t1.DefaultValue = DefaultValue
	t1.Nullable = Nullable
	t1.AutoIncrement = AutoIncrement
	Return t1
End Sub

Public Sub CreateORMFilter (Column As String, Operator As String, Value As String) As ORMFilter
	Dim t1 As ORMFilter
	t1.Initialize
	t1.Column = Column
	t1.Operator = Operator
	t1.Value = Value
	Return t1
End Sub

Public Sub CreateORMJoin (Table2 As String, OnConditions As String, Mode As String) As ORMJoin
	Dim t1 As ORMJoin
	t1.Initialize
	t1.Table2 = Table2
	t1.OnConditions = OnConditions
	t1.Mode = Mode
	Return t1
End Sub