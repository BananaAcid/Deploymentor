If WScript.Arguments.Count = 0 Then
    WScript.Echo "Error: Missing parameters"
    WScript.Quit 1 ' Exit with an error code
End If

' Get the first and second parameters
Dim param1, param2
param1 = WScript.Arguments(0)
If WScript.Arguments.Count > 1 Then
    param2 = WScript.Arguments(1)
End If

' Display the parameters
WScript.Echo "Parameter 1: " & param1
WScript.Echo "Parameter 2: " & param2


MsgBox("Hello, World!")