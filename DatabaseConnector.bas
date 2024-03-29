﻿B4J=true
Group=Class
ModulesStructureVersion=1
Type=Class
Version=9.1
@EndOfDesignText@
' DatabaseConnector class
' Version 1.09
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
	Private DBDir As String
	Private DBFile As String
	#If B4J
	Private JdbcUrl As String
	Private DriverClass As String
	Private DBName As String
	Private User As String
	Private Password As String
	#End If
	Type Conn (DBType As String, DriverClass As String, JdbcUrl As String, User As String, Password As String, MaxPoolSize As Int, DBName As String, DBDir As String, DBFile As String)
End Sub

Public Sub Initialize (mConn As Conn)
	Conn = mConn
	DBType = Conn.DBType
	DBDir = Conn.DBDir
	DBFile = Conn.DBFile

	#If B4J
	JdbcUrl = Conn.JdbcUrl
	DriverClass = Conn.DriverClass
	DBName = Conn.DBName
	User = Conn.User
	Password = Conn.Password
	#End If
	#If server
	MaxPoolSize = Conn.MaxPoolSize
	#End If
	
	#If B4i
	If DBDir = "" Then DBDir = File.DirDocuments
	If DBFile = "" Then DBFile = "data.db"
	If File.Exists(DBDir, DBFile) Then
		DB.Initialize(DBDir, DBFile, False)
	End If
	#Else If B4A
	If DBDir = "" Then DBDir = File.DirInternal
	If DBFile = "" Then DBFile = "data.db"
	If File.Exists(DBDir, DBFile) Then
	'File.Delete(DBDir, DBFile)
		DB.Initialize(DBDir, DBFile, False)
	End If
	#Else
	Select DBType.ToUpperCase
		Case "MYSQL", "SQL SERVER", "FIREBIRD", "POSTGRESQL"
			#If server
			Pool.Initialize(DriverClass, JdbcUrl, User, Password)
			If MaxPoolSize > 0 Then
				Dim jo As JavaObject = Pool
				jo.RunMethod("setMaxPoolSize", Array(MaxPoolSize))
			End If
			#End If
			DB.Initialize2(DriverClass, JdbcUrl, User, Password)
		Case "SQLITE"
			#If B4J
			If DriverClass <> "" And JdbcUrl <> "" Then
				If JdbcUrl.Length > "jdbc:sqlite:".Length Then
					Dim Temp As String = JdbcUrl.SubString("jdbc:sqlite:".Length)
				End If

				If Temp = DBFile Then
					DBDir = File.DirApp
				Else
					DBFile = File.GetName(Temp)
					DBDir = Temp.Replace($"/${DBFile}"$, "")
				End If

				If File.Exists(DBDir, "") = False Then
					File.MakeDir(DBDir, "")
				End If
				If DBExist2(Conn) Then
					DB.Initialize(DriverClass, JdbcUrl)
				End If
				
			Else
				If DBDir = "" Then DBDir = File.DirApp
				If DBFile = "" Then DBFile = "data.db"
				If DBExist2(Conn) Then
					#If B4J
					DB.InitializeSQLite(DBDir, DBFile, True)
					#Else
					DB.Initialize(DBDir, DBFile, True)
					#End If
				End If
			End If
			#Else
			#If B4A
			DBDir = File.DirInternal
			#End If
			#If B4J
			DBDir = File.DirApp
			#End If				
			If DBFile = "" Then DBFile = "data.db"
			If DBExist2(Conn) Then
				#If B4J
				DB.InitializeSQLite(DBDir, DBFile, True)
				#Else
				DB.Initialize(DBDir, DBFile, True)
				#End If
			End If
			#End If			
		Case "DBF"
			#If B4J			
			DB.Initialize(Conn.DriverClass, Conn.JdbcUrl)
			H2.Initialize(Conn2.DriverClass, Conn2.JdbcUrl)
			#End If
	End Select
	#End If
End Sub

#if B4J
Public Sub InitializeH2 (mConn As Conn)
	Conn2 = mConn
End Sub
#End If

' Create SQLite and MySQL database
Public Sub DBCreate As SQL
	Dim SQL1 As SQL
	Try
		#If B4J
		Select DBType.ToUpperCase
			Case "SQLITE"
				If DriverClass <> "" And JdbcUrl <> "" Then
					DB.Initialize(DriverClass, JdbcUrl)
				Else
					DB.InitializeSQLite(DBDir, DBFile, True)
				End If
				SQL1 = DB
				#If server
				SQL1.ExecNonQuery("PRAGMA journal_mode = wal")
				#End If
			#If B4J
			Case "MYSQL"
				Dim InformationSchemaJdbcUrl As String = JdbcUrl.Replace(DBName, "information_schema")
				SQL1.Initialize2(DriverClass, InformationSchemaJdbcUrl, User, Password)
				Dim qry As String = $"CREATE DATABASE ${DBName} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"$
				SQL1.ExecNonQuery(qry)
				Dim qry As String = $"USE ${DBName}"$
				SQL1.ExecNonQuery(qry)
			#End If
		End Select		
		#End If
		#If B4A or B4i
		DB.Initialize(DBDir, DBFile, True)
		SQL1 = DB
		#End If		
	Catch
		Log(LastException.Message)
	End Try
	Return SQL1
End Sub

#If B4J
' Check Database exists
Public Sub DBExist As ResumableSub
	Try
		Dim DBFound As Boolean
		If DBType.EqualsIgnoreCase("MySQL") Then
			Dim InformationSchemaJdbcUrl As String = JdbcUrl.Replace(DBName, "information_schema")
			Dim SQL1 As SQL
			SQL1.Initialize2(DriverClass, InformationSchemaJdbcUrl, User, Password)
			If SQL1 <> Null And SQL1.IsInitialized Then
				Dim qry As String = "SELECT * FROM SCHEMATA WHERE SCHEMA_NAME = ?"
				Dim rs As ResultSet = SQL1.ExecQuery2(qry, Array As String(DBName))
				Do While rs.NextRow
					DBFound = True
				Loop
				rs.Close
			End If
			If SQL1 <> Null And SQL1.IsInitialized Then SQL1.Close
		End If
	Catch
		LogError(LastException.Message)
	End Try
	Return DBFound
End Sub
#End If

' Check SQLite database file exists
Public Sub DBExist2 (mConn As Conn) As Boolean
	Dim DBFound As Boolean
	If File.Exists(mConn.DBDir, mConn.DBFile) Then
		DBFound = True
		'Log(mConn.DBDir)
	End If
	Return DBFound
End Sub

Public Sub DBOpen As SQL
	#If server
	Select DBType.ToUpperCase
		Case "MYSQL", "SQL SERVER", "FIREBIRD", "POSTGRESQL"
			Return Pool.GetConnection
		Case Else
			Return DB
	End Select
	#Else
		#If B4A or B4i
		DB.Initialize(DBDir, DBFile, True)
		#Else
		Select DBType.ToUpperCase
			Case "SQLITE"
				If DriverClass <> "" And JdbcUrl <> "" Then
					If JdbcUrl.Length > "jdbc:sqlite:".Length Then
						Dim Temp As String = JdbcUrl.SubString("jdbc:sqlite:".Length)
					End If
						
					If Temp = DBFile Then
						DBDir = File.DirApp
					Else
						DBFile = File.GetName(Temp)
						DBDir = Temp.Replace($"/${DBFile}"$, "")
					End If
						
					If File.Exists(DBDir, "") = False Then
						File.MakeDir(DBDir, "")
					End If
					DB.Initialize(DriverClass, JdbcUrl)
				Else
					If DBDir = "" Then DBDir = File.DirApp
					If DBFile = "" Then DBFile = "data.db"
					DB.InitializeSQLite(DBDir, DBFile, True)
				End If
			Case "MYSQL", "SQL SERVER", "FIREBIRD", "POSTGRESQL"
				DB.Initialize2(DriverClass, JdbcUrl, User, Password)
			Case "DBF"
				DB.Initialize(Conn.DriverClass, Conn.JdbcUrl)
				H2.Initialize(Conn2.DriverClass, Conn2.JdbcUrl)
		End Select
		#End If
		Return DB
	#End If
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
			Case "SQLITE"
				Dim qry As String = $"SELECT datetime(datetime('now'))"$
			Case "MYSQL"
				Dim qry As String = $"SELECT now()"$
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
			Case "SQLITE"
				Dim qry As String = $"SELECT datetime(datetime('now'))"$
			Case "MYSQL"
				Dim qry As String = $"SELECT now()"$
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
		Case "SQLITE"
			Dim qry As String = "SELECT LAST_INSERT_ROWID()"
		Case "MYSQL"
			Dim qry As String = "SELECT LAST_INSERT_ID()"
		Case "SQL SERVER"
			Dim qry As String = "SELECT SCOPE_IDENTITY()"
		Case "FIREBIRD"
			Dim qry As String = "SELECT PK"
		Case "POSTGRESQL"
			Dim qry As String = "SELECT LASTVAL()"
		Case Else
			Dim qry As String = "SELECT 0"
	End Select
	Return qry
End Sub