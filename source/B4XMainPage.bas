B4A=true
Group=App
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Macro: Title, GetLibraries, ide://run?file=%JAVABIN%\java.exe&args=-jar&args=%ADDITIONAL%\..\B4X\libget.jar&args=%PROJECT%&args=false
#Macro: Title, Export, ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip
Sub Class_Globals
	Private xui As XUI
	Private DB As MiniORM
	Private MS As ORMSettings
	Private Root As B4XView
	Private lblBack As B4XView
	Private lblCode As B4XView
	Private lblName As B4XView
	Private lblPrice As B4XView
	Private lblTitle As B4XView
	Private lblStatus As B4XView
	Private lblCategory As B4XView
	Private btnNew As B4XView
	Private btnEdit As B4XView
	Private btnDelete As B4XView
	Private Image As B4XImageView
	Private clvRecord As CustomListView
	Private PrefDialog1 As PreferencesDialog
	Private PrefDialog2 As PreferencesDialog
	Private PrefDialog3 As PreferencesDialog
	Private Viewing As String
	Private CategoryId As Int
	Private Category() As Category
	Private Const COLOR_RED As Int = -65536
	Private Const COLOR_BLUE As Int = -16776961
	Private Const COLOR_MAGENTA As Int = -65281
	Private Const COLOR_ADD As Int = -13447886
	Private Const COLOR_EDIT As Int = -12490271
	Private Const COLOR_DELETE As Int = -2354116
	Private Const COLOR_TRANSPARENT As Int = 0
	Private Const COLOR_OVERLAY As Int = -2147481048
	Type Category (Id As Int, Name As String)
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")
	B4XPages.SetTitle(Me, "MiniORM")
	ConfigureDatabase
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	If xui.IsB4A Then
		'back key in Android
		If PrefDialog1.BackKeyPressed Then Return False
		If PrefDialog2.BackKeyPressed Then Return False
		If PrefDialog3.BackKeyPressed Then Return False
	End If
	If xui.IsB4J Then
		If PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Close(xui.DialogResponse_Negative)
		If PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Close(xui.DialogResponse_Negative)
		If PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Close(xui.DialogResponse_Negative)
	End If
	If Viewing = "Product" Then
		GetCategories
		Return False
	End If
	DB.Close
	Return True
End Sub

Private Sub B4XPage_Appear

End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If PrefDialog1.IsInitialized And PrefDialog1.Dialog.Visible Then PrefDialog1.Dialog.Resize(Width, Height)
	If PrefDialog2.IsInitialized And PrefDialog2.Dialog.Visible Then PrefDialog2.Dialog.Resize(Width, Height)
	If PrefDialog3.IsInitialized And PrefDialog3.Dialog.Visible Then PrefDialog3.Dialog.Resize(Width, Height)
End Sub

'Don't miss the code in the Main module + manifest editor.
Private Sub IME_HeightChanged (NewHeight As Int, OldHeight As Int)
	PrefDialog1.KeyboardHeightChanged(NewHeight)
	PrefDialog2.KeyboardHeightChanged(NewHeight)
	PrefDialog3.KeyboardHeightChanged(NewHeight)
End Sub

#If B4J
Private Sub lblBack_MouseClicked (EventData As MouseEvent)
	GetCategories
End Sub
#Else
Private Sub lblBack_Click
	GetCategories
End Sub
#End If

Private Sub clvRecord_ItemClick (Index As Int, Value As Object)
	If Viewing = "Category" Then
		CategoryId = Value
		GetProducts
	End If
End Sub

Private Sub btnNew_Click
	If Viewing = "Product" Then
		Dim ProductMap As Map = CreateMap("Product Code": "", "Category": GetCategoryName(CategoryId), "Product Name": "", "Product Price": "", "id": 0)
		ShowDialog2("Add", ProductMap)
	Else
		Dim CategoryMap As Map = CreateMap("Category Name": "", "id": 0)
		ShowDialog1("Add", CategoryMap)
	End If
End Sub

Private Sub btnEdit_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim ProductId As Int = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		#If B4i
		Dim v2 As B4XView = pnl.GetView(1).GetView(0) ' using panel
		#Else
		Dim v2 As B4XView = pnl.GetView(1)
		#End If
		Dim v3 As B4XView = pnl.GetView(2)
		Dim v4 As B4XView = pnl.GetView(3)
		Dim ProductMap As Map = CreateMap("Product Code": v1.Text, "Category": v2.Text, "Product Name": v3.Text, "Product Price": v4.Text.Replace(",", ""), "id": ProductId)
		ShowDialog2("Edit", ProductMap)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim pnl As B4XView = lst.GetView(0)
		Dim v1 As B4XView = pnl.GetView(0)
		Dim CategoryMap As Map = CreateMap("Category Name": v1.Text, "id": CategoryId)
		ShowDialog1("Edit", CategoryMap)
	End If
End Sub

Private Sub btnDelete_Click
	Dim Index As Int = clvRecord.GetItemFromView(Sender)
	Dim Id As Int = clvRecord.GetValue(Index)
	Dim lst As B4XView = clvRecord.GetPanel(Index)
	Dim pnl As B4XView = lst.GetView(0)
	If Viewing = "Product" Then
		If CategoryId = 0 Then Return
		Dim v1 As B4XView = pnl.GetView(2)
	Else
		CategoryId = clvRecord.GetValue(Index)
		Dim v1 As B4XView = pnl.GetView(0)
	End If
	Dim M1 As Map
	M1.Initialize
	M1.Put("Item", v1.Text)
	ShowDialog3(M1, Id)
End Sub

Public Sub ConfigureDatabase
	MS.Initialize
	#If MySQL
		MS.DBType = "MySQL"
		MS.JdbcUrl = "jdbc:mysql://{DbHost}:{DbPort}/{DbName}?characterEncoding=utf8&useSSL=False"
		MS.DriverClass = "com.mysql.cj.jdbc.Driver"
	#Else If MariaDB
		MS.DBType = "MariaDB"
		MS.JdbcUrl = "jdbc:mariadb://{DbHost}:{DbPort}/{DbName}"
		MS.DriverClass = "org.mariadb.jdbc.Driver"
	#Else
	MS.DBType = "SQLite"
	MS.DBFile = "Data.db"
	#If B4J
	MS.DBDir = File.DirApp
	#Else
	MS.DBDir = xui.DefaultFolder
	#End If
	#End If
	#If MySQL Or MariaDB
		MS.DBName = "miniorm"
		MS.DbHost = "localhost"
		MS.User = "root"
		MS.Password = "password"
	#End If
	Try
		DB.Initialize
		DB.Settings = MS
		DB.ShowExtraLogs = True
		#If MySQL Or MariaDB
		Wait For (DB.ExistAsync) Complete (DbFound As Boolean)
		#Else
		Dim DbFound As Boolean = DB.Exist
		#End If
		If DbFound Then
			LogColor($"${MS.DBType} database found!"$, COLOR_BLUE)
			#If MySQL Or MariaDB
			DB.InitPool
			#End If
			'File.Delete(MS.DBDir, MS.DBFile)
			DB.Open
			GetCategories
		Else
			LogColor($"${MS.DBType} database not found!"$, COLOR_RED)
			CreateDatabase
		End If
	Catch
		Log(LastException.Message)
		LogColor("Error checking database!", COLOR_RED)
		Log("Application is terminated.")
		#If B4J
		ExitApplication
		#End If
	End Try
End Sub

Private Sub CreateDatabase
	LogColor("Creating database...", COLOR_MAGENTA)
	DB.Initialize
	DB.Settings = MS
	#If MySQL Or MariaDB
	Wait For (DB.CreateDatabaseAsync) Complete (Success As Boolean)
	#Else
	Dim Success As Boolean = DB.InitializeSQLite
	#End If
	If Not(Success) Then
		Log("Database creation failed!")
		Return
	End If

	DB.Open
	DB.ShowExtraLogs = True
	'DB.UseTimestamps = True
	DB.QueryAddToBatch = True
	
	DB.Table = "tbl_categories"
	DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "category_name")))
	DB.Create
	
	DB.Columns = Array("category_name")
	DB.Insert2(Array("Hardwares"))
	DB.Insert2(Array("Toys"))

	DB.Table = "tbl_products"
	DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "category_id", "Type": DB.INTEGER)))
	DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "product_code", "Size": 12)))
	DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "product_name")))
	DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "product_price", "Type": DB.DECIMAL, "Size": "10,2", "Default": 0.0)))
	'DB.BLOB = "longblob"
	DB.Columns.Add(DB.CreateColumn2(CreateMap("Name": "product_image", "Type": DB.BLOB)))
	DB.Foreign("category_id", "id", "tbl_categories", "", "")
	DB.Create
	
	DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
	DB.Insert2(Array(2, "T001", "Teddy Bear", 99.9))
	DB.Insert2(Array(1, "H001", "Hammer", 15.75))
	DB.Insert2(Array(2, "T002", "Optimus Prime", 1000))

	Wait For (DB.ExecuteBatchAsync) Complete (Success As Boolean)
	If Success Then
		LogColor("Database is created successfully!", COLOR_BLUE)
	Else
		LogColor("Database creation failed!", COLOR_RED)
		Log(LastException.Message)
	End If
	
	' Adding an image to blob field
	Dim b() As Byte = File.ReadBytes(File.DirAssets, "icon.png")
	DB.Table = "tbl_products"
	DB.Columns = Array("product_image")
	DB.Parameters = Array(b)
	DB.Id = 3 ' after setting Columns and Parameters
	DB.Save
	
	GetCategories
End Sub

Private Sub GetCategories
	Try
		DB.Table = "tbl_categories"
		DB.Query
		Dim Items As List = DB.Results
		Dim Category(Items.Size) As Category
		For i = 0 To Items.Size - 1
			Dim Item As Map = Items.Get(i)
			Category(i).Id = Item.Get("id")
			Category(i).Name = Item.Get("category_name")
		Next
		clvRecord.Clear
		For i = 0 To Category.Length - 1
			clvRecord.Add(CreateCategoryItems(Category(i).Name, clvRecord.AsView.Width), Category(i).Id)
		Next
		Viewing = "Category"
		lblTitle.Text = "Category"
		lblBack.Visible = False
		CreateDialog1
		CreateDialog2
		CreateDialog3
	Catch
		xui.MsgboxAsync(LastException.Message, "Error")
	End Try
End Sub

Private Sub GetProducts
	clvRecord.Clear
	DB.Table = "tbl_products p"
	DB.ColumnsType = CreateMap("product_image": DB.BLOB)
	DB.Columns = Array("p.id", "p.product_code", "p.product_name", "p.product_price", "p.product_image", "p.category_id", "c.category_name")
	'DB.Join = DB.CreateJoin("JOIN", "tbl_categories c", "p.category_id = c.id")
	DB.Join("JOIN", "tbl_categories c", "p.category_id = c.id")
	DB.WhereParams(Array("c.id = ?"), Array As Object(CategoryId))
	DB.Query
	Dim Items As List = DB.Results
	'Log(Items.As(JSON).ToString)
	For Each Item As Map In Items
		clvRecord.Add(CreateProductItems(Item.Get("product_code"), GetCategoryName(Item.Get("category_id")), Item.Get("product_name"), NumberFormat2(Item.Get("product_price"), 1, 2, 2, True), clvRecord.AsView.Width), Item.Get("id"))
		'#If Debug
		' Test blob field
		If 3 = Item.Get("id") Then
			Dim buffer() As Byte = Item.GetDefault("product_image", Array As Byte())
			If buffer.Length > 0 Then
				Dim in As InputStream
				in.InitializeFromBytesArray(buffer, 0, buffer.Length)
				Dim bmx As B4XBitmap
				#If B4A or B4i
				Dim bmp As Bitmap
				bmp.Initialize2(in)
				bmx = bmp
			  	#Else If B4J
				Dim img As Image
				img.Initialize2(in)
				bmx = img
				#End If
				in.Close
				Image.Bitmap = bmx
			End If
		Else
			Image.Clear
		End If
		'#End If
	Next
	Viewing = "Product"
	lblTitle.Text = GetCategoryName(CategoryId)
	lblBack.Visible = True
End Sub

Private Sub GetCategoryId (Name As String) As Int
	For i = 0 To Category.Length - 1
		If Category(i).Name = Name Then
			Return Category(i).Id
		End If
	Next
	Return 0
End Sub

Private Sub GetCategoryName (Id As Int) As String
	For i = 0 To Category.Length - 1
		If Category(i).Id = Id Then
			Return Category(i).Name
		End If
	Next
	Return ""
End Sub

Private Sub CreateCategoryItems (Name As String, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 90dip)
	p.LoadLayout("CategoryItem")
	lblName.Text = Name
	Return p
End Sub

Private Sub CreateProductItems (ProductCode As String, CategoryName As String, ProductName As String, ProductPrice As String, Width As Double) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, 180dip)
	p.LoadLayout("ProductItem")
	lblCode.Text = ProductCode
	lblCategory.Text = CategoryName
	lblName.Text = ProductName
	lblPrice.Text = ProductPrice
	Return p
End Sub

Private Sub CreateDialog1
	PrefDialog1.Initialize(Root, "Category", 300dip, 70dip)
	PrefDialog1.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog1.Dialog.TitleBarHeight = 50dip
	PrefDialog1.LoadFromJson(File.ReadString(File.DirAssets, "template_category.json"))
	PrefDialog1.SetEventsListener(Me, "PrefDialog1") '<-- must add to handle events
End Sub

Private Sub CreateDialog2
	Dim categories As List
	categories.Initialize
	For i = 0 To Category.Length - 1
		categories.Add(Category(i).Name)
	Next
	PrefDialog2.Initialize(Root, "Product", 300dip, 250dip)
	PrefDialog2.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog2.Dialog.TitleBarHeight = 50dip
	PrefDialog2.LoadFromJson(File.ReadString(File.DirAssets, "template_product.json"))
	PrefDialog2.SetOptions("Category", categories)
	PrefDialog2.SetEventsListener(Me, "PrefDialog2") '<-- must add to handle events
End Sub

Private Sub CreateDialog3
	PrefDialog3.Initialize(Root, "Delete", 300dip, 70dip)
	PrefDialog3.Theme = PrefDialog3.THEME_LIGHT
	PrefDialog3.Dialog.OverlayColor = COLOR_OVERLAY
	PrefDialog3.Dialog.TitleBarHeight = 50dip
	PrefDialog3.Dialog.TitleBarColor = COLOR_DELETE
	PrefDialog3.AddSeparator("default")
	PrefDialog3.SetEventsListener(Me, "PrefDialog3") '<-- must add to handle events
End Sub

Private Sub PrefDialog1_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog1)
End Sub

Private Sub PrefDialog2_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog2)
End Sub

Private Sub PrefDialog3_BeforeDialogDisplayed (Template As Object)
	AdjustDialogText(PrefDialog3)
End Sub

Private Sub AdjustDialogText (Pref As PreferencesDialog)
	Try
		Dim btnCancel As B4XView = Pref.Dialog.GetButton(xui.DialogResponse_Cancel)
		btnCancel.Width = btnCancel.Width + 20dip
		btnCancel.Left = btnCancel.Left - 20dip
		btnCancel.TextColor = COLOR_RED
		Dim btnOk As B4XView = Pref.Dialog.GetButton(xui.DialogResponse_Positive)
		If btnOk.IsInitialized Then
			btnOk.Width = btnOk.Width + 20dip
			btnOk.Left = btnCancel.Left - btnOk.Width
		End If
	Catch
		Log(LastException.Message)
	End Try
End Sub

Private Sub ShowDialog1 (Action As String, Item As Map)
	If Action = "Add" Then
		PrefDialog1.Dialog.TitleBarColor = COLOR_ADD
	Else
		PrefDialog1.Dialog.TitleBarColor = COLOR_EDIT
	End If
	PrefDialog1.Title = Action & " Category"
	Dim sf As Object = PrefDialog1.ShowDialog(Item, "OK", "CANCEL")
	#If B4J
	Sleep(0)
	PrefDialog1.CustomListView1.sv.Height = PrefDialog1.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#Else
	PrefDialog1.Dialog.Base.Top = 100dip ' Make it lower
	#End If
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If 0 = Item.Get("id") Then ' New row
			DB.Table = "tbl_categories"
			DB.WhereParam("category_name = ?", Item.Get("Category Name"))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Category already exist", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_name")
			DB.Save2(Array As Object(Item.Get("Category Name")))
			xui.MsgboxAsync("New category created!", $"ID: ${DB.First.Get("id")}"$)
		Else
			DB.Table = "tbl_categories"
			DB.Columns = Array("category_name")
			DB.Parameters = Array As Object(Item.Get("Category Name"))
			DB.Id = Item.Get("id")
			DB.Save
			xui.MsgboxAsync("Category updated!", "Edit")
		End If
		GetCategories
	Else
		Return
	End If
End Sub

Private Sub ShowDialog2 (Action As String, Item As Map)
	If Action = "Add" Then
		PrefDialog2.Dialog.TitleBarColor = COLOR_ADD
	Else
		PrefDialog2.Dialog.TitleBarColor = COLOR_EDIT
	End If
	PrefDialog2.Title = Action & " Product"
	Dim sf As Object = PrefDialog2.ShowDialog(Item, "OK", "CANCEL")
	Sleep(0)
	PrefDialog2.CustomListView1.sv.Height = PrefDialog2.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If 0 = Item.Get("id") Then ' New row
			DB.Table = "tbl_products"
			DB.WhereParam("product_code = ?", Item.Get("Product Code"))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Product Code already exist", "Error")
				Return
			End If
			If IsNumber(Item.Get("Product Price")) = False Then
				xui.MsgboxAsync("Product Price must be a number", "Error")
				Return
			End If
			DB.Reset
			DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
			Dim SelectedCategory As Int = GetCategoryId(Item.Get("Category"))
			DB.Save2(Array As Object(SelectedCategory, Item.Get("Product Code"), Item.Get("Product Name"), Item.Get("Product Price")))
			CategoryId = SelectedCategory
			xui.MsgboxAsync("New product created!", $"ID: ${DB.First.Get("id")}"$)
		Else
			DB.Table = "tbl_products"
			DB.WhereParams(Array("product_code = ?", "id <> ?"), Array As Object(Item.Get("Product Code"), Item.Get("id")))
			DB.Query
			If DB.Found Then
				xui.MsgboxAsync("Product Code already exist", "Error")
				Return
			End If
			If IsNumber(Item.Get("Product Price")) = False Then
				xui.MsgboxAsync("Product Price must be a number", "Error")
				Return
			End If
			DB.Reset
			Dim NewCategoryId As Int = GetCategoryId(Item.Get("Category"))
			DB.Columns = Array("category_id", "product_code", "product_name", "product_price")
			DB.Parameters = Array As Object(NewCategoryId, Item.Get("Product Code"), Item.Get("Product Name"), Item.Get("Product Price"))
			DB.Id = Item.Get("id")
			DB.Save
			xui.MsgboxAsync("Product updated!", "Edit")
			CategoryId = NewCategoryId
		End If
		GetProducts
	Else
		Return
	End If
End Sub

Private Sub ShowDialog3 (Item As Map, Id As Int)
	PrefDialog3.Title = "Delete " & Viewing
	Dim sf As Object = PrefDialog3.ShowDialog(Item, "OK", "CANCEL")
	#If B4J
	Sleep(0)
	PrefDialog3.CustomListView1.sv.Height = PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Height + 10dip
	#Else
	PrefDialog3.Dialog.Base.Top = 100dip ' Make it lower
	#End If
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Text = Item.Get("Item")
	#If B4i
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 16 ' Text too small in ios
	#Else
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).TextSize = 15 ' 14
	#End If
	PrefDialog3.CustomListView1.GetPanel(0).GetView(0).Color = COLOR_TRANSPARENT
	PrefDialog3.CustomListView1.sv.ScrollViewInnerPanel.Color = COLOR_TRANSPARENT
	Wait For (sf) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If Viewing = "Product" Then
			DB.Table = "tbl_products"
		Else
			DB.Table = "tbl_categories"
		End If
		DB.Find(Id)
		If DB.Found Then
			DB.Reset
			DB.Id = Id
			DB.Delete
			xui.MsgboxAsync(Viewing &" deleted successfully", "Delete")
		Else
			xui.MsgboxAsync(Viewing & " not found", "Error")
		End If
	Else
		Return
	End If
	If Viewing = "Product" Then
		GetProducts
	Else
		GetCategories
	End If
End Sub