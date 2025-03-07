B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Database Connector class
' Version 2.00
Sub Class_Globals
	Private SQL		As SQL
	Private CN 		As ConnectionInfo
	#If B4J
	Private Pool 	As ConnectionPool
	#End If
	Type ConnectionInfo ( _
	DBDir As String, _
	DBFile As String, _
	DBType As String, _
	DBHost As String, _
	DBPort As String, _
	DBName As String, _
	DriverClass As String, _
	JdbcUrl As String, _
	User As String, _
	Password As String, _
	JournalMode As String, _
	MaxPoolSize As Int)
	Private DBType As String
	Private mJournalMode As String = "DELETE"
	#If B4J
	Private mCharacterSet As String = "utf8mb4"
	Private mCollate As String = "utf8mb4_unicode_ci"
	Public Const MYSQL As String = "MYSQL"
	#End If
	Public Const SQLITE As String = "SQLITE"
End Sub

' If InitPool is True, database will be initialized
' Set to False if database is not created
Public Sub Initialize (Info As ConnectionInfo)
	CN = Info
	DBType = Info.DBType.ToUpperCase
	#If B4A
	If CN.DBDir = "" Then CN.DBDir = File.DirInternal
	#End If
	#If B4i
	If CN.DBDir = "" Then CN.DBDir = File.DirDocuments
	#End If
	#If B4J
	If CN.DBDir = "" Then CN.DBDir = File.DirApp
	'CN.JdbcUrl = CN.JdbcUrl.Replace("{DbName}", CN.DBName)
	CN.JdbcUrl = CN.JdbcUrl.Replace("{DbHost}", CN.DBHost)
	CN.JdbcUrl = IIf(CN.DBPort.Length = 0, CN.JdbcUrl.Replace(":{DbPort}", ""), CN.JdbcUrl.Replace("{DbPort}", CN.DBPort))
	CN.JdbcUrl = IIf(CN.DBDir.Length = 0, CN.JdbcUrl.Replace("{DbDir}" & GetSystemProperty("file.separator", "/"), ""), CN.JdbcUrl.Replace("{DbDir}", CN.DBDir))
	CN.JdbcUrl = IIf(CN.DBFile.Length = 0, CN.JdbcUrl.Replace("{DbFile}", ""), CN.JdbcUrl.Replace("{DbFile}", CN.DBFile))
	#End If
End Sub

Public Sub InitializePool
	Dim JdbcUrl2 As String = CN.JdbcUrl
	JdbcUrl2 = JdbcUrl2.Replace("{DbName}", CN.DBName)
	JdbcUrl2 = JdbcUrl2.Replace("{DbHost}", CN.DBHost)
	JdbcUrl2 = IIf(CN.DBPort.Length = 0, JdbcUrl2.Replace(":{DbPort}", ""), JdbcUrl2.Replace("{DbPort}", CN.DBPort))
	Pool.Initialize(CN.DriverClass, JdbcUrl2, CN.User, CN.Password)
	If CN.MaxPoolSize > 0 Then
		Dim jo As JavaObject = Pool
		jo.RunMethod("setMaxPoolSize", Array(CN.MaxPoolSize))
	End If
End Sub

#If B4J
' Create database
Public Sub DBCreate As ResumableSub
	Try
		Select DBType
			Case MYSQL
				Wait For (DBSchema) Complete (SQL1 As SQL)
				Dim qry As String = $"CREATE DATABASE ${CN.DBName} CHARACTER SET ${mCharacterSet} COLLATE ${mCollate}"$
				SQL1.ExecNonQuery(qry)
			Case SQLITE
				Select mJournalMode.ToUpperCase
					Case "WAL"
						'SQL1.Initialize(CN.DriverClass, CN.JdbcUrl)
						'SQL1.ExecNonQuery("PRAGMA journal_mode = wal")
						SQL1.InitializeSQLite(CN.DBDir, CN.DBFile, True)
						SQL1.ExecQuerySingleResult("PRAGMA journal_mode = wal")
					Case "DELETE"
						SQL1.InitializeSQLite(CN.DBDir, CN.DBFile, True)
				End Select
		End Select
	Catch
		Log(LastException)
		Return False
	End Try
	Close(SQL1)
	Select DBType
		Case MYSQL
			
	End Select
	Return True
End Sub
#Else
' Create SQLite database
Public Sub DBCreate As Boolean
	Try
		Dim SQL1 As SQL
		SQL1.Initialize(CN.DBDir, CN.DBFile, True)
	Catch
		Log(LastException.Message)
		Return False
	End Try
	Close(SQL1)
	Return True
End Sub
#End If

'Public Sub InitializePool 'As ResumableSub
'	Try
'		'Dim Schema As String = "information_schema"
'		Dim JdbcUrl2 As String = CN.JdbcUrl
'		JdbcUrl2 = JdbcUrl2.Replace("{DbName}", CN.DBName)
'		JdbcUrl2 = JdbcUrl2.Replace("{DbHost}", CN.DBHost)
'		JdbcUrl2 = IIf(CN.DBPort.Length = 0, JdbcUrl2.Replace(":{DbPort}", ""), JdbcUrl2.Replace("{DbPort}", CN.DBPort))
'		Pool.Initialize(CN.DriverClass, JdbcUrl2, CN.User, CN.Password)
''		Wait For SQL_Ready (Success As Boolean)
''		If Success = False Then
''			Log(LastException)
''			Return SQL
''		End If
'		If CN.MaxPoolSize > 0 Then
'			Dim jo As JavaObject = Pool
'			jo.RunMethod("setMaxPoolSize", Array(CN.MaxPoolSize))
'		End If
'	Catch
'		LogError(LastException)
'		'Return SQL
'	End Try
'End Sub

' Connect to database schema (MySQL)
Public Sub DBSchema As ResumableSub
	Try
		Dim Schema As String = "information_schema"
		Dim JdbcUrl2 As String = CN.JdbcUrl
		JdbcUrl2 = JdbcUrl2.Replace("{DbName}", Schema)
		JdbcUrl2 = JdbcUrl2.Replace("{DbHost}", CN.DBHost)
		JdbcUrl2 = IIf(CN.DBPort.Length = 0, JdbcUrl2.Replace(":{DbPort}", ""), JdbcUrl2.Replace("{DbPort}", CN.DBPort))
		Dim SQL1 As SQL
		SQL1.InitializeAsync("DB", CN.DriverClass, JdbcUrl2, CN.User, CN.Password)
		Wait For DB_Ready (Success As Boolean)
		If Success = False Then
			Log(LastException)
		End If
	Catch
		LogError(LastException)
	End Try
	Return SQL1
End Sub

' Check database file exists (SQLite)
Public Sub DBExist As Boolean
	Dim DBFound As Boolean
	If File.Exists(CN.DBDir, CN.DBFile) Then
		DBFound = True
	End If
	Return DBFound
End Sub

#If B4J
' Check database exists (MySQL)
Public Sub DBExist2 As ResumableSub
	Dim DBFound As Boolean
	Try
		Wait For (DBSchema) Complete (SQL1 As SQL)
		If SQL1 <> Null And SQL1.IsInitialized Then
			Dim qry As String = "SELECT * FROM SCHEMATA WHERE SCHEMA_NAME = ?"
			Dim rs As ResultSet = SQL1.ExecQuery2(qry, Array As String(CN.DBName))
			Do While rs.NextRow
				DBFound = True
			Loop
			rs.Close
		End If
	Catch
		LogError(LastException)
	End Try
	Close(SQL1)
	Return DBFound
End Sub
#End If

' Connect to database server
' Note: SQLite uses DBDir and DBFile
Public Sub DBOpen As SQL
	#If B4A or B4i
	If DBExist Then
		DB.Initialize(CN.DBDir, CN.DBFile, False)
	End If
	#End If
	#If B4J
	Select DBType
		Case MYSQL
			SQL = Pool.GetConnection
		Case SQLITE
			SQL.InitializeSQLite(CN.DBDir, CN.DBFile, False)
	End Select
	#End If
	Return SQL
End Sub

#If B4J
' Connect to database server (asynchronously connection)
' Note: SQLite uses JdbcUrl
Public Sub DBOpen2 As ResumableSub
	Try
		Select DBType
			Case MYSQL
				Pool.GetConnectionAsync("Pool")
				Wait For Pool_ConnectionReady (DB1 As SQL)
				SQL = DB1
			Case SQLITE
				SQL.InitializeAsync("DB", CN.DriverClass, CN.JdbcUrl, CN.User, CN.Password)
				Wait For DB_Ready (Success As Boolean)
				If Success = False Then
					Log(LastException)
				End If

		End Select
	Catch
		LogError(LastException.Message)
	End Try
	Return SQL
End Sub
#End If

' Close SQL object
Public Sub DBClose
	#If server
	' Do not close SQLite object in multi-threaded server handler in release mode
	If DBType = SQLITE Then
		Return
	End If
	#End If
	If SQL <> Null And SQL.IsInitialized Then SQL.Close
End Sub

' Check database can be connected
Public Sub Test As Boolean
	Dim con As SQL = DBOpen
	If con <> Null And con.IsInitialized Then
		con.Close
		Return True
	End If
	Return False
End Sub

' Close SQL object
Public Sub Close (SQL1 As SQL)
	#If server
	' Do not close SQLite object in multi-threaded server handler in release mode
	If DBType = SQLITE Then
		Return
	End If
	#End If
	If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
End Sub

' Return server date
Public Sub GetDate As String
	Try
		Select DBType
			Case MYSQL
				Dim qry As String = $"SELECT CURDATE()"$
			Case SQLITE
				Dim qry As String = $"SELECT DATE('now')"$
			Case Else
				Dim CurrentDateFormat As String = DateTime.DateFormat
				DateTime.DateFormat = "yyyy-MM-dd"
				Dim DateValue As String = DateTime.Date(DateTime.Now)
				DateTime.DateFormat = CurrentDateFormat
				Return DateValue
		End Select
		Dim con As SQL = DBOpen
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		Log(LastException.Message)
	End Try
	Close(con)
	Return str
End Sub

' Return server date (ascynchronous connection)
Public Sub GetDate2 As ResumableSub
	Try
		Select DBType
			Case MYSQL
				Dim qry As String = $"SELECT CURDATE()"$
			Case SQLITE
				Dim qry As String = $"SELECT DATE('now')"$
			Case Else
				DateTime.DateFormat = "yyyy-MM-dd"
				Return DateTime.Date(DateTime.Now)
		End Select
		#If B4J
		Wait For (DBOpen2) Complete (con As SQL)
		#Else
		Dim con As SQL = DBOpen
		#End If
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		Log(LastException.Message)
	End Try
	Close(con)
	Return str
End Sub

' Return server timestamp
Public Sub GetDateTime As String
	Try
		Select DBType
			Case MYSQL
				Dim qry As String = $"SELECT NOW()"$
			Case SQLITE
				Dim qry As String = $"SELECT DATETIME('now')"$
			Case Else	
				Dim CurrentDateFormat As String = DateTime.DateFormat
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Dim DateValue As String = DateTime.Date(DateTime.Now)
				DateTime.DateFormat = CurrentDateFormat
				Return DateValue
		End Select
		Dim con As SQL = DBOpen
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		Log(LastException.Message)
	End Try
	Close(con)
	Return str
End Sub

' Return server timestamp (ascynchronous connection)
Public Sub GetDateTime2 As ResumableSub
	Try
		Select DBType
			Case MYSQL
				Dim qry As String = $"SELECT NOW()"$
			Case SQLITE
				Dim qry As String = $"SELECT DATETIME('now')"$
			Case Else
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Return DateTime.Date(DateTime.Now)
		End Select
		#If B4J
		Wait For (DBOpen2) Complete (con As SQL)
		#Else
		Dim con As SQL = DBOpen
		#End If		
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		Log(LastException.Message)
	End Try
	Close(con)
	Return str
End Sub

Public Sub setCharacterSet (NewCharSet As String)
	mCharacterSet = NewCharSet
End Sub

Public Sub setCollate (NewCollate As String)
	mCollate = NewCollate
End Sub

Public Sub setJournalMode (Mode As String)
	mJournalMode = Mode
End Sub

Public Sub getDBFolder As String
	Return CN.DBDir
End Sub

' Return DBType
Public Sub getDBEngine As String
	Return DBType
End Sub

' Return SQL query for Last Insert ID based on DBType
Public Sub getLastInsertIDQuery As String
	Select DBType
		Case MYSQL
			Dim qry As String = "SELECT LAST_INSERT_ID()"
		Case SQLITE
			Dim qry As String = "SELECT LAST_INSERT_ROWID()"
		Case Else
			Dim qry As String = "SELECT 0"
	End Select
	Return qry
End Sub