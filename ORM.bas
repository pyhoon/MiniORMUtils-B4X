B4J=true
Group=​Breakpoints
ModulesStructureVersion=1
Type=Class
Version=9.71
@EndOfDesignText@
Sub Class_Globals
	Private SQL As SQL
	Private strTable As String
	'Private Error As String 'ignore
	Private DateTimeMethods As Map
	Private Query As String
	Private Condition As String
	Private BlnFirst As Boolean
	Private DBTable As ORMTable
	Private DBColumn As Map
	Public Const INTEGER As String = "INTEGER"
	Public Const DECIMAL As String = "NUMERIC" ' "DECIMAL"
	Public Const VARCHAR As String = "TEXT" ' "VARCHAR"
	Type DBResult (Tag As Object, Columns As Map, Rows As List)
	Type ORMTable (ResultSet As ResultSet, Count As Int, Data As List, Row As Object, First As Object)
	Type ORMColumn (ColumnName As String, ColumnType As String, ColumnLength As String, DefaultValue As String, Nullable As Boolean, AutoIncrement As Boolean)
	Type ORMFilter (Column As String, Operator As String, Value As String)
End Sub

Public Sub Initialize (mSQL As SQL)
	SQL = mSQL
	DateTimeMethods = CreateMap(91: "getDate", 92: "getTime", 93: "getTimestamp")
End Sub

Public Sub setTable (mTable As String)
	strTable = mTable
	Reset
End Sub

Public Sub getTable As String
	Return strTable
End Sub

Public Sub getDBResult As DBResult
	' Check table exist?
	If DBUtils.TableExists(SQL, strTable) Then
		Return OrderBy(Null, "")
	End If
	Return Null
End Sub

Public Sub setDataColumn (mDataColumn As Map)
	DBColumn = mDataColumn
End Sub

'Public Sub getDataColumn As Map
'	Return DBColumn
'End Sub

Public Sub Reset
	Query = $"SELECT * FROM ${strTable}"$
	Query = Query & " WHERE deleted_date IS NULL"
End Sub

Public Sub First As Object
	BlnFirst = True
	Return DBTable.First
End Sub

Public Sub Find (id As Int) As Object
	Condition = $" AND id = ${id}"$
	OrderBy(Null, "")
	Return DBTable.Row
End Sub

Public Sub getCount As Int
	OrderBy(Null, "")
	Return DBTable.Count
End Sub

Public Sub Results As List
	Return DBTable.Data
End Sub

Public Sub ResultSet As ResultSet
	Return DBTable.ResultSet
End Sub

Public Sub OrderBy (Col As Map, Limit As String) As DBResult
	If Query.Length = 0 Then Return Null
	If Condition.Length > 0 Then Query = Query & Condition
	If Col.IsInitialized Then
		Dim sb As StringBuilder
		sb.Initialize
		For Each k As String In Col.Keys
			If sb.Length > 0 Then sb.Append(", ")
			sb.Append(k & " " & Col.Get(k))
		Next
		Query = Query & $" ORDER BY ${sb.ToString}"$
	End If
	If Limit.Length > 0 Then Query = Query & $" LIMIT ${Limit}"$ ' Limit 10, 10 <-- second parameter is OFFSET
	Try
		Dim RS As ResultSet = SQL.ExecQuery(Query)
		DBTable.Initialize
		DBTable.Data.Initialize
		DBTable.ResultSet = RS
		Dim jrs As JavaObject = RS
		Dim rsmd As JavaObject = jrs.RunMethod("getMetaData", Null)
		Dim cols As Int = RS.ColumnCount
		Dim res As DBResult
		res.Initialize
		res.columns.Initialize
		res.Tag = Null 'without this the Tag properly will not be serializable.
		For i = 0 To cols - 1
			res.columns.Put(RS.GetColumnName(i), i)
		Next
		res.Rows.Initialize
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
			DBTable.Count = res.Rows.Size
			DBTable.Row = map1
			DBTable.Data.Add(map1)
			If BlnFirst Then
				DBTable.First = map1 ' row
				BlnFirst = False
				Return res
			End If			
		Loop
		RS.Close
	Catch
		Log(LastException)
		'Error = LastException
	End Try
	Return res
End Sub

Public Sub Create (mColumns As List, mTimestamp As Boolean)
	Dim sb As StringBuilder
	sb.Initialize
	' Start construct columns
	For i = 0 To mColumns.Size - 1
		If sb.Length > 0 Then sb.Append(",").Append(CRLF)
		Dim col As ORMColumn = mColumns.Get(i)
		sb.Append(col.ColumnName)
		sb.Append(" ").Append(col.ColumnType)
		If col.ColumnLength.Length > 0 Then sb.Append("(").Append(col.ColumnLength).Append(")")
		If Not(col.Nullable) Then sb.Append(" NOT NULL")
		If col.DefaultValue.Length > 0 Then sb.Append(" DEFAULT ").Append(col.DefaultValue)
	Next
	' Add Created_Date and Modified_Date columns by default if set to True
	If mTimestamp Then
		sb.Append(",").Append(CRLF)
		sb.Append("created_date INTEGER DEFAULT (strftime('%s000', 'now', 'localtime')),").Append(CRLF) ' SQLite
		sb.Append("modified_date INTEGER,").Append(CRLF)
		sb.Append("deleted_date INTEGER,")
	End If
	Dim cmd As StringBuilder
	cmd.Initialize
	cmd.Append($"CREATE TABLE ${strTable} ("$)
	' id created by mandatory
	cmd.Append($"id INTEGER,"$).Append(CRLF)
	cmd.Append(sb.ToString)
	' Pimary key id created by default
	cmd.Append(CRLF)
	cmd.Append($"PRIMARY KEY(id AUTOINCREMENT)"$)
	cmd.Append(")")
	Query = cmd.ToString
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
	Query = Query.Replace("PRIMARY KEY(id AUTOINCREMENT)", sb.ToString)
End Sub

' Insert new foreign keys
Public Sub Foreign (mKey As String, mReferences As String, mOnTable As String, mOnDelete As String, mOnUpdate As String)
	Dim sb As StringBuilder
	sb.Initialize
	' Find last close bracket position and insert new string
	Dim position As Int = Query.LastIndexOf(")")
	sb.Append( Query.SubString2(0, position) )
	'Log ( sb.ToString )
	sb.Append(",")
	sb.Append(CRLF)
	sb.Append( $"FOREIGN KEY (${mKey}) REFERENCES ${mOnTable} (${mReferences})"$ )
	If mOnDelete.Length > 0 Then sb.Append( " ON DELETE " & mOnDelete )
	If mOnUpdate.Length > 0 Then sb.Append( " ON UPDATE " & mOnUpdate )
	sb.Append(")")
	'Log ( sb.ToString )
	Query = sb.ToString
End Sub

Public Sub Execute
	Log ( Query )
	File.WriteString(File.DirApp, "ORM.txt", Query)
	SQL.ExecNonQuery(Query)
End Sub

Public Sub Save
	Dim cmd As String 
	Dim prm As List
	prm.Initialize
	If Condition.Length > 0 Then
		Dim sb As StringBuilder
		sb.Initialize
		cmd = $"UPDATE ${strTable} SET "$
		For Each col As String In DBColumn.Keys
			If sb.Length > 0 Then sb.Append(", ")
			sb.Append(col & " = ?")
			prm.Add(DBColumn.Get(col))
		Next
		cmd = cmd & sb.ToString & Condition
		Condition = ""
	Else
		Dim sb, vb As StringBuilder
		sb.Initialize
		vb.Initialize
		For Each col As String In DBColumn.Keys
			If sb.Length > 0 Then
				 sb.Append(", ")
				 vb.Append(", ")
			Else
				sb.Append(" (")
			End If
			sb.Append(col)
			vb.Append( "?" )
			prm.Add(DBColumn.Get(col))
		Next
		sb.Append(") ")
		cmd = $"INSERT INTO ${strTable}"$ & sb.ToString & " SELECT " & vb.ToString
	End If
	'Log ( cmd )
	'File.WriteString(File.DirApp, "ORM.txt", cmd & CRLF & CRLF & "param=" & prm.As(String))
	SQL.ExecNonQuery2(cmd, prm)
End Sub

Public Sub Where (mFilters As List)
	Dim sb As StringBuilder
	sb.Initialize
	For i = 0 To mFilters.Size - 1
		'If sb.Length > 0 Then
			sb.Append(" AND ")
		'Else
		'	sb.Append(" WHERE ")
		'End If
		Dim ft As ORMFilter = mFilters.Get(i)
		sb.Append($"${ft.Column} ${ft.Operator} ${ft.Value}"$)
	Next
	Condition = sb.ToString
End Sub

Public Sub Delete
	Dim cmd As String = $"DELETE FROM ${strTable}"$
	If Condition.Length > 0 Then cmd = cmd & Condition
	SQL.ExecNonQuery(cmd)
	Condition = ""
End Sub

Public Sub Destroy (ids() As Int)
	If ids.Length < 1 Then Return
	Dim cmd As String
	For i = 0 To ids.Length - 1
		cmd = $"DELETE FROM ${strTable} WHERE id = ?"$
		SQL.AddNonQueryToBatch(cmd, Array(ids(i)))
	Next
	Dim SenderFilter As Object = SQL.ExecNonQueryBatch("SQL")
	Wait For (SenderFilter) SQL_NonQueryComplete (Success As Boolean)
	Log("NonQuery: " & Success)
End Sub

Public Sub SoftDelete
	Dim cmd As String = $"UPDATE ${strTable} SET deleted_date = strftime('%s000', 'now', 'localtime')"$
	If Condition.Length > 0 Then cmd = cmd & Condition
	SQL.ExecNonQuery(cmd)
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