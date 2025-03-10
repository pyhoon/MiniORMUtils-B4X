B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=9.71
@EndOfDesignText@
' Mini Object-Relational Mapper (ORM) class
' Version 2.21
Sub Class_Globals
	Private DBSQL 					As SQL
	Private DBEngine 				As String
	Private DBID 					As Int
	Private DBColumns 				As List
	Private DBTable 				As String
	Private DBStatement 			As String
	Private DBPrimaryKey 			As String
	Private DBUniqueKey 			As String
	Private DBForeignKey 			As String
	Private DBConstraint 			As String
	Private DBGroupBy 				As String
	Private DBOrderBy 				As String
	Private DBLimit 				As String
	Private DBCondition 			As String
	Private DBHaving 				As String
	#If B4A or B4i
	Private DBParameters() 			As String
	#Else
	Private DBParameters 			As List
	Private BlnFirst 				As Boolean
	Private BlnUseTimestampsAsTicks As Boolean
	#End If
	Private BlnShowExtraLogs 		As Boolean
	Private BlnUseTimestamps 		As Boolean
	Private BlnAutoIncrement 		As Boolean
	Private BlnUseDataAuditUserId 	As Boolean
	Private BlnUpdateModifiedDate 	As Boolean
	Private BlnQueryAddToBatch 		As Boolean
	Private BlnQueryExecute 		As Boolean
	Private StrDefaultUserId 		As String = "1"
	#If B4J
	Private DateTimeMethods 		As Map = CreateMap(91: "getDate", 92: "getTime", 93: "getTimestamp")
	#End If
	Public INTEGER 					As String
	Public BIG_INT 					As String
	Public DECIMAL 					As String
	Public VARCHAR 					As String
	Public DATE_TIME 				As String ' datetime
	Public TIMESTAMP 				As String
	Public TEXT 					As String
	Public ORMTable 				As ORMTable
	Public ORMResult 				As ORMResult
	Public Const MYSQL 				As String = "MYSQL"
	Public Const SQLITE 			As String = "SQLITE"
	Private Const COLOR_RED 		As Int = -65536			'ignore
	Private Const COLOR_GREEN 		As Int = -16711936	'ignore
	Private Const COLOR_BLUE 		As Int = -16776961		'ignore
	Private Const COLOR_MAGENTA 	As Int = -65281		'ignore
	Type ORMResult (Tag As Object, Columns As Map, Rows As List)
	Type ORMFilter (Column As String, Operator As String, Value As String)
	Type ORMJoin (Table2 As String, OnConditions As String, Mode As String)
	Type ORMTable (ResultSet As ResultSet, RowCount As Int, Results As List, Row As Map, First As Map, Last As Map)
	Type ORMColumn (ColumnName As String, ColumnType As String, ColumnLength As String, Collation As String, DefaultValue As String, AllowNull As Boolean, Unique As Boolean, AutoIncrement As Boolean) ' B4i dislike word Nullable
End Sub

Public Sub Initialize (mSQL As SQL, mEngine As String)
	setSQL(mSQL)
	setEngine(mEngine)
	BlnAutoIncrement = True
End Sub

' Set DB Type
Public Sub setEngine (mEngine As String)
	DBEngine = mEngine.ToUpperCase
	Select DBEngine
		Case MYSQL
			INTEGER = "int"
			BIG_INT = "bigint"
			DECIMAL = "decimal"
			VARCHAR = "varchar"
			TEXT = "text"
			DATE_TIME = "datetime"
			TIMESTAMP = "timestamp"
		Case SQLITE
			INTEGER = "INTEGER"
			BIG_INT = "INTEGER"
			DECIMAL = "NUMERIC"
			VARCHAR = "TEXT"
			TEXT = "TEXT"
			DATE_TIME = "TEXT"
			TIMESTAMP = "TEXT"
	End Select
End Sub

' Return DB Type
Public Sub getEngine As String
	Return DBEngine
End Sub

Public Sub setSQL (mSQL As SQL)
	DBSQL = mSQL
End Sub

Public Sub getSQL As SQL
	Return DBSQL
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

Public Sub setShowExtraLogs (Value As Boolean)
	BlnShowExtraLogs = Value
End Sub

Public Sub setUpdateModifiedDate (Value As Boolean)
	BlnUpdateModifiedDate = Value
End Sub

Public Sub setUseTimestamps (Value As Boolean)
	BlnUseTimestamps = Value
End Sub

Public Sub getUseTimestamps As Boolean
	Return BlnUseTimestamps
End Sub

#If B4J
Public Sub setUseTimestampsAsTicks (Value As Boolean)
	BlnUseTimestampsAsTicks = Value
End Sub
#End If

Public Sub setUseDataAuditUserId (Value As Boolean)
	BlnUseDataAuditUserId = Value
End Sub

Public Sub setDefaultUserId (Value As String)
	StrDefaultUserId = Value
End Sub

Public Sub setQueryAddToBatch (Value As Boolean)
	BlnQueryAddToBatch = Value
End Sub

Public Sub setQueryExecute (Value As Boolean)
	BlnQueryExecute = Value
End Sub

Public Sub setAutoIncrement (Value As Boolean)
	BlnAutoIncrement = Value
End Sub

Public Sub Close
	#If WAL
	If DBEngine = SQLITE Then
		Return
	End If
	#End If
	If DBSQL <> Null And DBSQL.IsInitialized Then DBSQL.Close
End Sub

Public Sub Reset
	DBStatement = $"SELECT * FROM ${DBTable}"$
	DBHaving = ""
	DBOrderBy = ""
	DBCondition = ""
	DBUniqueKey = ""
	DBPrimaryKey = ""
	DBForeignKey = ""
	DBConstraint = ""
	DBColumns.Initialize
	#If B4A or B4i
	Dim DBParameters() As String
	#Else
	DBParameters.Initialize
	#End If
End Sub

Public Sub Results As List
	Return ORMTable.Results
End Sub

' Query column id
Public Sub Find (mID As Int)
	Reset
	WhereParam("id = ?", mID)
	Query
End Sub

' Query by single condition
Public Sub Find2 (mCondition As String, mValue As Object)
	Reset
	WhereParam(mCondition, mValue)
	Query
End Sub

Public Sub setId (mID As Int)
	DBID = mID
	WhereParam("id = ?", mID)
End Sub

Public Sub getId As Int
	Return DBID
End Sub

' Returns first queried row
Public Sub getFirst As Map
	If ORMTable.IsInitialized And ORMTable.First.IsInitialized Then
		Return ORMTable.First
	End If
	Return CreateMap("id": 0)
End Sub

' Returns new inserted row
Public Sub getLast As Map
	Return ORMTable.Last
End Sub

Public Sub getFirstId As Int
	Return getFirst.Get("id")
End Sub

' Returns number of rows in ORMTable
Public Sub getRowCount As Int
	Return ORMTable.RowCount
End Sub

' Returns True if ORMTable.RowCount > 0
Public Sub getFound As Boolean
	Return ORMTable.RowCount > 0
End Sub

' Start SELECT query
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

' Return map of only selected columns from a row
' Useful for filtering new row
Public Sub SelectOnly (Columns As List) As Map
	Dim NewMap As Map
	NewMap.Initialize
	If ORMTable.IsInitialized And ORMTable.First.IsInitialized Then
		For Each Col In Columns
			If ORMTable.First.ContainsKey(Col) Then
				NewMap.Put(Col, ORMTable.First.Get(Col))
			End If
		Next
	End If
	Return NewMap
End Sub

Public Sub setGroupBy (Columns As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each Column As String In Columns
		If sb.Length > 0 Then sb.Append(", ") Else sb.Append(" GROUP BY ")
		sb.Append(Column)
	Next
	DBGroupBy = sb.ToString
End Sub

Public Sub setHaving (mStatements As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each statement In mStatements
		If sb.Length > 0 Then sb.Append(" AND ") Else sb.Append(" HAVING ")
		sb.Append(statement)
	Next
	DBHaving = sb.ToString
End Sub

Public Sub setOrderBy (Col As Map)
	If Col.IsInitialized Then
		Dim sb As StringBuilder
		sb.Initialize
		For Each key As String In Col.Keys
			If sb.Length > 0 Then sb.Append(", ")
			Dim value As String = Col.Get(key)
			If value.EqualsIgnoreCase("DESC") Then
				sb.Append(key & " " & value)
			Else
				sb.Append(key)
			End If
		Next
		DBOrderBy = $" ORDER BY ${sb.ToString}"$
	End If
End Sub

Public Sub SortByLastId
	DBOrderBy = $" ORDER BY id DESC"$
End Sub

Public Sub Create
	Dim sb As StringBuilder
	sb.Initialize
	For Each col As ORMColumn In DBColumns
		sb.Append(col.ColumnName)
		sb.Append(" ")
		Select DBEngine
			Case MYSQL
				Select col.ColumnType
					Case INTEGER, BIG_INT, DECIMAL, TIMESTAMP, DATE_TIME, TEXT
						sb.Append(col.ColumnType)
					Case Else
						sb.Append(VARCHAR)
				End Select
				If col.ColumnLength.Length > 0 Then
					sb.Append("(").Append(col.ColumnLength).Append(")")
				End If
				If col.Collation.Length > 0 Then
					sb.Append(" ").Append(col.Collation)
				End If
			Case SQLITE
				sb.Append(col.ColumnType)
		End Select

		Select col.ColumnType
			Case INTEGER, BIG_INT, TIMESTAMP, DATE_TIME
				If DBEngine = SQLITE And col.ColumnType.EqualsIgnoreCase("TEXT") Then
					If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append("'").Append(col.DefaultValue).Append("'")
				Else
					If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append(col.DefaultValue)
				End If
			Case Else
				If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append("'").Append(col.DefaultValue).Append("'")
		End Select
		If col.AllowNull Then sb.Append(" NULL") Else sb.Append(" NOT NULL")
		If col.Unique Then sb.Append(" UNIQUE")
		If col.AutoIncrement Then
			Select DBEngine
				Case MYSQL
					sb.Append(" AUTO_INCREMENT")
				Case SQLITE
					sb.Append(" AUTOINCREMENT")
			End Select
		End If
		sb.Append(",").Append(CRLF)
	Next
	
	Select DBEngine
		Case MYSQL
			If BlnUseDataAuditUserId Then
				sb.Append("created_by " & INTEGER & " DEFAULT " & StrDefaultUserId & ",").Append(CRLF)
				sb.Append("modified_by " & INTEGER & ",").Append(CRLF)
				sb.Append("deleted_by " & INTEGER & ",").Append(CRLF)
			End If
			If BlnUseTimestamps Then
				' Use timestamp and datetime
				sb.Append("created_date " & TIMESTAMP & " DEFAULT CURRENT_TIMESTAMP,").Append(CRLF)
				sb.Append("modified_date " & DATE_TIME & " DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,").Append(CRLF)
				sb.Append("deleted_date " & DATE_TIME & " DEFAULT NULL,")
			End If
		Case SQLITE
			If BlnUseDataAuditUserId Then
				sb.Append("created_by " & INTEGER & " DEFAULT " & StrDefaultUserId & ",").Append(CRLF)
				sb.Append("modified_by " & INTEGER & ",").Append(CRLF)
				sb.Append("deleted_by " & INTEGER & ",").Append(CRLF)
			End If
			If BlnUseTimestamps Then
				sb.Append("created_date " & VARCHAR & " DEFAULT (datetime('now')),").Append(CRLF)
				sb.Append("modified_date " & VARCHAR & ",").Append(CRLF)
				sb.Append("deleted_date " & VARCHAR & ",")
			End If
	End Select

	Dim stmt As StringBuilder
	stmt.Initialize
	stmt.Append($"CREATE TABLE ${DBTable} ("$)
	
	' id column added by default
	If BlnAutoIncrement Then
		Select DBEngine
			Case MYSQL
				stmt.Append($"id ${INTEGER} NOT NULL AUTO_INCREMENT,"$).Append(CRLF)
			Case SQLITE
				stmt.Append($"id ${INTEGER},"$).Append(CRLF)
		End Select
	End If

	' Put the columns here
	stmt.Append(sb.ToString)
	
	If DBPrimaryKey.Length > 0 Then
		stmt.Append(CRLF)
		stmt.Append($"PRIMARY KEY(${DBPrimaryKey})"$)
	Else
		' id column set as primary key by default
		If BlnAutoIncrement Then
			stmt.Append(CRLF)
			Select DBEngine
				Case MYSQL
					stmt.Append($"PRIMARY KEY(id)"$)
				Case SQLITE
					stmt.Append($"PRIMARY KEY(id AUTOINCREMENT)"$)
			End Select
		Else
			stmt.Remove(stmt.Length - 1, stmt.Length) ' remove the last comma
		End If
	End If
	
	If DBUniqueKey.Length > 0 Then
		stmt.Append(",")
		stmt.Append(CRLF)
		stmt.Append(DBUniqueKey)
	End If
	
	If DBForeignKey.Length > 0 Then
		stmt.Append(",")
		stmt.Append(CRLF)
		stmt.Append(DBForeignKey)
	End If
	
	If DBConstraint.Length > 0 Then
		stmt.Append(",")
		stmt.Append(CRLF)
		stmt.Append(DBConstraint)
	End If
	
	stmt.Append(")")
	DBStatement = stmt.ToString
	If BlnQueryAddToBatch Then AddNonQueryToBatch
	If BlnQueryExecute Then Execute
End Sub

Public Sub Create2 (CreateStatement As String)
	DBStatement = CreateStatement
	#If B4J
	DBParameters.Clear
	#Else
	Dim DBParameters() As String
	#End If
	If BlnQueryAddToBatch Then AddNonQueryToBatch
	If BlnQueryExecute Then Execute
End Sub

' Replace default primary key
Public Sub Primary (mKeys() As String)
	If mKeys.Length = 0 Then Return
	Dim keys As StringBuilder
	keys.Initialize
	For i = 0 To mKeys.Length - 1
		If i > 0 Then keys.Append(", ")
		keys.Append(mKeys(i))
	Next
	DBPrimaryKey = keys.ToString
End Sub

' Add foreign key
Public Sub Foreign (mKey As String, mReferences As String, mOnTable As String, mOnDelete As String, mOnUpdate As String)
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append( $"FOREIGN KEY (${mKey}) REFERENCES ${mOnTable} (${mReferences})"$ )
	If mOnDelete.Length > 0 Then sb.Append( " ON DELETE " & mOnDelete )
	If mOnUpdate.Length > 0 Then sb.Append( " ON UPDATE " & mOnUpdate )
	DBForeignKey = sb.ToString
End Sub

' Add unique key
' mKey: Column name
' Optional: mAlias
Public Sub Unique (mKey As String, mAlias As String)
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("UNIQUE KEY")
	If mAlias.Length > 0 Then sb.Append(" " & mAlias)
	sb.Append($" (${mKey})"$)
	DBUniqueKey = sb.ToString
End Sub

' Add constraint
' mType: UNIQUE or PRIMARY KEY
' mKeys: Column names separated by comma
' Optional: mAlias
Public Sub Constraint (mType As String, mKeys As String, mAlias As String)
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("CONSTRAINT")
	If mAlias.Length > 0 Then sb.Append(" " & mAlias)
	sb.Append(" " & mType)
	sb.Append($"(${mKeys})"$)
	DBConstraint = sb.ToString
End Sub

Public Sub Execute
	Try
		' 2024-04-09 fix missing args
		Dim paramsize As Int = ParametersCount
		If paramsize > 0 Then
			Dim Args(paramsize) As Object
			Dim i As Int
			For Each Param In DBParameters
				Args(i) = Param
				i = i + 1
			Next
			If BlnShowExtraLogs Then LogQuery2
			DBSQL.ExecNonQuery2(DBStatement, Args)
		Else
			If BlnShowExtraLogs Then LogQuery
			DBSQL.ExecNonQuery(DBStatement)
		End If
	Catch
		Log(LastException)
	End Try
End Sub

'<code>
'Wait For (DB.ExecuteBatch) Complete (Success As Boolean)
'If Success Then
'    Log("success")
'Else
'    Log("error")
'End If</code>
Public Sub ExecuteBatch As ResumableSub
	Dim SenderFilter As Object = DBSQL.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	Return Success
End Sub

Public Sub AddNonQueryToBatch
	'LogColor(DBStatement & " " & DBParameters, COLOR_MAGENTA)
	Dim paramsize As Int = ParametersCount
	Dim Args(paramsize) As Object
	Dim i As Int
	For Each Param In DBParameters
		Args(i) = Param
		i = i + 1
	Next
	DBSQL.AddNonQueryToBatch(DBStatement, Args)
End Sub

#If B4A or B4i
Public Sub AddParameters (Params() As String)
	'DBParameters = Merge(DBParameters, Params)
	If Params.Length = 0 Then Return
	If DBParameters.Length > 0 Then
		Dim NewArray(DBParameters.Length + Params.Length) As String
		For i = 0 To DBParameters.Length - 1
			NewArray(i) = DBParameters(i)
		Next
		For i = 0 To Params.Length - 1
			NewArray(DBParameters.Length + i) = Params(i)
		Next
		DBParameters = NewArray
	Else
		DBParameters = Params
	End If
End Sub
#Else
Public Sub AddParameters (Params As List)
	DBParameters.AddAll(Params)
End Sub
#End If

#If B4A or B4i
Public Sub setParameters (Params() As String)
	DBParameters = Params
End Sub
#Else
Public Sub setParameters (Params As List)
	DBParameters.Initialize
	DBParameters.AddAll(Params)
End Sub
#End If

' Example: Limit 10, 10 (second parameter is Offset)
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
		ORMTable.Initialize
		ORMTable.First.Initialize
		ORMTable.Results.Initialize
		
		If DBCondition.Length > 0 Then DBStatement = DBStatement & DBCondition
		If DBGroupBy.Length > 0 Then DBStatement = DBStatement & DBGroupBy
		If DBHaving.Length > 0 Then DBStatement = DBStatement & DBHaving
		If DBOrderBy.Length > 0 Then DBStatement = DBStatement & DBOrderBy
		If DBLimit.Length > 0 Then DBStatement = DBStatement & $" LIMIT ${DBLimit}"$ ' Limit 10, 10 <-- second parameter is OFFSET
		Dim paramsize As Int = ParametersCount
		If paramsize > 0 Then
			If BlnShowExtraLogs Then LogQuery2
			Dim RS As ResultSet = DBSQL.ExecQuery2(DBStatement, DBParameters)
		Else
			If BlnShowExtraLogs Then LogQuery
			Dim RS As ResultSet = DBSQL.ExecQuery(DBStatement)
		End If

		'ORMTable.Initialize
		'ORMTable.First.Initialize
		'ORMTable.Results.Initialize
		ORMTable.ResultSet = RS

		#If B4A or B4i
		Dim Columns As Map = DBUtils.ExecuteMap(DBSQL, DBStatement, DBParameters)
		If Columns.IsInitialized Then
			Dim ColumnTypes(Columns.Size) As String
			Dim i As Int
			For i = 0 To Columns.Size - 1
				ColumnTypes(i) = DBUtils.DB_TEXT
			Next
		Else
			Dim ColumnTypes() As String
		End If

		Dim Rows As Map = DBUtils.ExecuteJSON(DBSQL, DBStatement, DBParameters, 0, ColumnTypes)
		If BlnShowExtraLogs Then Log(Rows.As(JSON).ToString)
		ORMTable.Results = Rows.Get("root")
		ORMTable.RowCount = ORMTable.Results.Size

		If ORMTable.RowCount > 0 Then
			ORMTable.First = ORMTable.Results.Get(0)
			ORMTable.Row = ORMTable.Results.Get(0)
			Columns.Initialize
			i = 0
			For Each Key In ORMTable.First.Keys
				Columns.Put(Key, i)
				i = i + 1
			Next
		End If

		Dim res As ORMResult
		res.Initialize
		res.Rows.Initialize
		res.Columns.Initialize
		res.Tag = Null 'without this the Tag properly will not be serializable.
		res.Rows = ORMTable.Results
		res.Columns = Columns
		ORMResult = res
		#Else
		BlnFirst = True
		Dim jrs As JavaObject = RS
		Dim rsmd As JavaObject = jrs.RunMethod("getMetaData", Null)
		Dim res As ORMResult
		res.Initialize
		res.Rows.Initialize
		res.Columns.Initialize
		res.Tag = Null 'without this the Tag properly will not be serializable.
      
		Dim cols As Int = RS.ColumnCount
		For i = 0 To cols - 1
			res.Columns.Put(RS.GetColumnName(i), i)
		Next
		Do While RS.NextRow
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
					If BlnUseTimestampsAsTicks Then
						Dim SQLTime As JavaObject = jrs.RunMethodJO(DateTimeMethods.Get(ct), Array(i + 1))
						If SQLTime.IsInitialized Then
							row(i) = SQLTime.RunMethod("getTime", Null)
						Else
							row(i) = Null
						End If
					Else
						row(i) = RS.GetString2(i) ' Do not use getObject, otherwise return different date formats for datetime and timestamps
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
		RS.Close ' test 2023-10-24
		ORMResult = res
		#End If
	Catch
		Log(LastException)
		LogColor("Are you missing ' = ?' in query?", COLOR_RED)
	End Try
	DBCondition = ""
	DBHaving = ""
	#If B4A or B4i
	DBParameters = Array As String()
	#Else
	DBParameters.Initialize
	#End If
End Sub

#If B4A or B4i
Public Sub Query2 (mParams() As String)
#Else
Public Sub Query2 (mParams As List)
#End If
	setParameters(mParams)
	Query
End Sub

' Return an object without calling Query
' Note: ORMTable and ORMResults are not affected
Public Sub Scalar As Object
	If DBCondition.Length > 0 Then DBStatement = DBStatement & DBCondition
	Dim paramsize As Int = ParametersCount
	If paramsize > 0 Then
		Return DBSQL.ExecQuerySingleResult2(DBStatement, DBParameters)
	Else
		Return DBSQL.ExecQuerySingleResult(DBStatement)
	End If
End Sub

#If B4A or B4i
' Similar to Scalar but passing Params
Public Sub Scalar2 (mParams() As String) As Object
#Else
' Similar to Scalar but passing Params
Public Sub Scalar2 (mParams As List) As Object
#End If
	setParameters(mParams)
	Return Scalar
End Sub

Public Sub Insert
	Dim cd As Boolean ' contains created_date
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
		If col.EqualsIgnoreCase("created_date") Then cd = True
	Next
	' To handle varchar timestamps
	If BlnUseTimestamps And Not(cd) Then
		If sb.Length > 0 Then
			sb.Append(", ")
			vb.Append(", ")
		End If
		sb.Append("created_date")
		Select DBEngine
			Case MYSQL
				vb.Append("NOW()")
			Case SQLITE
				vb.Append("DATETIME('now')")
		End Select
	End If
	DBStatement = $"INSERT INTO ${DBTable} (${sb.ToString}) VALUES (${vb.ToString})"$
	If BlnQueryAddToBatch Then AddNonQueryToBatch
	If BlnQueryExecute Then Execute
End Sub

#If B4A or B4i
Public Sub Insert2 (mParams() As String)
#Else
Public Sub Insert2 (mParams As List)
#End If
	setParameters(mParams)
	Insert
End Sub

' Update must have at least 1 condition
Public Sub Save
	Dim BlnNew As Boolean
	If DBCondition.Length > 0 Then
		Dim md As Boolean ' contains modified_date
		Dim sb As StringBuilder
		sb.Initialize
		DBStatement = $"UPDATE ${DBTable} SET "$
		For Each col As String In DBColumns
			If sb.Length > 0 Then sb.Append(", ")
			If col.EqualsIgnoreCase("modified_date") Then md = True
			If col.Contains("=") Then
				sb.Append(col)
			Else If col.EndsWith("++") Then
				col = col.Replace("++", "").Trim
				sb.Append($"${col} = ${col} + 1"$)
			Else
				sb.Append(col & " = ?")
			End If
		Next
		DBStatement = DBStatement & sb.ToString
		' To handle varchar timestamps
		If BlnUpdateModifiedDate And Not(md) Then
			Select DBEngine
				Case MYSQL
					DBStatement = DBStatement & ", modified_date = NOW()"
				Case SQLITE
					DBStatement = DBStatement & ", modified_date = DATETIME('now')"
			End Select
		End If
		DBStatement = DBStatement & DBCondition
	Else
		Dim cd As Boolean ' contains created_date
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
			If col.EqualsIgnoreCase("created_date") Then cd = True
		Next
		' To handle varchar timestamps
		If BlnUseTimestamps And Not(cd) Then
			If sb.Length > 0 Then
				sb.Append(", ")
				vb.Append(", ")
			End If
			sb.Append("created_date")
			Select DBEngine
				Case MYSQL
					vb.Append("NOW()")
				Case SQLITE
					vb.Append("DATETIME('now')")
			End Select
		End If
		DBStatement = $"INSERT INTO ${DBTable} (${sb.ToString}) VALUES (${vb.ToString})"$
		BlnNew = True
	End If
	
	Dim paramsize As Int = ParametersCount
	If BlnNew Then
		If paramsize > 0 Then
			If BlnShowExtraLogs Then LogQuery2
			DBSQL.ExecNonQuery2(DBStatement, DBParameters)
		Else
			If BlnShowExtraLogs Then LogQuery
			DBSQL.ExecNonQuery(DBStatement)
		End If
		Dim NewID As Int = getLastInsertID
		' Return new row
		Find(NewID)
	Else
		If paramsize > 0 Then
			If BlnShowExtraLogs Then LogQuery2
			DBSQL.ExecNonQuery2(DBStatement, DBParameters)
		Else
			If BlnShowExtraLogs Then LogQuery
			DBSQL.ExecNonQuery(DBStatement)
		End If
		' Count numbers of ?
		Dim Params As Int = CountChar("?", DBCondition)
		DBStatement = "SELECT * FROM " & DBTable
		#If B4A or B4i
		Dim ConditionParams(Params) As String
		For i = 0 To Params - 1
			ConditionParams(i) = DBParameters(paramsize - Params + i)
		Next
		#Else
		Dim ConditionParams As List
		ConditionParams.Initialize
		For i = 0 To Params - 1
			ConditionParams.Add(DBParameters.Get(paramsize - Params + i))
		Next
		#End If
		DBParameters = ConditionParams
		' Return row after update
		Query
	End If
End Sub

#If B4A or B4i
Public Sub Save2 (mParams() As String)
#Else
Public Sub Save2 (mParams As List)
#End If
	setParameters(mParams)
	Save
End Sub

Public Sub getLastInsertID As Object
	Select DBEngine
		Case MYSQL
			DBStatement = "SELECT LAST_INSERT_ID()"
		Case SQLITE
			DBStatement = "SELECT LAST_INSERT_ROWID()"
		Case Else
			If BlnShowExtraLogs Then Log("Unknown DBEngine")
			Return -1
	End Select
	If BlnShowExtraLogs Then LogQuery
	Return DBSQL.ExecQuerySingleResult(DBStatement)
End Sub

' Adding new Condition
Public Sub setWhere (mStatements As List)
	Dim sb As StringBuilder
	sb.Initialize
	For Each statement In mStatements
		If sb.Length > 0 Then sb.Append(" AND ") Else sb.Append(" WHERE ")
		sb.Append(statement)
	Next
	DBCondition = DBCondition & sb.ToString
End Sub

' Set Condition with single condition and value
Public Sub WhereParam (mCondition As String, mValue As Object)
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append(" WHERE ")
	sb.Append(mCondition)
	DBCondition = sb.ToString
	#If B4A or B4i
	setParameters(Array As String(mValue))
	#Else
	setParameters(Array As Object(mValue))
	#End If
End Sub

#If B4A or B4i
' Append new Condition and Parameters
Public Sub WhereParams (mConditions As List, mParams() As String)
#Else
' Append new Condition and Parameters
Public Sub WhereParams (mConditions As List, mParams As List)
#End If
	Dim sb As StringBuilder
	sb.Initialize
	For Each condition In mConditions
		If sb.Length > 0 Then sb.Append(" AND ") Else sb.Append(" WHERE ")
		sb.Append(condition)
	Next
	DBCondition = DBCondition & sb.ToString
	AddParameters(mParams)
End Sub

Public Sub Delete
	DBStatement = $"DELETE FROM ${DBTable}"$
	If DBCondition.Length > 0 Then DBStatement = DBStatement & DBCondition
	Dim paramsize As Int = ParametersCount
	If paramsize > 0 Then
		If BlnShowExtraLogs Then LogQuery2
		DBSQL.ExecNonQuery2(DBStatement, DBParameters)
	Else
		If BlnShowExtraLogs Then LogQuery
		DBSQL.ExecNonQuery(DBStatement)
	End If
	DBCondition = ""
End Sub

Public Sub Destroy (ids() As Int) As ResumableSub
	If ids.Length < 1 Then Return False
	For i = 0 To ids.Length - 1
		DBStatement = $"DELETE FROM ${DBTable} WHERE id = ?"$
		If BlnShowExtraLogs Then LogQueryWithArg(ids(i))
		DBSQL.AddNonQueryToBatch(DBStatement, Array(ids(i)))
	Next
	Dim SenderFilter As Object = DBSQL.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	'Log("NonQuery: " & Success)
	Return Success
End Sub

Public Sub SoftDelete
	Select DBEngine
		Case MYSQL
			DBStatement = $"UPDATE ${DBTable} SET deleted_date = now()"$
		Case SQLITE
			DBStatement = $"UPDATE ${DBTable} SET deleted_date = strftime('%s000', 'now')"$
		Case Else
			If BlnShowExtraLogs Then Log("Unknown DBEngine")
			Return
	End Select
	If DBCondition.Length > 0 Then DBStatement = DBStatement & DBCondition
	If BlnShowExtraLogs Then LogQuery
	DBSQL.ExecNonQuery(DBStatement)
End Sub

' Tests whether the table exists (SQLite)
Public Sub TableExists (TableName As String) As Boolean
	' SQLite code extracted from DBUtils
	DBStatement = $"SELECT count(name) FROM sqlite_master WHERE type = 'table' AND name = ? COLLATE NOCASE"$
	If BlnShowExtraLogs Then LogQueryWithArg(TableName)
	Dim count As Int = DBSQL.ExecQuerySingleResult2(DBStatement, Array As String(TableName))
	Return count > 0
End Sub

' Tests whether the table exists in the given database (MySQL)
Public Sub TableExists2 (TableName As String, DatabaseName As String) As Boolean
	DBStatement = $"SELECT count(TABLE_NAME) FROM TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?"$
	If BlnShowExtraLogs Then LogQueryWithArg(Array As String(DatabaseName, TableName))
	Dim count As Int = DBSQL.ExecQuerySingleResult2(DBStatement, Array As String(DatabaseName, TableName))
	Return count > 0
End Sub

' Append to the end of SQL statement
Public Sub Append (strSQL As String) As String
	DBStatement = DBStatement & strSQL
	Return DBStatement
End Sub

' Set raw SQL statement. Call Reset first.
Public Sub setStatement (strSQL As String)
	DBStatement = strSQL
End Sub

' Return SQL statement
Public Sub getStatement As String
	Return DBStatement
End Sub

' Print current SQL statement without parameters
Public Sub LogQuery
	Log(DBStatement)
End Sub

' Print current SQL statement and parameters
Public Sub LogQuery2
	Log(DBStatement)
	Log(DBParameters)
End Sub

' Print current SQL statement without parameters
Public Sub LogQueryWithArg (Arg As Object)
	Log($"${DBStatement} [${Arg}]"$)
End Sub

Public Sub Split (str As String) As String()
	Log(str)
	Dim ss() As String
	ss = Regex.Split(",", str)
	For Each s As String In ss
		s = s.Trim
	Next
	Log(ss)
	Return ss
End Sub

'#If B4A or B4i
' Merge 2 arrays
'Public Sub Merge (array1() As String, array2() As String) As String()
'	Dim BC As ByteConverter
'	Dim array3(array1.Length + array2.Length) As String
'	BC.ArrayCopy(array1, 0, array3, 0, array1.Length)
'	BC.ArrayCopy(array2, 0, array3, array1.Length, array2.Length)
'	Return array3
'End Sub
'#End If

Private Sub ParametersCount As Int
	#If B4A or B4i
	Return DBParameters.Length
	#Else
	Return DBParameters.Size
	#End If
End Sub

Private Sub CountChar (c As String, Word As String) As Int
	Dim count As Int
	For i = 0 To Word.Length - 1
		If c = Word.SubString2(i, i + 1) Then
			count = count + 1
		End If
	Next
	Return count
End Sub

Public Sub CreateColumn (ColumnName As String, ColumnType As String, ColumnLength As String, Collation As String, DefaultValue As String, AllowNull As Boolean, IsUnique As Boolean, AutoIncrement As Boolean) As ORMColumn
	Dim t1 As ORMColumn
	t1.Initialize
	t1.ColumnName = ColumnName
	t1.ColumnType = ColumnType
	t1.ColumnLength = ColumnLength
	t1.Collation = Collation
	t1.DefaultValue = DefaultValue
	t1.AllowNull = AllowNull
	t1.Unique = IsUnique
	t1.AutoIncrement = AutoIncrement
	If t1.ColumnType = "" Then t1.ColumnType = VARCHAR
	If t1.ColumnType = VARCHAR And t1.ColumnLength = "" Then t1.ColumnLength = "255"
	If t1.ColumnType = BIG_INT And t1.ColumnLength = "" Then t1.ColumnLength = "20"
	'If t1.ColumnType = INTEGER Or t1.ColumnType = TIMESTAMP Or t1.ColumnLength = "0" Then t1.ColumnLength = ""
	If t1.ColumnType = INTEGER Then t1.ColumnLength = "11"
	If t1.ColumnType = TIMESTAMP Then t1.ColumnLength = ""
	If t1.ColumnLength = "0" Then t1.ColumnLength = ""
	Return t1
End Sub

' Name - Column Name (String)
' Type - Column Type (String) e.g INTEGER/DECIMAL/VARCHAR/TIMESTAMP
' Size - Column Length (String) e.g 255/10,2
' Collation - Collation for char (String) e.g COLLATE utf8mb4_unicode_ci
' Default - Default Value (String) e.g CURRENT_TIMESTAMP/now()/1
' Null - Allow Null (Boolean)
' Unique - Is Unique (Boolean)
' AutoIncrement - Auto increment (Boolean)
Public Sub CreateColumn2 (Props As Map) As ORMColumn
	Dim t1 As ORMColumn
	t1.Initialize
	t1.ColumnName = ""
	t1.ColumnType = ""
	t1.ColumnLength = ""
	t1.Collation = ""
	t1.DefaultValue = ""
	t1.AllowNull = True
	t1.Unique = False
	t1.AutoIncrement = False
	For Each Key As String In Props.Keys
		Select Key.ToLowerCase
			Case "ColumnName".ToLowerCase, "Name".ToLowerCase
				t1.ColumnName = Props.Get(Key)
			Case "ColumnType".ToLowerCase, "Type".ToLowerCase
				t1.ColumnType = Props.Get(Key)
			Case "ColumnLength".ToLowerCase, "ColumnSize".ToLowerCase, "Length".ToLowerCase, "Size".ToLowerCase
				t1.ColumnLength = Props.Get(Key)
			Case "Collation".ToLowerCase
				t1.Collation = Props.Get(Key)
			Case "DefaultValue".ToLowerCase, "Default".ToLowerCase
				t1.DefaultValue = Props.Get(Key)
			Case "Nullable".ToLowerCase, "Null".ToLowerCase, "AllowNull".ToLowerCase
				t1.AllowNull = Props.Get(Key)
			Case "Unique".ToLowerCase
				t1.Unique = Props.Get(Key)
			Case "AutoIncrement".ToLowerCase
				t1.AutoIncrement = Props.Get(Key)
			Case Else
				t1.ColumnName = Key
		End Select
	Next
	If t1.ColumnType = "" Then t1.ColumnType = VARCHAR
	If t1.ColumnType = VARCHAR And t1.ColumnLength = "" Then t1.ColumnLength = "255"
	If t1.ColumnType = BIG_INT And t1.ColumnLength = "" Then t1.ColumnLength = "20"
	'If t1.ColumnType = INTEGER Or t1.ColumnType = TIMESTAMP Or t1.ColumnLength = "0" Then t1.ColumnLength = ""
	If t1.ColumnType = INTEGER Then t1.ColumnLength = "11"
	If t1.ColumnType = TIMESTAMP Then t1.ColumnLength = ""
	If t1.ColumnLength = "0" Then t1.ColumnLength = ""
	Return t1
End Sub

Public Sub CreateFilter (Column As String, Operator As String, Value As String) As ORMFilter
	Dim t1 As ORMFilter
	t1.Initialize
	t1.Column = Column
	t1.Operator = Operator
	t1.Value = Value
	Return t1
End Sub

Public Sub CreateJoin (Table2 As String, OnConditions As String, Mode As String) As ORMJoin
	Dim t1 As ORMJoin
	t1.Initialize
	t1.Table2 = Table2
	t1.OnConditions = OnConditions
	t1.Mode = Mode
	Return t1
End Sub