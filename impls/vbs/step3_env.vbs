Option Explicit

Include "Types.vbs"
Include "Reader.vbs"
Include "Printer.vbs"
Include "Env.vbs"

Dim objEnv
Set objEnv = NewEnv(Nothing)

Function MAdd(objArgs)
	CheckArgNum objArgs, 2
	Set MAdd = NewMalNum( _
		objArgs.Item(1).Value + objArgs.Item(2).Value)
End Function
objEnv.Add NewMalSym("+"), NewVbsProc("MAdd", False)

Function MSub(objArgs)
	CheckArgNum objArgs, 2
	Set MSub = NewMalNum( _
		objArgs.Item(1).Value - objArgs.Item(2).Value)
End Function
objEnv.Add NewMalSym("-"), NewVbsProc("MSub", False)

Function MMul(objArgs)
	CheckArgNum objArgs, 2
	Set MMul = NewMalNum( _
		objArgs.Item(1).Value * objArgs.Item(2).Value)
End Function
objEnv.Add NewMalSym("*"), NewVbsProc("MMul", False)

Function MDiv(objArgs)
	CheckArgNum objArgs, 2
	Set MDiv = NewMalNum( _
		objArgs.Item(1).Value \ objArgs.Item(2).Value)
End Function
objEnv.Add NewMalSym("/"), NewVbsProc("MDiv", False)

Sub CheckArgNum(objArgs, lngArgNum)
	If objArgs.Count - 1 <> lngArgNum Then
		Err.Raise vbObjectError, _
			"CheckArgNum", "Wrong number of arguments."
	End IF
End Sub

Sub CheckType(objMal, varType)
	If objMal.Type <> varType Then
		Err.Raise vbObjectError, _
			"CheckType", "Wrong argument type."
	End IF
End Sub

Function MDef(objArgs, objEnv)
	Dim varRet
	CheckArgNum objArgs, 2
	CheckType objArgs.Item(1), TYPES.SYMBOL
	Set varRet = Evaluate(objArgs.Item(2), objEnv)
	objEnv.Add objArgs.Item(1), varRet
	Set MDef = varRet
End Function
objEnv.Add NewMalSym("def!"), NewVbsProc("MDef", True)

Function MLet(objArgs, objEnv)
	Dim varRet
	CheckArgNum objArgs, 2

	Dim objBinds
	Set objBinds = objArgs.Item(1)
	If objBinds.Type <> TYPES.LIST And _
		objBinds.Type <> TYPES.VECTOR Then
		Err.Raise vbObjectError, _
			"MLet", "Wrong argument type."
	End If
	
	If objBinds.Count Mod 2 <> 0 Then
		Err.Raise vbObjectError, _
			"MLet", "Wrong argument count."
	End If

	Dim objNewEnv
	Set objNewEnv = NewEnv(objEnv)
	Dim i, objSym
	For i = 0 To objBinds.Count - 1 Step 2
		Set objSym = objBinds.Item(i)
		CheckType objSym, TYPES.SYMBOL
		objNewEnv.Add objSym, Evaluate(objBinds.Item(i + 1), objNewEnv)
	Next

	Set varRet = Evaluate(objArgs.Item(2), objNewEnv)
	Set MLet = varRet
End Function
objEnv.Add NewMalSym("let*"), NewVbsProc("MLet", True)

Call REPL()
Sub REPL()
	Dim strCode, strResult
	While True
		WScript.StdOut.Write("user> ")

		On Error Resume Next
			strCode = WScript.StdIn.ReadLine()
			If Err.Number <> 0 Then WScript.Quit 0
		On Error Goto 0

		'On Error Resume Next
			WScript.Echo REP(strCode)
			If Err.Number <> 0 Then
				WScript.StdErr.WriteLine Err.Source + ": " + Err.Description 
			End If
		On Error Goto 0
	Wend
End Sub

Function Read(strCode)
	Set Read = ReadString(strCode)
End Function

Function Evaluate(objCode, objEnv) ' Return Nothing / objCode
	If TypeName(objCode) = "Nothing" Then
		Set Evaluate = Nothing
		Exit Function
	End If
	Dim varRet
	If objCode.Type = TYPES.LIST Then
		If objCode.Count = 0 Then ' ()
			Set Evaluate = objCode
			Exit Function
		End If
		Set objCode.Item(0) = Evaluate(objCode.Item(0), objEnv)
		Set varRet = objCode.Item(0).Apply(objCode, objEnv)
	Else
		Set varRet = EvaluateAST(objCode, objEnv)
	End If

	Set Evaluate = varRet
End Function


Function EvaluateAST(objCode, objEnv)
	Dim varRet, i
	Select Case objCode.Type
		Case TYPES.SYMBOL
			Set varRet = objEnv.Get(objCode)
		Case TYPES.LIST
			Err.Raise vbObjectError, _
				"EvaluateAST", "Unexpect type."
		Case TYPES.VECTOR
			For i = 0 To objCode.Count() - 1
				Set objCode.Item(i) = Evaluate(objCode.Item(i), objEnv)
			Next
			Set varRet = objCode
		Case TYPES.HASHMAP
			For Each i In objCode.Keys()
				Set objCode.Item(i) = Evaluate(objCode.Item(i), objEnv)
			Next
			Set varRet = objCode
		Case Else
			Set varRet = objCode
	End Select
	Set EvaluateAST = varRet
End Function

Function EvaluateRest(objCode, objEnv)
	Dim varRet, i
	Select Case objCode.Type
		Case TYPES.LIST
			For i = 1 To objCode.Count() - 1
				Set objCode.Item(i) = Evaluate(objCode.Item(i), objEnv)
			Next
			Set varRet = objCode
		Case Else
			Err.Raise vbObjectError, _
				"EvaluateRest", "Unexpected type."
	End Select
	Set EvaluateRest = varRet
End Function

Function Print(objCode)
	Print = PrintMalType(objCode, True)
End Function

Function REP(strCode)
	REP = Print(Evaluate(Read(strCode), objEnv))
End Function

Sub Include(strFileName)
	With CreateObject("Scripting.FileSystemObject")
		ExecuteGlobal .OpenTextFile( _
			.GetParentFolderName( _
			.GetFile(WScript.ScriptFullName)) & _
			"\" & strFileName).ReadAll
	End With
End Sub








' Function Read(strCode)
' 	Set Read = ReadString(strCode)
' End Function

' Function Evaluate(objCode, objEnv)
' 	Dim i
' 	If TypeName(objCode) = "Nothing" Then
' 		Call REPL()
' 	End If
	
' 	If objCode.Type = TYPE_LIST Then
' 		If objCode.Value.Count = 0 Then
' 			Set Evaluate = objCode
' 			Exit Function
' 		End If
		
' 		Dim objSymbol
' 		Set objSymbol = Evaluate(objCode.Value.Item(0), objEnv)
' 		If TypeName(objSymbol) = "MalType" Then
' 			'MsgBox TypeName(objCode.value)
' 			Select Case objSymbol.Value
' 				Case "def!"
' 					CheckArgNum objCode, 2
' 					CheckSymbol objCode.Value.Item(1)
' 					'MsgBox 2
' 					objEnv.Add objCode.Value.Item(1).Value, _
' 						Evaluate(objCode.Value.Item(2), objEnv)
' 					'MsgBox 3
' 					Set Evaluate = objEnv.Get(objCode.Value.Item(1).Value)
' 				Case "let*"
' 					Dim objNewEnv
' 					Set objNewEnv = New Environment
' 					objNewEnv.SetSelf objNewEnv
' 					objNewEnv.SetOuter objEnv
' 					CheckArgNum objCode, 2
' 					CheckListOrVector objCode.Value.Item(1)
' 					CheckEven objCode.Value.Item(1).Value.Count
' 					With objCode.Value.Item(1).Value
' 						For i = 0 To .Count - 1 Step 2
' 							CheckSymbol .Item(i)
' 							objNewEnv.Add .Item(i).Value, _
' 								Evaluate(.Item(i + 1), objNewEnv)
' 						Next
' 					End With
' 					Set Evaluate = Evaluate(objCode.Value.Item(2), objNewEnv)
' 			End Select
' 		Else
' 			Set Evaluate = objSymbol(EvaluateAST(objCode, objEnv))
' 		End If
' 	Else
' 		Set Evaluate = EvaluateAST(objCode, objEnv)
' 	End If
' End Function

' Sub CheckEven(lngNum)
' 	If lngNum Mod 2 <> 0 Then
' 		boolError = True
' 		strError = "not a even number"
' 		Call REPL()
' 	End If	
' End Sub

' Sub CheckList(objMal)
' 	If objMal.Type <> TYPE_LIST Then
' 		boolError = True
' 		strError = "neither a list nor a vector"
' 		Call REPL()
' 	End If
' End Sub

' Sub CheckListOrVector(objMal)
' 	If objMal.Type <> TYPE_LIST And objMal.Type <> TYPE_VECTOR Then
' 		boolError = True
' 		strError = "not a list"
' 		Call REPL()
' 	End If
' End Sub

' Sub CheckSymbol(objMal)
' 	If objMal.Type <> TYPE_SYMBOL Then
' 		boolError = True
' 		strError = "not a symbol"
' 		Call REPL()
' 	End If
' End Sub

' Function EvaluateAST(objCode, objEnv)
' 	If TypeName(objCode) = "Nothing" Then
' 		MsgBox "Nothing2"
' 	End If
	
' 	Dim objResult, i
' 	Select Case objCode.Type
' 		Case TYPE_SYMBOL
' 			Select Case objCode.Value
' 				Case "def!"
' 					Set objResult = objCode
' 				Case "let*"
' 					Set objResult = objCode
' 				Case Else
' 					Set objResult = objEnv.Get(objCode.Value)	
' 			End Select
' 		Case TYPE_LIST
' 			For i = 0 To objCode.Value.Count - 1
' 				Set objCode.Value.Item(i) = Evaluate(objCode.Value.Item(i), objEnv)
' 			Next
' 			Set objResult = objCode
' 		Case TYPE_VECTOR
' 			For i = 0 To objCode.Value.Count - 1
' 				Set objCode.Value.Item(i) = Evaluate(objCode.Value.Item(i), objEnv)
' 			Next
' 			Set objResult = objCode
' 		Case TYPE_HASHMAP
' 			Dim arrKeys
' 			arrKeys = objCode.Value.Keys
' 			For i = 0 To objCode.Value.Count - 1
' 				Set objCode.Value.Item(arrKeys(i)) = _
' 					Evaluate(objCode.Value.Item(arrKeys(i)), objEnv)
' 			Next
' 			Set objResult = objCode
' 		Case Else
' 			Set objResult = objCode
' 	End Select
' 	Set EvaluateAST = objResult
' End Function

' Function Print(objCode)
' 	Print = PrintMalType(objCode, True)
' End Function

' Function REP(strCode)
' 	REP = Print(Evaluate(Read(strCode), objEnv))
' End Function

' Sub Include(strFileName)
' 	With CreateObject("Scripting.FileSystemObject")
' 		ExecuteGlobal .OpenTextFile( _
' 			.GetParentFolderName( _
' 			.GetFile(WScript.ScriptFullName)) & _
' 			"\" & strFileName).ReadAll
' 	End With
' End Sub