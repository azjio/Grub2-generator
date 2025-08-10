
; mk-soft
; https://www.purebasic.fr/english/viewtopic.php?f=12&t=71693

; урезанная версия, без мак-ос, только линукс

EnableExplicit


DeclareModule RunAsAdmin
  Declare Login()
EndDeclareModule

Module RunAsAdmin

 
  CompilerSelect #PB_Compiler_OS

    CompilerCase #PB_OS_Linux
     
      Global WinLogin
      Global Label_Prog, Text_Program, Label_User, Label_Passwd, String_User, String_Passwd, Button_Ok
     
      ; -------------------------------------------------------------------------------
     
      Procedure OpenWinLogin(x = 100, y = 100, width = 420, height = 180)
        WinLogin = OpenWindow(#PB_Any, x, y, width, height, "Login", #PB_Window_SystemMenu)
        Label_Prog = TextGadget(#PB_Any, 10, 10, 90, 25, "Program:")
        Text_Program = TextGadget(#PB_Any, 110, 10, 300, 25, "")
        Label_User = TextGadget(#PB_Any, 10, 50, 90, 25, "User:")
        Label_Passwd = TextGadget(#PB_Any, 10, 80, 90, 25, "Password:")
        String_User = StringGadget(#PB_Any, 110, 50, 300, 25, "")
        String_Passwd = StringGadget(#PB_Any, 110, 80, 300, 25, "", #PB_String_Password)
        Button_Ok = ButtonGadget(#PB_Any, 310, 130, 100, 30, "Ok")
      EndProcedure
     
      ; -------------------------------------------------------------------------------
     
      Procedure _Login()
        Protected cmd.s, program.s
       
        program = GetFilePart(ProgramFilename())
        ; pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY PROGRAM_TO_RUN
        cmd = "-c " + #DQUOTE$ + "pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY " + ProgramFilename() + " 1" + #DQUOTE$
        If RunProgram("bash", cmd, "", #PB_Program_Wait)
          End
        Else
          MessageRequester("Error", "Execute With Privileges!", #PB_MessageRequester_Error)
          End
        EndIf
       
      EndProcedure
     
      ; -------------------------------------------------------------------------------
     
      Procedure _LoginSuDo()
        Protected user.s, passwd.s, cmd.s
       
        OpenWinLogin()
        SetGadgetText(Text_Program, GetFilePart(ProgramFilename()))
        SetGadgetText(String_User, UserName())
       
        Repeat
          Select WaitWindowEvent()
            Case #PB_Event_CloseWindow
              End
            Case #PB_Event_Gadget
              If EventGadget() = Button_Ok
                Break
              EndIf
          EndSelect
        ForEver
        user = GetGadgetText(String_User)
        passwd = GetGadgetText(String_Passwd)
        CloseWindow(WinLogin)
       
        If user = UserName()
          cmd.s = "-c " + #DQUOTE$ + "echo " + passwd + " | sudo -S " + ProgramFilename() + " 1" + #DQUOTE$
        Else
          cmd.s = "-c " + #DQUOTE$ + "echo " + passwd + " | sudo -u " + user + " -S " + ProgramFilename() + " 1" + #DQUOTE$
        EndIf
        If RunProgram("bash", cmd, "")
          End
        Else
          MessageRequester("Error", "Execute With Privileges!", #PB_MessageRequester_Error)
          End
        EndIf
       
      EndProcedure

     
  CompilerEndSelect
 
  ; -----------------------------------------------------------------------------------
 
  Procedure Login()
    If CountProgramParameters() = 0
      ProcedureReturn _Login()
    Else
      ProcedureReturn #True
    EndIf
  EndProcedure
 
  ; -----------------------------------------------------------------------------------
 
EndModule

; IDE Options = PureBasic 5.70 LTS (Linux - x64)
; CursorPosition = 4
; Folding = --
; EnableXP