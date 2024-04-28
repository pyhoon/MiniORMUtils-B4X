B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' Database Connector class
' Version 1.11
Sub Class_Globals
	#If server
	Private Pool As ConnectionPool
	Private MaxPoolSize As Int
	#End If
	Private DB As SQL
	Private H2 As SQL
	Private Conn As Conn
	#if B4J
	Private Conn2 As Conn
	#End If
	Private DBType As String
	Private DBName As String
	Private DBDir As String
	#If B4J
	Private JdbcUrl As String
	Private DriverClass As String
	Private DBHost As String
	Private DBPort As String
	Private User As String
	Private Password As String
	#End If
	Type Conn ( _
	DBType 		As String, _
	DriverClass As String, _
	JdbcUrl 	As String, _
	User 		As String, _
	Password 	As String, _
	MaxPoolSize As Int, _
	DBHost 		As String, _
	DBPort 		As String, _
	DBName 		As String, _
	DBDir 		As String)
End Sub

Public Sub Initialize (mConn As Conn)
	Conn = mConn
	DBType = Conn.DBType
	DBName = Conn.DBName
	DBDir = Conn.DBDir
	
	#If B4A
	If DBDir = "" Then DBDir = File.DirInternal
	If DBName = "" Then DBName = "data.db"
	#End If
	
	#If B4i
	If DBDir = "" Then DBDir = File.DirDocuments
	If DBName = "" Then DBName = "data.db"
	#End If

	#If B4J
	DBHost = Conn.DBHost
	DBPort = Conn.DBPort
	JdbcUrl = Conn.JdbcUrl
	DriverClass = Conn.DriverClass
	User = Conn.User
	Password = Conn.Password
	
	JdbcUrl = JdbcUrl.Replace("{DbName}", DBName)
	JdbcUrl = JdbcUrl.Replace("{DbHost}", DBHost)
	JdbcUrl = IIf(DBPort.Length = 0, JdbcUrl.Replace(":{DbPort}", ""), JdbcUrl.Replace("{DbPort}", DBPort))
	
	JdbcUrl = IIf(DBDir.Length = 0, JdbcUrl.Replace("{DbDir}/", ""), JdbcUrl.Replace("{DbDir}", DBDir))
	#If server
	MaxPoolSize = Conn.MaxPoolSize
	#End If
	#End If
End Sub

#if B4J
Public Sub InitializeH2 (mConn As Conn)
	Conn2 = mConn
End Sub
#End If

' Create SQLite and MySQL database
Public Sub DBCreate As ResumableSub
	Dim Success As Boolean
	Dim SQL1 As SQL
	Try
		#If B4A or B4i
		SQL1.Initialize(DBDir, DBName, True)
		#End If	
		#If B4J
		Select DBType.ToUpperCase
			Case "SQLITE"
				#If server
				SQL1.Initialize(DriverClass, JdbcUrl)
				SQL1.ExecNonQuery("PRAGMA journal_mode = wal")
				#Else
				SQL1.InitializeSQLite(DBDir, DBName, True)
				#End If
			Case "MYSQL"
				Dim JdbcUrl2 As String = Conn.JdbcUrl
				JdbcUrl2 = JdbcUrl2.Replace("{DbName}", "information_schema")
				JdbcUrl2 = JdbcUrl2.Replace("{DbHost}", DBHost)
				JdbcUrl2 = IIf(DBPort.Length = 0, JdbcUrl2.Replace(":{DbPort}", ""), JdbcUrl2.Replace("{DbPort}", DBPort))
				SQL1.Initialize2(DriverClass, JdbcUrl2, User, Password)
				Dim qry As String = $"CREATE DATABASE ${DBName} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"$
				SQL1.ExecNonQuery(qry)
		End Select
		#End If
		Success = True
	Catch
		Log(LastException.Message)
	End Try
	Return Success
End Sub

' Check Database exists
Public Sub DBExist As ResumableSub
	Try
		Dim DBFound As Boolean
		Select DBType.ToUpperCase
			#If B4J			
			Case "MYSQL"
				Dim JdbcUrl2 As String = Conn.JdbcUrl
				JdbcUrl2 = JdbcUrl2.Replace("{DbName}", "information_schema")
				JdbcUrl2 = JdbcUrl2.Replace("{DbHost}", DBHost)
				JdbcUrl2 = IIf(DBPort.Length = 0, JdbcUrl2.Replace(":{DbPort}", ""), JdbcUrl2.Replace("{DbPort}", DBPort))
				Dim SQL1 As SQL
				SQL1.Initialize2(DriverClass, JdbcUrl2, User, Password)
				If SQL1 <> Null And SQL1.IsInitialized Then
					Dim qry As String = "SELECT * FROM SCHEMATA WHERE SCHEMA_NAME = ?"
					Dim rs As ResultSet = SQL1.ExecQuery2(qry, Array As String(DBName))
					Do While rs.NextRow
						DBFound = True
					Loop
					rs.Close
				End If
				If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
			#End If	
			Case "SQLITE"
				If File.Exists(Conn.DBDir, Conn.DBName) Then
					DBFound = True
				End If
		End Select
	Catch
		Log(LastException.Message)
	End Try
	Return DBFound
End Sub

Public Sub DBOpen As SQL
	#If B4A or B4i
	DB.Initialize(DBDir, DBName, False)
	#End If
	#If B4J
	Select DBType.ToUpperCase
		Case "MYSQL", "SQL SERVER", "FIREBIRD", "POSTGRESQL"
			#If server
			If Pool.IsInitialized = False Then
				Pool.Initialize(DriverClass, JdbcUrl, User, Password)
				If MaxPoolSize > 0 Then
					Dim jo As JavaObject = Pool
					jo.RunMethod("setMaxPoolSize", Array(MaxPoolSize))
				End If
			End If
			Return Pool.GetConnection
			#Else
			DB.Initialize2(DriverClass, JdbcUrl, User, Password)
			#End If
		Case "SQLITE"
			#If server
			DB.Initialize(DriverClass, JdbcUrl)
			#Else
			DB.InitializeSQLite(DBDir, DBName, False)
			#End If	
		Case "DBF"
			DB.Initialize(Conn.DriverClass, Conn.JdbcUrl)
			H2.Initialize(Conn2.DriverClass, Conn2.JdbcUrl)
	End Select
	#End If
	Return DB
End Sub

Public Sub DBClose
	Select DBType.ToUpperCase
		Case "SQLITE"
			' Do not close SQLite object in multi-threaded server handler in release mode
			#If Not(server)
			If DB <> Null And DB.IsInitialized Then DB.Close
			#End If
		Case Else
			If DB <> Null And DB.IsInitialized Then DB.Close
	End Select
End Sub

' Check database can be connected
Public Sub DBTest As Boolean
	Dim con As SQL = DBOpen
	If con <> Null And con.IsInitialized Then
		con.Close
		Return True
	End If
	Return False
End Sub

Public Sub H2Open As SQL
	Return H2
End Sub

Public Sub Close (SQL1 As SQL)
	Select DBType.ToUpperCase
		Case "SQLITE"
			' Do not close SQLite object in multi-threaded server handler in release mode
			#If Not(server)
			If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
			#End If
		Case Else
			If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
	End Select
End Sub

Public Sub GetDate As String
	Try
		Select DBType.ToUpperCase
			Case "MYSQL"
				Dim qry As String = $"SELECT now()"$
			Case "SQLITE"
				Dim qry As String = $"SELECT datetime(datetime('now'))"$
			Case Else
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Return DateTime.Date(DateTime.Now)
		End Select
		Dim con As SQL = DBOpen
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		Log(LastException.Message)
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	Return str
End Sub

Public Sub GetDateTime As String
	Try
		Select DBType.ToUpperCase
			Case "MYSQL"
				Dim qry As String = $"SELECT now()"$
			Case "SQLITE"
				Dim qry As String = $"SELECT datetime(datetime('now'))"$
			Case Else
				DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
				Return DateTime.Date(DateTime.Now)
		End Select
		Dim con As SQL = DBOpen
		Dim str As String = con.ExecQuerySingleResult(qry)
	Catch
		Log(LastException.Message)
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	Return str
End Sub

Public Sub getDBFolder As String
	Return DBDir
End Sub

' Return DBType
Public Sub getDBEngine As String
	Return DBType
End Sub

' Return SQL query for Last Insert ID based on DBType
Public Sub getLastInsertIDQuery As String
	Select DBType.ToUpperCase
		Case "MYSQL"
			Dim qry As String = "SELECT LAST_INSERT_ID()"
		Case "SQL SERVER"
			Dim qry As String = "SELECT SCOPE_IDENTITY()"
		Case "SQLITE"
			Dim qry As String = "SELECT LAST_INSERT_ROWID()"
		Case Else
			Dim qry As String = "SELECT 0"
	End Select
	Return qry
End Sub