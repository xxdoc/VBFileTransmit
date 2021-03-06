VERSION 5.00
Object = "{248DD890-BB45-11CF-9ABC-0080C7E7B78D}#1.0#0"; "mswinsck.ocx"
Object = "{BD0C1912-66C3-49CC-8B12-7B347BF6C846}#15.3#0"; "Codejock.SkinFramework.v15.3.1.ocx"
Begin VB.Form frmFTServer 
   Caption         =   "FTServer"
   ClientHeight    =   3210
   ClientLeft      =   120
   ClientTop       =   450
   ClientWidth     =   7035
   Icon            =   "frmFTServer.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   3210
   ScaleWidth      =   7035
   StartUpPosition =   2  '屏幕中心
   Begin VB.CommandButton Command2 
      Caption         =   "Command2"
      Height          =   495
      Left            =   4800
      TabIndex        =   10
      Top             =   2400
      Width           =   1095
   End
   Begin FTServer.LabelProgressBar LabelProgressBar1 
      Height          =   375
      Left            =   3600
      TabIndex        =   9
      Top             =   1440
      Width           =   3255
      _ExtentX        =   5741
      _ExtentY        =   661
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "宋体"
         Size            =   9
         Charset         =   134
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
   Begin VB.CheckBox Check1 
      Caption         =   "最小化隐藏"
      Height          =   180
      Left            =   5640
      TabIndex        =   8
      Top             =   120
      Width           =   1500
   End
   Begin VB.CommandButton Command1 
      Caption         =   "开启服务"
      Height          =   375
      Left            =   4320
      TabIndex        =   7
      Top             =   40
      Width           =   1095
   End
   Begin VB.TextBox Text1 
      Height          =   270
      Left            =   1080
      TabIndex        =   4
      Top             =   80
      Width           =   1095
   End
   Begin VB.ListBox List1 
      Height          =   2580
      Left            =   120
      TabIndex        =   0
      Top             =   600
      Width           =   3135
   End
   Begin VB.Timer Timer1 
      Index           =   0
      Left            =   4560
      Top             =   600
   End
   Begin MSWinsockLib.Winsock Winsock1 
      Index           =   0
      Left            =   5040
      Top             =   600
      _ExtentX        =   741
      _ExtentY        =   741
      _Version        =   393216
   End
   Begin XtremeSkinFramework.SkinFramework SkinFramework1 
      Left            =   5520
      Top             =   600
      _Version        =   983043
      _ExtentX        =   635
      _ExtentY        =   635
      _StockProps     =   0
   End
   Begin VB.Label Label1 
      Height          =   180
      Index           =   4
      Left            =   3480
      TabIndex        =   6
      Top             =   120
      Width           =   800
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "服务状态："
      Height          =   180
      Index           =   3
      Left            =   2520
      TabIndex        =   5
      Top             =   120
      Width           =   900
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "侦听端口："
      Height          =   180
      Index           =   2
      Left            =   120
      TabIndex        =   3
      Top             =   120
      Width           =   900
   End
   Begin VB.Label Label1 
      Caption         =   "0"
      Height          =   180
      Index           =   1
      Left            =   1440
      TabIndex        =   2
      Top             =   360
      Width           =   1770
   End
   Begin VB.Label Label1 
      AutoSize        =   -1  'True
      Caption         =   "当前连接列表："
      Height          =   180
      Index           =   0
      Left            =   120
      TabIndex        =   1
      Top             =   360
      Width           =   1260
   End
   Begin VB.Menu NotifyIconMenu 
      Caption         =   "托盘图标菜单"
      Visible         =   0   'False
      Begin VB.Menu menuShowWindow 
         Caption         =   "显示窗口"
      End
      Begin VB.Menu menuExit 
         Caption         =   "退出"
      End
   End
End
Attribute VB_Name = "frmFTServer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit


Private Const mconstrBar As String = "--"


Private Function mfCloseAllConnect() As Boolean
    Dim ctlSck As MSWinsockLib.Winsock
    
    For Each ctlSck In Winsock1
        If ctlSck.State <> 0 Then
            ctlSck.Close
            gArr(ctlSck.Index) = gArr(0)
            If ctlSck.Index <> 0 Then Unload ctlSck
        End If
    Next
    
    List1.Clear
    Label1.Item(1).Caption = 0
    
End Function

Private Function mfConnect() As Boolean
    With Winsock1.Item(0)
        If Command1.Caption = gVar.ServerStart Then
            Dim strPort As String
            
            strPort = Trim(Text1.Text)
            If Len(strPort) = 0 Then
                strPort = GetSetting(gVar.RegAppName, gVar.RegTcpSection, gVar.RegTcpKeyPort, gVar.TCPPort)
            End If
            strPort = CStr(CLng(Val(strPort)))
            If Val(strPort) > 65535 Or Val(strPort) < 0 Then strPort = gVar.TCPPort
            If strPort <> Text1.Text Then Text1.Text = strPort
            SaveSetting gVar.RegAppName, gVar.RegTcpSection, gVar.RegTcpKeyPort, strPort
            
            If .State <> 0 Then .Close
            .LocalPort = strPort
            .Listen
            Command1.Caption = gVar.ServerClose
            Label1.Item(4).Caption = gVar.ServerStarted
            Label1.Item(4).ForeColor = vbBlue
        Else
            .Close
            Command1.Caption = gVar.ServerStart
            Label1.Item(4).Caption = gVar.ServerNotStarted
            Label1.Item(4).ForeColor = vbRed
            Call mfCloseAllConnect
        End If
    End With
End Function

Private Function mfStartConfirm(ByVal intIndex As Integer) As Boolean
    '防非客户端来连接服务器，启动对应计时器进行反馈检查
    Dim timerCF As Timer
    Dim blnExist As Boolean
    
    If intIndex = 0 Then
        MsgBox "非法传入！", vbCritical, "计时器警告"
        Exit Function
    End If
    For Each timerCF In Timer1
        If timerCF.Index = intIndex Then
            blnExist = True
            Exit For
        End If
    Next
    
    If Not blnExist Then Load Timer1.Item(intIndex)
    Timer1.Item(intIndex).Interval = 1000
    Timer1.Item(intIndex).Enabled = True
    
End Function


Private Function mfVersionCS(ByVal strGetInfo As String, sckSend As MSWinsockLib.Winsock) As Boolean
    '接收到客户端发来版本信息
    Dim strVC As String, strNetFile As String, strVS As String, strCompare As String
    Dim strNewSetupFile As String
                
    strVC = Mid(strGetInfo, Len(gVar.PTVersionOfClient) + 1)
    strNetFile = gVar.AppPath & gVar.ClientExeName
    strVS = gfBackVersion(strNetFile)
    
    strCompare = gfVersionCompare(strVC, strVS)
    If strCompare = "0" Then
        Call gfSendInfo(gVar.PTVersionNotUpdate, sckSend)
    ElseIf strCompare = "1" Then
        Call gfSendInfo(gVar.PTVersionNeedUpdate & strVS, sckSend)
        
        '发送更新文件安装包的信息
        gArr(sckSend.Index) = gArr(0)
        strNewSetupFile = gVar.AppPath & gVar.NewSetupFileName
        If Not gfDirFile(strNewSetupFile) Then
Debug.Print "更新文件发送前异常"
            Exit Function
        End If
        
        With gArr(sckSend.Index)
            .FileFolder = gVar.FolderNameTemp
            .FileName = gVar.NewSetupFileName
            .FilePath = strNewSetupFile
            .FileSizeTotal = FileLen(.FilePath)
        End With
        
        If sckSend.State = 7 Then
            If gfSendInfo(gfFileInfoJoin(sckSend.Index, ftSend), sckSend) Then
Debug.Print "已发送更新包的文件信息"
            End If
        End If
        
    Else
        '版本检测异常
        Call gfSendInfo(gVar.PTVersionNotUpdate & strCompare, sckSend)
Debug.Print "版本检测异常"
        
    End If
    
End Function



Private Sub Command1_Click()
    Const conInterval As Long = 2
    Static sngLastTime As Single
    Dim sngCurTime As Single
    
    sngCurTime = Timer
    If sngCurTime - sngLastTime < conInterval Then
        MsgBox "两次点击时间间隔小于" & conInterval & "秒！", vbExclamation
        Exit Sub
    End If
    sngLastTime = sngCurTime
    
    Call mfConnect
    
End Sub

Private Sub Command2_Click()
'''    Call gfLoadSkin(Me, SkinFramework1, sMS07)
    
    Dim strValue As String
    
''    Call gfRegOperate(HKEY_LOCAL_MACHINE, HKEY_USER_RUN, "aaa", REG_SZ, strValue) 'OK
'    Call gfRegOperate(HKEY_CURRENT_USER, HKEY_USER_RUN, "ctfmon", REG_SZ, strValue) 'OK
'    Call gfRegOperate(HKEY_CURRENT_USER, HKEY_USER_RUN, "ctfmon.exe", REG_SZ, strValue) 'OK
'    Call gfRegOperate(HKEY_CURRENT_USER, HKEY_USER_RUN, "aaa", REG_SZ, strValue) 'OK
'    Call gfRegOperate(HKEY_CURRENT_USER, HKEY_USER_RUN, "aaa", REG_SZ, "1234abc", RegWrite) 'OK
'    Call gfRegOperate(HKEY_CURRENT_USER, HKEY_USER_RUN, "aaa", REG_SZ, strValue, RegDelete) 'OK
'    Call gfRegOperate(HKEY_LOCAL_MACHINE, HKEY_USER_RUN, "aaa", REG_SZ, strValue, RegDelete) 'OK
'    Call gfRegOperate(HKEY_LOCAL_MACHINE, HKEY_USER_RUN, "aaa", REG_SZ, strValue, RegRead)
'    Call gfRegOperate(HKEY_LOCAL_MACHINE, HKEY_USER_RUN, "aaa", REG_SZ, "123中国ABC", RegWrite) 'OK
'''    Call gfRegOperate(HKEY_LOCAL_MACHINE, HKEY_USER_RUN, App.EXEName, REG_SZ) ', strValue)
'''    MsgBox strValue
'''    strValue = """" & gVar.AppPath & App.EXEName & ".exe"""
'''    MsgBox strValue
'    Call gfRegOperate(HKEY_LOCAL_MACHINE, HKEY_USER_RUN, App.EXEName, REG_SZ, strValue, RegWrite)

End Sub

Private Sub Form_Load()
        
    If App.PrevInstance Then
        MsgBox "服务端已打开！", vbExclamation
        Unload Me
        Exit Sub
    End If
    
    Timer1.Item(0).Interval = 1000
    Check1.Value = 1
    
    Call gsInitialize
    Call gfStartUpSet
    Call gfNotifyIconAdd(Me)
    Call gfLoadSkin(Me, SkinFramework1, , True)
    Call mfConnect
    
End Sub

Private Sub Form_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    '处理托盘图标上鼠标事件
    Dim sngMsg As Single
    
    sngMsg = X / Screen.TwipsPerPixelX
    
    Select Case sngMsg
        Case WM_RBUTTONUP
            Call Me.PopupMenu(Me.NotifyIconMenu, , , , Me.menuShowWindow)
        Case WM_LBUTTONDBLCLK
            With Me
                If .WindowState = vbMinimized Then
                    .WindowState = vbNormal
                    .Show
                    .SetFocus
                Else
                    .WindowState = vbMinimized
                End If
            End With
        Case Else
    End Select
    
End Sub

Private Sub Form_Resize()
    If Me.WindowState = vbMinimized Then
        If Check1.Value = 1 Then
            Me.Hide
            Call gfNotifyIconBalloon(Me, "最小化到系统托盘图标啦", "提示")
        End If
    End If
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Call gfNotifyIconDelete(Me)
End Sub

Private Sub menuExit_Click()
    Unload Me
End Sub

Private Sub menuShowWindow_Click()
    Me.WindowState = vbNormal
    Me.Visible = True
End Sub

Private Sub Timer1_Timer(Index As Integer)
    Static stCon As Long
    Static lngConfirmTime As Long
    
    If Index = 0 Then
        If Winsock1.Item(0).State = 2 Then
            If Command1.Caption <> gVar.ServerClose Then
                Command1.Caption = gVar.ServerClose
                Label1.Item(4).Caption = gVar.ServerStarted
                Label1.Item(4).ForeColor = vbBlue
                gVar.TCPServerStarted = True
            End If
        ElseIf Winsock1.Item(0).State = 9 Then
            If Label1.Item(4).Caption <> gVar.ServerError Then
                Command1.Caption = gVar.ServerStart
                Label1.Item(4).Caption = gVar.ServerError
                Label1.Item(4).ForeColor = vbRed
                Call mfCloseAllConnect
                gVar.TCPServerStarted = False
            End If
        Else
            If Label1.Item(4).Caption <> gVar.ServerNotStarted Then
                Command1.Caption = gVar.ServerStart
                Label1.Item(4).Caption = gVar.ServerNotStarted
                Label1.Item(4).ForeColor = vbRed
                Call mfCloseAllConnect
                gVar.TCPServerStarted = False
            End If
        End If
        
        '''当客户端非正常关闭时，连接不会自动断开，此处每隔一段时间检查一次所有连接的状态，不等于7则关闭掉连接
        stCon = stCon + 1
        If stCon > 5 Then
'Debug.Print Winsock1.Count
            Dim sckCon As MSWinsockLib.Winsock
            For Each sckCon In Winsock1
                If sckCon.Index <> 0 Then
                    If sckCon.State <> 7 Then
'Debug.Print "StateErrorIndex:" & sckCon.Index
                        Call Winsock1_Close(sckCon.Index)
                    End If
                End If
            Next
            stCon = 1
        End If
    '''index=0计时器为服务端自身检查用
    
    Else
    '''index>0为各个客户端连接检查用
        Dim sckClose As MSWinsockLib.Winsock
        
        lngConfirmTime = lngConfirmTime + 1
        If lngConfirmTime > gVar.WaitTimeOfConfirm Then
            If Not gArr(Index).Connected Then
                For Each sckClose In Winsock1
                    If sckClose.Index = Index Then
                        Call Winsock1_Close(Index)
                        Exit For
                    End If
                Next
            End If
            lngConfirmTime = 0
            Unload Timer1.Item(Index)
Debug.Print gArr(Index).Connected
        End If
        
    End If
End Sub


Private Sub Winsock1_Close(Index As Integer)
    Dim K As Long
    
    If Index = 0 Then Exit Sub
    If List1.ListCount = 0 Then Exit Sub
    
    For K = 0 To List1.ListCount - 1
        If (InStr(List1.List(K), Winsock1.Item(Index).RemoteHostIP) > 0) _
            And (InStr(List1.List(K), mconstrBar & Winsock1.Item(Index).Tag & mconstrBar) > 0) Then
            List1.RemoveItem K
            Unload Winsock1.Item(Index)
            gArr(Index) = gArr(0)
            Close
            Label1.Item(1).Caption = List1.ListCount
            Exit For
        End If
    Next
    
End Sub

Private Sub Winsock1_ConnectionRequest(Index As Integer, ByVal requestID As Long)
    Dim ctlSck As Winsock
    Dim K As Long
    
    If Index <> 0 Then Exit Sub
    
    For Each ctlSck In Winsock1
        If ctlSck.Index = K Then
            K = K + 1
        Else
            Exit For
        End If
    Next
    
    With Winsock1
        If K = .Count Then ReDim Preserve gArr(K)
        gArr(K) = gArr(0)
        
        Load .Item(K)
        .Item(K).Accept requestID
        .Item(K).Tag = requestID
        
        List1.AddItem .Item(K).RemoteHostIP & mconstrBar & CStr(requestID) & mconstrBar & K
        Label1.Item(1).Caption = List1.ListCount
        
        Call gfSendInfo(gVar.PTClientConfirm, Winsock1.Item(K)) '发送客户端确认信息，如果规定时间内回馈正确则连接持续，否则断开连接
        Call mfStartConfirm(K)  '如果规定时间内回馈正确则连接持续，否则断开连接
        
    End With
    
End Sub

Private Sub Winsock1_DataArrival(Index As Integer, ByVal bytesTotal As Long)
    Dim strGet As String
    Dim byteGet() As Byte
    
    With gArr(Index)
        If Not .FileTransmitState Then
            '字符信息传输状态↓
            
            Winsock1.Item(Index).GetData strGet '接收字符信息
                
            If Not gfRestoreInfo(strGet, Winsock1.Item(Index)) Then
                '文件信息
                
            End If
            
            If InStr(strGet, gVar.PTRealClient) Then    '客户端发回的连接确认
                .Connected = True
                
            ElseIf InStr(strGet, gVar.PTVersionOfClient) > 0 Then
                '接到客户端版本信息
                Call mfVersionCS(strGet, Winsock1.Item(Index))
            
            ElseIf InStr(strGet, gVar.PTFileStart) > 0 Then
                '发送更新包给客户端
                Call gfSendFile(.FilePath, Winsock1.Item(Index))
                
            End If
            
Debug.Print "Server GetInfo:" & strGet, bytesTotal
             '字符信息传输状态↑
             
        Else
            '文件传输状态↓
            
            If .FileNumber = 0 Then
                .FileNumber = FreeFile
                Open .FilePath For Binary As #.FileNumber
            End If
            
            ReDim byteGet(bytesTotal - 1)
            Winsock1.Item(Index).GetData byteGet, vbArray + vbByte
            Put #.FileNumber, , byteGet
            .FileSizeCompleted = .FileSizeCompleted + bytesTotal
            
            If .FileSizeCompleted >= .FileSizeTotal Then
                Close #.FileNumber
                Call gfSendInfo(gVar.PTFileEnd, Winsock1.Item(Index))
                gArr(Index) = gArr(0)
Debug.Print "Server Received Over"
            End If
            
            '文件传输状态↑
            
        End If
    End With
End Sub

Private Sub Winsock1_Error(Index As Integer, ByVal Number As Integer, Description As String, ByVal Scode As Long, ByVal Source As String, ByVal HelpFile As String, ByVal HelpContext As Long, CancelDisplay As Boolean)

    If Index <> 0 Then
        If gArr(Index).FileTransmitState Then   '异常时清空文件传输信息
Debug.Print "ServerWinsockError:" & Index & "--" & Err.Number & "  " & Err.Description
            Close '#gArr(Index).FileNumber
            gArr(Index) = gArr(0)
            
        End If
    End If
    
End Sub

Private Sub Winsock1_SendComplete(Index As Integer)
    
    If Index = 0 Then Exit Sub
    With gArr(Index)
        If .FileTransmitState Then
            If .FileSizeCompleted < .FileSizeTotal Then
                Call gfSendFile(.FilePath, Winsock1.Item(Index))
            Else
                gArr(Index) = gArr(0)
Debug.Print "Send Over"
            End If
        End If
    End With
    
End Sub
