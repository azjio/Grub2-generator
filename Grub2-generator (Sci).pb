;- ● TOP
; AZJIO
; 19.05.2024
; 05.03.2024
; 21.02.2024
; 17.10.2021 — 26.10.2021

; Сделать хоткей Ctrl+F
; Вернуть подсветку невидимого текста

EnableExplicit

;- ● #Constants
#Menu = 0
#File = 0
#q$ = Chr(34)

Enumeration Window
	#Window_0
	#WinInfo
	#WinFind
EndEnumeration


Enumeration RegExp
	#RegExp
	#RegExp1
	#RegExpTmp
EndEnumeration

Enumeration Gadget
	#LV
	#Edit
	#StrField
	#btnSave
	#btnApply
; 	#btnAddSn
	#btnAddClass
; 	#btnDelSn
	#btnOpn
	#btnReOpn
; 	#btnDup
	#btnFind
	#btnReplace
	#btnHDD
	#btnBackup
	#btnDef
	#btnMenu
	
	#txt1
	#txt2
	#strg1
	#strg2
	#btnReplaceAll
	#btnCount
	#chCase
	#chFindItem
	#chFindClass
	#chFindCode
	#StatusBar
	
	#btnlsblk
	#Edit2
	#btnblkid
	#btnLast
EndEnumeration

Enumeration Menu
	#mAdd
	#mDel
	#mDupl
	#mRename
	#mNext
	#mFind
	#mReplace
	#mSave
	#mSvTmp
	#mPath1
	#mPath2
EndEnumeration

Structure MenuEntryList
	Name.s
	Class.s
	Code.s
EndStructure

;- ● Declare
Declare AddItemList(ind)
Declare AddItemList0()
Declare.s GetSelText()
Declare SaveToFile()
Declare FindText()
Declare WinFind()
Declare HighlightSelection()
Declare DupItemList()
Declare SaveBackup()
Declare SaveToTemplate()
Declare OpnGrubcfg()
Declare GetDriveInfo()
Declare WinInfo()
Declare Limit(*Value.integer, Min, Max)
Declare.s RgExReplace2(RgEx, Text$, Replacement$)
Declare SelItem(idx)
Declare SetChangeFlag()

Declare Color(*regex, regexLength, n)
Declare Color2(*regex, regexLength, n)
Declare MakeUTF8Text(text.s)
Declare MakeScintillaText(text.s, *sciLength.Integer=0)
Declare SciNotification(Gadget, *scinotify.SCNotification)
Declare SplitL(String.s, List StringList.s(), Separator.s = " ")
Declare Color3(KeyStr$, Lexeme, EndPos0, txtLen)
; Declare Color_indicator(*regex, regexLength, EndPos)


;- ● Global
Global PathGrubcfg$, Text$, tmp, tmp2, idx, idx0, tmp$, *Point, isNotFind
Global PathTemplate$
Global PathTmp$
Global CRLF$ = #CRLF$
Global NewList MenuEntryList.MenuEntryList()
Global flgHSel, IsOpenSection
Global needsave
Global needsaveTotal, needsaveTotalRe = 1

; Если нет секции Set, то нужны умолчальные fm$ и editor$
CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		Define fm$     = "explorer.exe"
		Define editor$ = "notepad.exe"
	CompilerCase #PB_OS_Linux
		Define fm$     = "xdg-open"
		Define editor$ = "xdg-open"
CompilerEndSelect


UseGIFImageDecoder()


CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		CompilerIf #PB_Compiler_Debugger
			; 			Приходится указывать прямой путь
			PathGrubcfg$ = "C:\Temp\grub.cfg"
		CompilerElse
			PathGrubcfg$ = GetPathPart(ProgramFilename()) + "grub.cfg"
		CompilerEndIf
	CompilerCase #PB_OS_Linux
		PathGrubcfg$ = "/boot/grub/grub.cfg"
		If FileSize(PathGrubcfg$) < 0
			PathGrubcfg$ = "/boot/grub2/grub.cfg"
		EndIf
CompilerEndSelect


Global FindText$
Global flgINI = 0
Global ini$, PathConfig$
Global root = 1
Define NewMap ClassINI.s()
Define w3, h3
Define w = 1024
Define h = 600


;- ini
; Проверяем, нет ли папки с настройками рядом с исполняемым файлом, т.е. портабельный вариант
PathConfig$ = GetPathPart(ProgramFilename())
If FileSize(PathConfig$ + "Grub2-generator.ini") = -1
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			PathConfig$ = GetHomeDirectory() + "AppData\Roaming\Grub2-generator\"
		CompilerCase #PB_OS_Linux
			PathConfig$ = GetHomeDirectory() + ".config/Grub2-generator/"
	CompilerEndSelect
EndIf

PathTemplate$ = PathConfig$ + "template" + #PS$
ini$ = PathConfig$ + "Grub2-generator.ini"

If FileSize(ini$) > 3 And OpenPreferences(ini$)
	If PreferenceGroup("Set")
		; 	ini$ = ReadPreferenceString("ini$", ini$)
		h = ReadPreferenceInteger("WinHeight", h)
		w = ReadPreferenceInteger("WinWidth", w)
		root = ReadPreferenceInteger("root", -1)
		editor$ = ReadPreferenceString("editor", editor$)
		fm$     = ReadPreferenceString("fm", fm$)
		tmp = Val("$" + ReadPreferenceString("Sep" , "2550"))
		If tmp > $D7FF And tmp < $20
			tmp = $2550
		EndIf
		ClosePreferences()
	EndIf
	flgINI = 1
EndIf

; попробовать добавить флаг, который определяет как запускать программу, от админа или нет. root=1 и окно "Спрашивать снова?"
; Да - root=1 и запускать от root и больше не спрашивать
; Нет - root=0 и запускать без root и больше не спрашивать
; Отмена - запускать без root и спрашивать при следующем запуске
; или галка "Запомнить выбор"
CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
	; чтобы не напрягать логином во время теста исходника
	CompilerIf  #PB_Compiler_Debugger
	CompilerElse
		
		; 	https://www.purebasic.fr/english/viewtopic.php?f=12&t=71693
		XIncludeFile "RunAsAdmin.pbi"
		If root = 1
			If Not RunAsAdmin::Login()
				; 			MessageRequester("", "Без прав админа сохранение файла станет невозможным.")
				End
			EndIf
		ElseIf root = -1
			Select MessageRequester("Запускать всегда от root?", "Запускать всегда от root? Выбор будет сохранён. " + #CRLF$ + "'Отмена' запускает без root и не сохраняет выбор", #PB_MessageRequester_YesNoCancel)
				Case #PB_MessageRequester_Yes
					If flgINI And OpenPreferences(ini$)
						If PreferenceGroup("Set")
							WritePreferenceInteger("root", 1)
							ClosePreferences()
						EndIf
						flgINI = 1
					EndIf
; эта команда перезапускает исполняемый файл с новыми правами, важно чтобы не было диалогов перед ней
					If Not RunAsAdmin::Login() 
						; 			MessageRequester("", "Без прав админа сохранение файла станет невозможным.")
						End
					EndIf
					root = 1
; 					Debug "сохраняем root = 1"
				Case #PB_MessageRequester_No
					root = 0
; 					Debug "сохраняем root = 0"
; 				Default
; 					Debug "Отмена"
			EndSelect
			If root <> -1 And flgINI And OpenPreferences(ini$)
				If PreferenceGroup("Set")
					WritePreferenceInteger("root", root)
					ClosePreferences()
				EndIf
				flgINI = 1
			EndIf
		EndIf
		
	CompilerEndIf
CompilerEndIf

w3 = w
h3 = h
ExamineDesktops()
Limit(@w, 500, DesktopWidth(0))
Limit(@h, 250, DesktopHeight(0))

Global SepCode$ = Space(12)
ReplaceString(SepCode$, " ", Chr(tmp), #PB_String_InPlace)


; Надо получить позицию и длину группы, чтобы точно сделать замены блоков. При изменении блока изменить позиции на величину изменения длины
; Работать только с памятью, в которой хранится прочитанный файл, чтобы исключить влияние внешним изменением файла.
; 1. В начале menuentry допускается перенос строки и пробельные символы, что исключает закомментированную строку.
; 2. В конце, перед закрывающей фигурной скобкой } допускается перенос строки и пробельные символы, что исключает закомментированную строку.
; 3. Имя пункта может быть в одинарной или двойной кавычке и завершается таким же символом с использованием ссылки на группу \1
; 4. Между именем пункта и открывающей фигурной скобкой { допускается либо ничего, либо строка классов, хоткеев и прочего
; 5. Наборы символов: имя файла, классы сделаны исключающими перенос строки и фигурные скобки

CreateRegularExpression(#RegExp1, "\A\s+\z")
If Not CreateRegularExpression(#RegExp,
           "(?<=[\r\n])\h*menuentry\h+([" + #q$ + "'])([^\r\n{}]+?)\1		(?:\h+([^\r\n{}]+?))?\h*		\{\h*\v*(.+?)		[\r\n]+\s*\}\h*(?=[\r\n])",
          #PB_RegularExpression_DotAll | #PB_RegularExpression_NoCase | #PB_RegularExpression_Extended)

	Debug RegularExpressionError()
	End
EndIf

;- ● Data images
DataSection
	CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
		IconTitle:
		IncludeBinary "icon.gif"
		IconTitleend:
	CompilerEndIf
	Icon1:
	IncludeBinary "images" + #PS$ + "1.gif"
	Icon1end:
	Icon2:
	IncludeBinary "images" + #PS$ + "2.gif"
	Icon2end:
	Icon3:
	IncludeBinary "images" + #PS$ + "3.gif"
	Icon3end:
	Icon4:
	IncludeBinary "images" + #PS$ + "4.gif"
	Icon4end:
	Icon5:
	IncludeBinary "images" + #PS$ + "5.gif"
	Icon5end:
	Icon6:
	IncludeBinary "images" + #PS$ + "6.gif"
	Icon6end:
	Icon7:
	IncludeBinary "images" + #PS$ + "7.gif"
	Icon7end:
	Icon8:
	IncludeBinary "images" + #PS$ + "8.gif"
	Icon8end:
	Icon9:
	IncludeBinary "images" + #PS$ + "9.gif"
	Icon9end:
	Icon10:
	IncludeBinary "images" + #PS$ + "10.gif"
	Icon10end:
	Icon11:
	IncludeBinary "images" + #PS$ + "11.gif"
	Icon11end:
	Icon12:
	IncludeBinary "images" + #PS$ + "12.gif"
	Icon12end:
	Icon13:
	IncludeBinary "images" + #PS$ + "13.gif"
	Icon13end:
	Icon14:
	IncludeBinary "images" + #PS$ + "14.gif"
	Icon14end:
	Icon15:
	IncludeBinary "images" + #PS$ + "15.gif"
	Icon15end:
	Icon16:
	IncludeBinary "images" + #PS$ + "16.gif"
	Icon16end:
	Icon17:
	IncludeBinary "images" + #PS$ + "17.gif"
	Icon17end:
	Icon18:
	IncludeBinary "images" + #PS$ + "18.gif"
	Icon18end:
EndDataSection

CatchImage(1, ?Icon1)
CatchImage(2, ?Icon2)
CatchImage(3, ?Icon3)
CatchImage(4, ?Icon4)
CatchImage(5, ?Icon5)
CatchImage(6, ?Icon6)
CatchImage(7, ?Icon7)
CatchImage(8, ?Icon8)
CatchImage(9, ?Icon9)
CatchImage(10, ?Icon10)
CatchImage(11, ?Icon11)
CatchImage(12, ?Icon12)
CatchImage(13, ?Icon13)
CatchImage(14, ?Icon14)
CatchImage(15, ?Icon15)
CatchImage(16, ?Icon16)
CatchImage(17, ?Icon17)
CatchImage(18, ?Icon18)

CompilerIf #PB_Compiler_Version < 610
If Not InitScintilla()
	MessageRequester("Grub2-generator", "Not Init Scintilla")
	End
EndIf
CompilerEndIf

Global marginWidth, LenTxtSci, regex$, TextLength
Global *SciMemText
Global flgStyle = 0

Define em
Define i


;-┌──GUI──┐
If OpenWindow(#Window_0, 0, 0, w, h, "", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
	CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
		CatchImage(0, ?IconTitle)
		gtk_window_set_icon_(WindowID(#Window_0), ImageID(0)) ; назначаем иконку в заголовке
	CompilerEndIf
	
	ButtonImageGadget(#btnOpn, 10, 5, 28, 28, ImageID(6))
	GadgetToolTip(#btnOpn , "Открыть grub.cfg")
	ButtonImageGadget(#btnSave, 50, 5, 28, 28, ImageID(3))
; 	ButtonGadget(#btnSave, 10, 5, 90, 30, "Сохранить")
	GadgetToolTip(#btnSave , "Сохранить в выбранный файл")
	
	ButtonImageGadget(#btnReOpn, 90, 5, 28, 28, ImageID(7))
	GadgetToolTip(#btnReOpn , "Переоткрыть *.cfg")
	
	ButtonImageGadget(#btnBackup, 130, 5, 28, 28, ImageID(13))
	GadgetToolTip(#btnBackup , "Сделать бэкап конфига")
	
	ButtonImageGadget(#btnDef, 170, 5, 28, 28, ImageID(14))
	GadgetToolTip(#btnDef , "/etc/default/grub")
	
	ButtonImageGadget(#btnMenu, 210, 5, 28, 28, ImageID(11))
	GadgetToolTip(#btnMenu , "Меню пунктов (выберите пункт)")
	
; 	ButtonImageGadget(#btnDup, 130, 5, 28, 28, ImageID(8))
; 	GadgetToolTip(#btnDup , "Дублировать пункт")
	
; 	ButtonImageGadget(#btnAddSn, 170, 5, 28, 28, ImageID(1))
; 	ButtonGadget(#btnAddSn, 110, 5, 90, 30, "Добавить")
; 	GadgetToolTip(#btnAddSn , "Добавить фрагмент")
; 	ButtonImageGadget(#btnDelSn, 210, 5, 28, 28, ImageID(2))
; 	ButtonGadget(#btnDelSn, 210, 5, 90, 30, "Удалить")
; 	GadgetToolTip(#btnDelSn , "Удалить пункт-фрагмент")
	
	
	ButtonImageGadget(#btnApply, 270, 5, 28, 28, ImageID(4))
; 	ButtonGadget(#btnApply, 890, 5, 90, 30, "Применить")
	GadgetToolTip(#btnApply , "Сохранить данные пункта")
	ButtonImageGadget(#btnFind, 310, 5, 28, 28, ImageID(9))
	GadgetToolTip(#btnFind , "Найти текст (Ctrl + F), продолжить - F3")
	ButtonImageGadget(#btnReplace, 350, 5, 28, 28, ImageID(17))
	GadgetToolTip(#btnReplace , "Найти и заменить (Ctrl + H)")
	ButtonImageGadget(#btnAddClass, 390, 5, 28, 28, ImageID(5))
; 	ButtonGadget(#btnAddClass, 390, 5, 190, 30, "Заполнить классы")
	GadgetToolTip(#btnAddClass , "Заполнить классы, чтобы отображалась иконка")
	CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
		ButtonImageGadget(#btnHDD, 430, 5, 28, 28, ImageID(12))
		GadgetToolTip(#btnHDD , "Инфа о UUID")
	CompilerEndIf
	
	
	ListViewGadget(#LV, 10, 40, 250, h - 50)
	SetGadgetColor(#LV, #PB_Gadget_BackColor, $3F3F3F)
	SetGadgetColor(#LV, #PB_Gadget_FrontColor, $AAAAAA)
	StringGadget(#StrField, 270, 40, w - 280, 30, "")
	SetGadgetColor(#StrField, #PB_Gadget_BackColor, $3F3F3F)
	SetGadgetColor(#StrField, #PB_Gadget_FrontColor, $AAAAAA)
; 	EditorGadget(#Edit, 270, 75, w - 280, h - 85)
	ScintillaGadget(#Edit, 270, 75, w - 280, h - 85, @SciNotification())
	

	If CreatePopupImageMenu(#Menu)
		MenuItem(#mAdd, "Добавить пункт над текущим", ImageID(1))
		MenuItem(#mDel, "Удалить выбранный пункт", ImageID(2))
		MenuItem(#mDupl, "Дублировать выбранный пункт", ImageID(8))
		MenuItem(#mRename, "Переименовать", ImageID(10))
		MenuItem(#mSvTmp, "Сохранить как шаблон", ImageID(13))
	EndIf
	AddKeyboardShortcut(#Window_0, #PB_Shortcut_F3, #mNext)
	AddKeyboardShortcut(#Window_0, #PB_Shortcut_Control | #PB_Shortcut_F, #mFind)
	AddKeyboardShortcut(#Window_0, #PB_Shortcut_Control | #PB_Shortcut_H, #mReplace)
	AddKeyboardShortcut(#Window_0, #PB_Shortcut_Control | #PB_Shortcut_S, #mSave)
	
	#MenuS = 1
	If CreatePopupImageMenu(#MenuS)
		If flgINI And OpenPreferences(ini$)
			If PreferenceGroup("Path")
				i = #mPath1 - 1
				ExaminePreferenceKeys()
				While  NextPreferenceKey()
					; пришлось к пути добавить "=", чтобы строка читалась
					i + 1
					tmp = FileSize(PreferenceKeyName())
; 					Debug Str(tmp) + " " + PreferenceKeyName()
					If tmp = -2
						MenuItem(i, PreferenceKeyName(), ImageID(6))
					ElseIf tmp > -1
						MenuItem(i, PreferenceKeyName(), ImageID(18))
					Else
						i - 1
					EndIf
				Wend
				ClosePreferences()
			EndIf
		EndIf
		If i < #mPath1
			CompilerSelect #PB_Compiler_OS
				CompilerCase #PB_OS_Windows
					MenuItem(#mPath1, ini$, ImageID(18))
					MenuItem(#mPath2, PathConfig$, ImageID(6))
				CompilerCase #PB_OS_Linux
					MenuItem(#mPath1, "/etc/default/grub", ImageID(18))
					MenuItem(#mPath2, GetHomeDirectory() + ".config/Grub2-generator/", ImageID(6))
			CompilerEndSelect
		EndIf
	EndIf




;- ● Scintilla Set
; Устанавливает режим текста
; ScintillaSendMessage(#Edit, #SCI_SETUNDOCOLLECTION, 1) ; коллекционировать отмены, видимо по умолчанию, не влияет
ScintillaSendMessage(#Edit, #SCI_SETMODEVENTMASK, #SC_MOD_INSERTTEXT) ; маска событий #SCN_MODIFIED только втсавка текста
ScintillaSendMessage(#Edit, #SCI_SETWRAPMODE, #SC_WRAP_NONE) ; без переносов строк
ScintillaSendMessage(#Edit, #SCI_SETCODEPAGE, #SC_CP_UTF8)	 ; в кодировке UTF-8
														 ; ScintillaSendMessage(#Edit, #SCI_SETVIRTUALSPACEOPTIONS, #SCVS_RECTANGULARSELECTION | #SCVS_USERACCESSIBLE) ; позволить установить курсор и выделение за пределами конца строки
														 ; Устанавливает текущую подсветку строки
ScintillaSendMessage(#Edit, #SCI_SETCARETLINEVISIBLE, 1)	 ; подсвечивает текущую строку
ScintillaSendMessage(#Edit, #SCI_SETCARETLINEVISIBLEALWAYS, 1) ; подсвечивает всегда, даже при потере фокуса
														   ; ScintillaSendMessage(#Edit, #SCI_SETCARETLINEBACKALPHA, 255) ; прозрачность подсветки текущей строки (0-255), 255 прозрачна на 100%
ScintillaSendMessage(#Edit, #SCI_SETCARETLINEBACK, RGB(0, 0, 0)) ; цвет подсвеченной строки
																 ; Устанавливает стиль текста
; NanumGothic - задать этот шрифт и устроить поиск существующего шрифта
ScintillaSendMessage(#Edit, #SCI_STYLESETFONT, #STYLE_DEFAULT, MakeUTF8Text("Arial")) ; выделение прямоугольником лучше работает с моноширинным шрифтом Courier New
ScintillaSendMessage(#Edit, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 11)		  ; размер шрифта
ScintillaSendMessage(#Edit, #SCI_STYLESETBACK, #STYLE_DEFAULT, $3F3F3F)		  ; цвет фона
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #STYLE_DEFAULT, $AAAAAA)	  ; цвет текста
ScintillaSendMessage(#Edit, #SCI_STYLECLEARALL)
; Устанавливает размер отступа и стиль колонки номеров строк
ScintillaSendMessage(#Edit, #SCI_STYLESETFONT, #STYLE_LINENUMBER, MakeUTF8Text("Arial")) ; шрифт номеров строк
ScintillaSendMessage(#Edit, #SCI_STYLESETBACK, #STYLE_LINENUMBER, RGB(33, 33, 33))		 ; цвет фона поля номеров строк
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #STYLE_LINENUMBER, RGB(153, 153, 153))	 ; цвет текста поля номеров строк
marginWidth=ScintillaSendMessage(#Edit, #SCI_TEXTWIDTH, #STYLE_LINENUMBER, MakeUTF8Text("_999")) ; ширина поля номеров строк
ScintillaSendMessage(#Edit, #SCI_SETMARGINTYPEN, 0, #SC_MARGIN_NUMBER)
ScintillaSendMessage(#Edit, #SCI_SETMARGINWIDTHN, 0, marginWidth) ; Устанавливает ширину поля номеров строк
marginWidth=0
ScintillaSendMessage(#Edit, #SCI_SETMARGINMASKN, 2, #SC_MASK_FOLDERS) ; Устанавливает отступ для поля свёртывания с запасом сгиба
ScintillaSendMessage(#Edit, #SCI_SETMARGINWIDTHN, 2, marginWidth)	  ; Устанавливает ширину поля свёртывания
ScintillaSendMessage(#Edit, #SCI_SETMARGINSENSITIVEN, 2, #True)		  ; Устанавливает чуствительность поля к клику
																  ; Устанавливает стиль текстовго курсора и выделения
ScintillaSendMessage(#Edit, #SCI_SETCARETSTICKY, 1)					  ; делает всегда видимым (?)
ScintillaSendMessage(#Edit, #SCI_SETCARETWIDTH, 1)					  ; толщина текстовго курсора
ScintillaSendMessage(#Edit, #SCI_SETCARETFORE, RGB(255, 255, 255))	  ; цвет текстовго курсора
ScintillaSendMessage(#Edit, #SCI_SETSELALPHA, 100)					  ; прозрачность выделения
ScintillaSendMessage(#Edit, #SCI_SETSELBACK, 1, RGB(255, 255, 255))	  ; цвет фона выделения
ScintillaSendMessage(#Edit, #SCI_SETSELFORE, 1, RGB(160, 160, 160))	  ; цвет текста выделения
																  ; Устанавливает дополнительные стили при использовании множественного курсора и выделения
ScintillaSendMessage(#Edit, #SCI_SETADDITIONALCARETFORE, RGB(255, 160, 160)) ; цвет дополнительного текстовго курсора
ScintillaSendMessage(#Edit, #SCI_SETADDITIONALCARETSBLINK, 1)				 ; мигание дополнительного текстовго курсора
ScintillaSendMessage(#Edit, #SCI_SETADDITIONALSELALPHA, 100)				 ; прозрачность дополнительного выделения
ScintillaSendMessage(#Edit, #SCI_SETADDITIONALSELBACK, RGB(255, 255, 100))	 ; цвет фона дополнительного выделения
ScintillaSendMessage(#Edit, #SCI_SETADDITIONALSELFORE, RGB(255, 255, 130))	 ; цвет текста дополнительного выделения
																		 ; Разрешает множественный курсор
ScintillaSendMessage(#Edit, #SCI_SETRECTANGULARSELECTIONMODIFIER, #SCMOD_ALT); выделить, удерживая нажатой клавишу Alt
ScintillaSendMessage(#Edit, #SCI_SETMULTIPLESELECTION, 1)					 ; позволяет выделить несколько раз удерживая нажатой клавишу CTRL или CMD
ScintillaSendMessage(#Edit, #SCI_SETMULTIPASTE, #SC_MULTIPASTE_EACH)		 ; множественная вставка текста
ScintillaSendMessage(#Edit, #SCI_SETADDITIONALSELECTIONTYPING, 1)			 ; позволяет ввод текста, перемешение курсора и т.д. сразу в нескольких местах

; Маркер выделенного слова
#MarkSel = 5
ScintillaSendMessage(#Edit, #SCI_INDICSETSTYLE, #MarkSel, #INDIC_STRAIGHTBOX)
ScintillaSendMessage(#Edit, #SCI_INDICSETFORE, #MarkSel, $FF00FF)
ScintillaSendMessage(#Edit, #SCI_INDICSETALPHA, #MarkSel, 105)
ScintillaSendMessage(#Edit, #SCI_INDICSETUNDER, #MarkSel, 1)
ScintillaSendMessage(#Edit, #SCI_SETINDICATORCURRENT, #MarkSel) ; делает индикатор под номером 4 текущим


; Эти константы будут использоватся для подсветки синтаксиса.
Enumeration 0
; 	#LexerState_Space
; 	#LexerState_FoldKeyword
; 	#LexerState_String
	#LexerState_Number = 7
	#LexerState_Keyword
	#LexerState_Preprocessor
	#LexerState_Operator
	#LexerState_Comment
	#LexerState_Var
	#LexerState_Param
	#LexerState_Path
	#LexerState_Func
	#LexerState_Echo
	#LexerState_UUID
	#LexerState_Device
EndEnumeration
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Comment, RGB(113, 174, 113)) ; Цвет комментариев
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Var, $729DD3)				; Цвет переменных, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Number, $ABCEE3)				; Цвет чисел, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Keyword, $FF9F00)			; Цвет ключевых слов, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Preprocessor, $BBC200)		; Цвет препроцессор, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Operator, $8080FF)			; Цвет оператор, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Param, $72ADC0)			; Цвет параметров --nnn, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Path, $BDBB7E)			; Цвет путей, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Func, $DBA6AA)			; Цвет функции, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Echo, $49c980)			; Цвет вывода, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_UUID, $DE97D9)			; Цвет UUID, BGR
ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_Device, $9CCBEB)			; Цвет устройство - диск, BGR
; ScintillaSendMessage(#Edit, #SCI_STYLESETFORE, #LexerState_FoldKeyword, RGB(0, 136, 0))	; Цвет ключевых слов со сворачиванием.
; ScintillaSendMessage(#Edit, #SCI_STYLESETBOLD, #LexerState_Number, 1)					; Выделять чисел жирным шрифтом
; ScintillaSendMessage(#Edit, #SCI_STYLESETITALIC, #LexerState_Comment, 1)				; Выделять комментарии наклонным шрифтом




	
	If Not OpnGrubcfg()
		CloseWindow(#Window_0)
		End
	EndIf
	
	EnableGadgetDrop(#LV, #PB_Drop_Private, #PB_Drag_Copy, 2)
	EnableGadgetDrop(#Edit, #PB_Drop_Files, #PB_Drag_Copy)
	
	WindowBounds(#Window_0, 500, 250, #PB_Ignore, #PB_Ignore)
	
; 	SetGadgetState(#LV, 1)
; 	SetGadgetItemState(#LV, 1, 1)
; 	PostEvent(#PB_EventType_LeftClick, #Window_0, #LV)
	
;-┌──Loop──┐
	Repeat
		Select WaitWindowEvent()
;-├ Menu events
			Case #PB_Event_Menu
				em = EventMenu()
				Select em
					Case #mReplace
						WinFind()
					Case #mAdd
						AddItemList0()
					Case #mDel
						idx = GetGadgetState(#LV)
						If idx <> -1
							If SelectElement(MenuEntryList(), idx) And DeleteElement(MenuEntryList())
								RemoveGadgetItem(#LV, idx)
								SetGadgetText(#StrField, "")
								ScintillaSendMessage(#Edit, #SCI_CLEARALL)
								SetChangeFlag()
							EndIf
						EndIf
					Case #mDupl
						DupItemList()
					Case #mRename
						tmp$ = GetGadgetText(#LV)
						tmp$ = InputRequester("Переименовать", "Введите новое имя пункта", tmp$)
						If Asc(tmp$)
							idx = GetGadgetState(#LV)
							If idx <> -1
								If SelectElement(MenuEntryList(), idx)
									MenuEntryList()\Name = tmp$
									SetGadgetItemText(#LV, idx, tmp$)
									SetChangeFlag()
								EndIf
							EndIf
						EndIf
						
					Case #mFind
						FindText()
					Case #mNext
						idx = ListIndex(MenuEntryList())
						tmp2 = idx
							isNotFind = 1
							While NextElement(MenuEntryList())
								idx + 1
								tmp = FindString(MenuEntryList()\Code, FindText$, 1, #PB_String_NoCase)
								If tmp
									tmp - 1

									SetGadgetState(#LV, idx)
; 									SetGadgetItemState(#LV, idx, 1)
									; 									PostEvent(#PB_Event_LeftClick, #Window_0, #LV)
									SelItem(idx)
									ScintillaSendMessage(#Edit, #SCI_GOTOPOS, tmp)				 ; Курсор в
; 									Color_indicator(MakeScintillaText(FindText$, @TextLength), Len(FindText$), tmp-1)
									ScintillaSendMessage(#Edit, #SCI_SETSELECTION, tmp, tmp + Len(FindText$))
									isNotFind = 0
									Break
								EndIf
							Wend
							If isNotFind
								; ResetList(MenuEntryList())
; 								если не найдено, то возвращаем изначально выбранный элемент, так как он связан со списком LB
								SelectElement(MenuEntryList(), tmp2)
							EndIf
						
					Case #mSave
						SaveToFile()
					Case #mSvTmp
						SaveToTemplate()
					Case #mPath1 To 99
						tmp$ = GetMenuItemText(#MenuS, em)
						tmp = FileSize(tmp$)
						CompilerSelect #PB_Compiler_OS
							CompilerCase #PB_OS_Windows
								If tmp = -2
									RunProgram("explorer.exe", tmp$, "")
								ElseIf tmp > -1
									RunProgram("explorer.exe", "/select," + Chr(34) + tmp$ + Chr(34), "")
								EndIf
							CompilerCase #PB_OS_Linux
								If tmp = -2
									RunProgram("xdg-open", tmp$, "")
									; RunProgram("geany", tmp$, "")
								ElseIf tmp > -1
									RunProgram("xdg-open", tmp$, "")
									; RunProgram("nemo", tmp$, "")
								EndIf
						CompilerEndSelect
				EndSelect
;-├ Resize Gadget
			Case #PB_Event_SizeWindow
				w = WindowWidth(#Window_0)
				h = WindowHeight(#Window_0)
				ResizeGadget(#LV, #PB_Ignore, #PB_Ignore, #PB_Ignore, h - 50)
				ResizeGadget(#StrField, #PB_Ignore, #PB_Ignore, w - 280, #PB_Ignore)
				ResizeGadget(#Edit, #PB_Ignore, #PB_Ignore, w - 280, h - 85)
;-├ Gadget events
			Case #PB_Event_Gadget
				Select EventGadget()
						
					CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
						Case #btnHDD
							WinInfo()
						CompilerEndIf
						
					Case #btnMenu
						If GetGadgetState(#LV) = -1
							MessageRequester("", "Сначала выберите пункт")
						Else
							DisplayPopupMenu(#Menu, WindowID(#Window_0))
						EndIf
					Case #btnFind
						FindText()
						
					Case #btnReplace
						WinFind()
						
						
					Case #btnOpn
						PathTmp$ = OpenFileRequester("Открыть файл", PathGrubcfg$, "Конфиг (*.cfg)|*.cfg", 0)
						If Asc(PathTmp$) And FileSize(PathTmp$) > 0
							PathGrubcfg$ = PathTmp$
							PathTmp$ = ""
							OpnGrubcfg()
						EndIf
						
					Case #btnReOpn
						OpnGrubcfg()
						SetGadgetText(#StrField, "")
						ScintillaSendMessage(#Edit, #SCI_CLEARALL)
						
; 					Case #btnDelSn
; 						idx = GetGadgetState(#LV)
; 						If idx <> -1
; 							If SelectElement(MenuEntryList(), idx) And DeleteElement(MenuEntryList())
; 								RemoveGadgetItem(#LV, idx)
; 							EndIf
; 						EndIf
						
					Case #btnAddClass
						tmp$ = ""
						If flgINI And OpenPreferences(ini$) ; And MapSize(ClassINI()) = 0
							If PreferenceGroup("Class")
								ExaminePreferenceKeys()
								While NextPreferenceKey() ; Пока находит ключи
									ClassINI(PreferenceKeyName()) = PreferenceKeyValue()
								Wend
								ClosePreferences()
							EndIf
						EndIf
; 						If MapSize(ClassINI())
							CreateRegularExpression(#RegExpTmp, "submenu\h+([" + #q$ + "'])([^\r\n{}]+?)\1\h*\{")
							ForEach MenuEntryList()
								If MenuEntryList()\Name = SepCode$
; 									MenuEntryList()\Code = ReplaceRegularExpression(#RegExpTmp, MenuEntryList()\Code, "submenu \1\2\1 --class folder {")
									MenuEntryList()\Code = RgExReplace2(#RegExpTmp, MenuEntryList()\Code, "submenu \1\2\1 --class folder {")
								Else
									ForEach ClassINI()
										If FindString(MenuEntryList()\Name, ClassINI(), 1, #PB_String_NoCase) And Not FindString(MenuEntryList()\Class, "--class")
											MenuEntryList()\Class = " --class " + MapKey(ClassINI()) + " " + MenuEntryList()\Class
											tmp$ + MapKey(ClassINI()) + " (" + MenuEntryList()\Name + ")" + #CRLF$
										EndIf
									Next
								EndIf
							Next
							FreeRegularExpression(#RegExpTmp)
; 						EndIf
						ClearMap(ClassINI())
						If Asc(tmp$)
							MessageRequester("Добавлено", tmp$)
							tmp$ = ""
						EndIf
						
; 					Case #btnDup
; 						DupItemList()
; 					Case #btnAddSn
; 						AddItemList0()

;-├── Apply
					Case #btnApply
						idx = GetGadgetState(#LV)
						If idx <> -1
							If SelectElement(MenuEntryList(), idx)
								
								
								
; 								LenTxtSci = ScintillaSendMessage(#Edit, #SCI_GETLENGTH) ; получим длину текста в гаджете Scintilla
; 								tmp$ = Space(LenTxtSci +4)
; 								ScintillaSendMessage(#Edit, #SCI_GETTEXT, LenTxtSci + 2, @tmp$)
; 								MenuEntryList()\Code = tmp$
; 								tmp$ = ""
								
								
								LenTxtSci = ScintillaSendMessage(#Edit, #SCI_GETLENGTH)								  ; получает длину текста в байтах
								*SciMemText = AllocateMemory(LenTxtSci+2)										  ; Выделяем память на длину текста и 1 символ на Null
								If *SciMemText																  ; Если указатель получен, то
									ScintillaSendMessage(#Edit, #SCI_GETTEXT, LenTxtSci + 1, *SciMemText)
									tmp$ = PeekS(*SciMemText, -1, #PB_UTF8)										  ; Считываем значение из области памяти
									FreeMemory(*SciMemText)
									MenuEntryList()\Code = tmp$
									SetChangeFlag()
									SetGadgetAttribute(#btnApply, #PB_Button_Image, ImageID(4))
									ScintillaSendMessage(#Edit, #SCI_SETSAVEPOINT) ; документ не требует сохранения
									ScintillaSendMessage(#Edit, #SCI_EMPTYUNDOBUFFER) ; забыть историю отмен, чтобы не сбрасывать гаджет в 0 или в предыдущий пункт
									tmp$ = ""
								EndIf
								
								
								
; 								MenuEntryList()\Code = GetGadgetText(#Edit)
								MenuEntryList()\Class = GetGadgetText(#StrField)
							EndIf
						EndIf
					Case #btnSave
						SaveToFile()
					Case #btnBackup
						SaveBackup()
					Case #btnDef
						DisplayPopupMenu(#MenuS, WindowID(#Window_0))
; 						RunProgram("xdg-open", "/etc/default/grub", "")
; 						If EventType() = #PB_EventType_RightClick
; 							MessageRequester("",GetHomeDirectory() + ".config/Grub2-generator/")
; 							RunProgram("xdg-open", GetHomeDirectory() + ".config/Grub2-generator/", "")
; 						Else
; 						EndIf

						
					Case #LV
						Select EventType()
							Case #PB_EventType_RightClick
							If GetGadgetState(#LV) <> -1
								DisplayPopupMenu(#Menu, WindowID(#Window_0))
							EndIf
								
							Case #PB_EventType_LeftClick
								idx = GetGadgetState(#LV)
								If idx <> -1
									SelItem(idx)
								EndIf
								
					
							Case #PB_EventType_DragStart ; если начали перетаскивать, то кешируем индекс пункта
; 								так как idx в #PB_EventType_LeftClick портит idx в DragStart, то сделал отдельную переменную idx0
								idx0 = GetGadgetState(#LV)
; 								tmp$ = GetGadgetText(#LV)
								DragPrivate(2) ;  EnableGadgetDrop ... 2
						EndSelect
				
				EndSelect
;-├ Drop
			Case #PB_Event_GadgetDrop
				Select EventGadget()
					Case #LV
						tmp = GetGadgetState(#LV)
						If tmp = -1 ; почему не вставляем в конец списка? потому что надо прописывать это индивидуально MoveElement с #PB_List_After
							Continue
						EndIf
						If (tmp - 1) <> idx0 ; не делаем ничгео, если при перетаскивании пункт должен вставится в туже позицию.
							tmp$ = GetGadgetItemText(#LV, idx0)
							
							; 						Перемещение элемента списка в другую позицию
							*Point = SelectElement(MenuEntryList(), tmp) ; куда будет вставлено
							If *Point
								If SelectElement(MenuEntryList(), idx0) ; что что вбрано для перемещения
									MoveElement(MenuEntryList(), #PB_List_Before, *Point)
								EndIf
							EndIf
							
							If tmp > idx0
								tmp - 1
							EndIf
							
							RemoveGadgetItem(#LV, idx0)
							AddGadgetItem(#LV, tmp, tmp$)
						EndIf
						
					Case #Edit
						tmp$ = EventDropFiles()
; 						Debug tmp$
						If Not FindString(tmp$, Chr(10))
							PathGrubcfg$ = tmp$
							OpnGrubcfg()
							ScintillaSendMessage(#Edit, #SCI_CLEARALL)
							SetGadgetText(#StrField, "")
						EndIf
				EndSelect
				
			Case #PB_Event_CloseWindow
				If needsaveTotal And MessageRequester("Закрыть без сохранения?", "Вы хотите закрыть программу без сохранения файла?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_No
					Continue
				EndIf
				
				; Сохранение размеров окна только при его изменении относительно стартовых значений
; 				If EventWindow() = #WinInfo
; 					CloseWindow(#WinInfo)
; 				Else
					If w3 <> w Or h3 <> h
						If flgINI And OpenPreferences(ini$)
							If PreferenceGroup("Set")
								WritePreferenceInteger("WinHeight", h)
								WritePreferenceInteger("WinWidth", w)
								ClosePreferences()
							EndIf
						EndIf
					EndIf
					CloseWindow(#Window_0)
					End
; 				EndIf
		EndSelect
	ForEver
EndIf
;-└──Loop──┘

;==================================================================
;
; Author:    ts-soft     
; Date:       March 5th, 2010
; Explain:
;     modified version from IBSoftware (CodeArchiv)
;     on vista and above check the Request for "User mode" or "Administrator mode" in compileroptions
;    (no virtualisation!)
;==================================================================
Procedure ForceDirectories(Dir.s)
	Static tmpDir.s, Init
	Protected result
	
	If Len(Dir) = 0
		ProcedureReturn #False
	Else
		If Not Init
			tmpDir = Dir
			Init   = #True
		EndIf
		If (Right(Dir, 1) = #PS$)
			Dir = Left(Dir, Len(Dir) - 1)
		EndIf
		If (Len(Dir) < 3) Or FileSize(Dir) = -2 Or GetPathPart(Dir) = Dir
			If FileSize(tmpDir) = -2
				result = #True
			EndIf
			tmpDir = ""
			Init = #False
			ProcedureReturn result
		EndIf
		ForceDirectories(GetPathPart(Dir))
		ProcedureReturn CreateDirectory(Dir)
	EndIf
EndProcedure



Procedure SaveBackup()
	Protected DestinationPath$, File$
	If root = 1
		DestinationPath$ = GetPathPart(PathGrubcfg$) + "backup"
		File$ = GetFilePart(PathGrubcfg$, #PB_FileSystem_NoExtension) + "_" + FormatDate("%yyyy.%mm.%dd_%hh.%ii.%ss", Date()) + "." + GetExtensionPart(PathGrubcfg$)
		If ForceDirectories(DestinationPath$) And CopyFile(PathGrubcfg$, DestinationPath$ + #PS$ + File$)
			CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
				SetFileAttributes(DestinationPath$, #PB_FileSystem_ReadUser | #PB_FileSystem_WriteUser | #PB_FileSystem_ExecUser| #PB_FileSystem_ReadGroup | #PB_FileSystem_ExecGroup | #PB_FileSystem_ReadAll | #PB_FileSystem_ExecAll)
			CompilerEndIf
			DestinationPath$ + #PS$ + File$
			CompilerIf  #PB_Compiler_OS = #PB_OS_Linux
				SetFileAttributes(DestinationPath$, #PB_FileSystem_ReadUser | #PB_FileSystem_WriteUser  | #PB_FileSystem_ReadGroup | #PB_FileSystem_ReadAll)
			CompilerEndIf
			MessageRequester("Успешно", DestinationPath$ + #CRLF$ + #CRLF$ + File$)
		Else
			MessageRequester("Ошибка", "Ошибка", #PB_MessageRequester_Error)
		EndIf
	Else
		DestinationPath$ = PathConfig$ + "backup"
		File$ = GetFilePart(PathGrubcfg$, #PB_FileSystem_NoExtension) + "_" + FormatDate("%yyyy.%mm.%dd_%hh.%ii.%ss", Date()) + "." + GetExtensionPart(PathGrubcfg$)
		If ForceDirectories(DestinationPath$) And CopyFile(PathGrubcfg$, DestinationPath$ + #PS$ + File$)
; 			DestinationPath$ + #PS$ + File$
			MessageRequester("Успешно", DestinationPath$ + #CRLF$ + #CRLF$ + File$)
		Else
			MessageRequester("Ошибка", "Ошибка", #PB_MessageRequester_Error)
		EndIf
	EndIf
EndProcedure

Procedure SaveToTemplate()
	Protected LenTxtSci, menuitem$, tmp$, Name$, *SciMemText, File$, id_file
	
	
	idx = GetGadgetState(#LV)
	If idx <> -1
		Name$ = GetGadgetItemText(#LV, idx)
		Name$ = InputRequester("Укажите имя пункта", "Укажите имя пункта", Name$)
		If Not Asc(Name$)
			ProcedureReturn
		EndIf
		
		File$ = SaveFileRequester("Открыть файл", PathTemplate$ + Name$, "*.cfg|*.cfg", 0)
		If Asc(File$)
			; условие, если пользователь не ввёл расширение файла, но в случае если фильтр только "cfg"
			If Right(File$, 4) <> ".cfg"
				File$ + ".cfg"
			EndIf
		Else
			ProcedureReturn
		EndIf
		If FileSize(File$) > -1 And MessageRequester("Перезаписать?", "Вы хотите перезаписать файл ...?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_No
			ProcedureReturn
		EndIf
		
		
		menuitem$ = "menuentry '" + Name$ + "' " + GetGadgetText(#StrField) + " {" + #CRLF$
		LenTxtSci = ScintillaSendMessage(#Edit, #SCI_GETLENGTH)								  ; получает длину текста в байтах
		*SciMemText = AllocateMemory(LenTxtSci+2)											  ; Выделяем память на длину текста и 1 символ на Null
		If *SciMemText																		  ; Если указатель получен, то
			ScintillaSendMessage(#Edit, #SCI_GETTEXT, LenTxtSci + 1, *SciMemText)
			tmp$ = PeekS(*SciMemText, -1, #PB_UTF8)										  ; Считываем значение из области памяти
			FreeMemory(*SciMemText)
			; 				If Not Asc(tmp$)
			; 					MessageRequester("", "Отсутсвует контент пункта")
			; 					ProcedureReturn
			; 				EndIf
			id_file = CreateFile(#PB_Any, File$)
			If id_file
				WriteStringFormat(id_file, #PB_UTF8)
				WriteString(id_file, menuitem$ + tmp$ + #CRLF$ + "}", #PB_UTF8)
				CloseFile(id_file)
			EndIf
			
		EndIf
	EndIf
	
EndProcedure


Procedure SaveToFile()
; 	Protected tmp, tmp$
	PathTmp$ = SaveFileRequester("Сохранить", PathGrubcfg$, "grub.cfg|grub.cfg|Конфиг (*.cfg)|*.cfg|Все файлы (*.*)|*.*", 0)
	If Asc(PathTmp$)
		PathGrubcfg$ = PathTmp$
		PathTmp$ = ""
		Text$ = ""
		tmp = 0
		ForEach MenuEntryList()
			If MenuEntryList()\Name = SepCode$
				Text$ + MenuEntryList()\Code
				tmp = 0
			Else
				If tmp
					Text$ + CRLF$
				EndIf
				If Asc(MenuEntryList()\Class)
					tmp$ = " " + MenuEntryList()\Class
				Else
					tmp$ = ""
				EndIf
				Text$ + "menuentry " + #q$ + MenuEntryList()\Name + #q$ + tmp$ + " {" + CRLF$ + MenuEntryList()\Code + CRLF$ + "}"
				tmp = 1
			EndIf
		Next
		If CreateFile(#File, PathGrubcfg$)
			If WriteString(#File, Text$, #PB_UTF8)
				needsaveTotal = 0
				needsaveTotalRe = 1
				SetGadgetAttribute(#btnSave, #PB_Button_Image, ImageID(3))
			EndIf
			CloseFile(#File)
		Else
			MessageRequester("", "Не удалось создать файл.")
		EndIf
		Text$ = ""
		tmp$ = ""
	EndIf
EndProcedure


Procedure FindText()
; 	Protected tmp, tmp$
	tmp$ = GetSelText()
	If Asc(tmp$) And (FindString(tmp$, #LF$) Or FindString(tmp$, #CR$))
		tmp$ = ""
	EndIf
	FindText$ = InputRequester("Найти", "Введите текст поиска", tmp$)
	If Asc(FindText$)
		idx = 0
		ForEach MenuEntryList()
			tmp = FindString(MenuEntryList()\Code, FindText$, 1, #PB_String_NoCase)
			If tmp
				tmp - 1
				SetGadgetState(#LV, idx)
				; 									SetGadgetItemState(#LV, idx, 1)
				; 									PostEvent(#PB_Event_LeftClick, #Window_0, #LV)
				SelItem(idx)
				ScintillaSendMessage(#Edit, #SCI_GOTOPOS, tmp)				 ; Курсор в
; 				Color_indicator(MakeScintillaText(FindText$, @TextLength), Len(FindText$), tmp-1)
				ScintillaSendMessage(#Edit, #SCI_SETSELECTION, tmp, tmp + Len(FindText$))
				Break
			EndIf
			idx + 1
		Next
	EndIf
EndProcedure

; CompilerSelect #PB_Compiler_OS
; 	CompilerCase #PB_OS_Windows
; 		Macro GetAttributes
; 			GetFileAttributes(PathGrubcfg$) & #PB_FileSystem_System
; 		EndMacro
; 	CompilerCase #PB_OS_Linux
; 		Macro GetAttributes
; 			GetFileAttributes(PathGrubcfg$) & #PB_FileSystem_ReadAll
; 		EndMacro
; CompilerEndSelect

Procedure OpnGrubcfg()
	Protected PosStart = 1, PosTmp = 1
	Protected Text$, tmp$
	
; 	условие для первого запуска
	If FileSize(PathGrubcfg$) < 0; Or Not (GetFileAttributes(PathGrubcfg$) & #PB_FileSystem_ReadAll) ; отсутствует или нет разрешения чтения
		PathGrubcfg$ = OpenFileRequester("Открыть файл", PathGrubcfg$, "Конфиг (*.cfg)|*.cfg", 0)
		If Asc(PathGrubcfg$) = 0 Or FileSize(PathGrubcfg$) < 0
; 			MessageRequester("", "Не найден файл: " + PathGrubcfg$)
			ProcedureReturn 0
		EndIf
	EndIf

	If ReadFile(#File, PathGrubcfg$, #PB_UTF8)
		Text$ = ReadString(#File, #PB_UTF8 | #PB_File_IgnoreEOL)
		CloseFile(#File)
	EndIf
	
	
	If Not Asc(Text$)
		MessageRequester("", "Пустой файл: " + PathGrubcfg$)
		Text$ = ""
		ProcedureReturn 0
	EndIf

	If CountString(Text$, #CR$)
	; 	При смешанном переносе строк если разница больше чем в 2 раза, то используем Linux вариант конца строки
		If CountString(Text$, #LF$)/CountString(Text$, #CR$) > 2
			CRLF$ = #LF$
		Else
			CRLF$ = #CRLF$
		EndIf
	Else
		CRLF$ = #LF$
	EndIf
	
	Define PosStart = 1
	Define PosTmp = 1
	
	ClearList(MenuEntryList())
	ClearGadgetItems(#LV)

	If ExamineRegularExpression(#RegExp, Text$)
		While NextRegularExpressionMatch(#RegExp)
			PosTmp = RegularExpressionMatchPosition(#RegExp)
			If PosTmp > PosStart 
				tmp$ = Mid(Text$, PosStart, PosTmp - PosStart)
				If Not MatchRegularExpression(#RegExp1 , tmp$) And AddElement(MenuEntryList())
					MenuEntryList()\Name = SepCode$
					MenuEntryList()\Code = tmp$
				EndIf
				PosStart = PosTmp + RegularExpressionMatchLength(#RegExp)
			EndIf
			If AddElement(MenuEntryList())
				; 				MenuEntryList() = RegularExpressionMatchString(#RegExp)
				MenuEntryList()\Name = RegularExpressionGroup(#RegExp, 2)
				MenuEntryList()\Class = RegularExpressionGroup(#RegExp, 3)
				MenuEntryList()\Code = RegularExpressionGroup(#RegExp, 4)
			EndIf
		Wend
		If Len(Text$) > PosStart 
			tmp$ = Mid(Text$, PosStart)
			If Not MatchRegularExpression(#RegExp1 , tmp$) And AddElement(MenuEntryList())
				MenuEntryList()\Name = SepCode$
				MenuEntryList()\Code = tmp$
			EndIf
		EndIf
	EndIf
	
	ForEach MenuEntryList()
		AddGadgetItem(#LV, -1, MenuEntryList()\Name) 
	Next
	
; 	Сброс флага необходимости сохранения
	needsaveTotal = 0
	needsaveTotalRe = 1
	SetGadgetAttribute(#btnSave, #PB_Button_Image, ImageID(3))
	
; 	Сокращённый путь
; 	CreateRegularExpression(#RegExpTmp, "(^.{3,11}/|.{11})(.*)(/.{6,27}|.{27})$" )
; 	SetWindowTitle(#Window_0,   "Grub2-generator (" + RgExReplace2(#RegExpTmp,PathGrubcfg$, "\1...\3" ) + ")")
; 	FreeRegularExpression(#RegExpTmp)
	SetWindowTitle(#Window_0,  "Grub2-generator (" + PathGrubcfg$ + ")")
	
	ProcedureReturn 1
EndProcedure

Procedure DupItemList()
	Protected Name$, Class$, Code$
	idx = GetGadgetState(#LV)
	If idx <> -1 And GetGadgetItemText(#LV, idx) <> SepCode$
; 	If idx <> -1 And GetGadgetText(#LV) <> SepCode$
		If SelectElement(MenuEntryList(), idx)
			Name$ = MenuEntryList()\Name
			Class$ = MenuEntryList()\Class
			Code$ = MenuEntryList()\Code
			If AddElement(MenuEntryList())
				MenuEntryList()\Name = Name$
				MenuEntryList()\Class = Class$
				MenuEntryList()\Code = Code$
				AddGadgetItem(#LV, idx + 1, MenuEntryList()\Name)
				SetChangeFlag()
			EndIf
		EndIf
		
	EndIf
EndProcedure

Procedure SetChangeFlag()
	needsaveTotal = 1
	If needsaveTotal And needsaveTotalRe
		needsaveTotalRe = 0
		SetGadgetAttribute(#btnSave, #PB_Button_Image, ImageID(16))
	EndIf
EndProcedure


Procedure AddItemList0()
	Protected tmp$, idx
	tmp$ = OpenFileRequester("Открыть файл", PathTemplate$, "Конфиг (*.cfg)|*.cfg", 0)
	If Asc(tmp$) And FileSize(tmp$) > 0
		PathTemplate$ = tmp$
		tmp$ = ""
; 		tmp$ = InputRequester("Имя", "Тире (-) добавляет как код", "-")
; 		If Asc(tmp$)
			idx = GetGadgetState(#LV)
			If idx = -1
				If LastElement(MenuEntryList()) And AddElement(MenuEntryList())
					AddItemList(idx)
				EndIf
			Else
				If SelectElement(MenuEntryList(), idx) And InsertElement(MenuEntryList())
					AddItemList(idx)
				EndIf
			EndIf
; 		EndIf
	EndIf
EndProcedure

Procedure AddItemList(ind)
	Protected txt$, tmp$, fNoMitem = 1
	Protected UUIDclipboard$, UUIDcode$
	If ReadFile(#File, PathTemplate$, #PB_UTF8)
		ReadStringFormat(#File)
		txt$ = ReadString(#File, #PB_UTF8 | #PB_File_IgnoreEOL)
		CloseFile(#File)
	EndIf
	
	
	UUIDclipboard$ = GetClipboardText()
	If Len(UUIDclipboard$) = 36
		If CreateRegularExpression(#RegExpTmp, "\A[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}\z", #PB_RegularExpression_NoCase)
			If Not MatchRegularExpression(#RegExpTmp , UUIDclipboard$)
				UUIDclipboard$ = ""
			EndIf
			FreeRegularExpression(#RegExpTmp)
		EndIf
		
		If Asc(UUIDclipboard$)
			If CreateRegularExpression(#RegExpTmp, "[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}", #PB_RegularExpression_NoCase)
				If ExamineRegularExpression(#RegExpTmp, txt$) And NextRegularExpressionMatch(#RegExpTmp)
					UUIDcode$ = RegularExpressionMatchString(#RegExpTmp)
				EndIf
				FreeRegularExpression(#RegExpTmp)
			EndIf
			If Asc(UUIDcode$)
				If MessageRequester("Заменить UUID?", "Вы хотите заменить найденный в шаблоне UUID: " + #LF$ + UUIDcode$ + #LF$ + "на UUID находящийся в буфере обмена: " + #LF$ + UUIDclipboard$, 
				                    #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
					ReplaceString(txt$, UUIDcode$, UUIDclipboard$, #PB_String_InPlace)
				EndIf
			EndIf
		EndIf
	EndIf
	
; 	Если вставляемый код парсится как пункт, то он добавляется как пункт с именем и классом
	If CreateRegularExpression(#RegExpTmp,
	                           "\A\s*menuentry\h+([" + #q$ + "'])([^\r\n{}]+?)\1		(?:\h+([^\r\n{}]+?))?\h*		\{\h*\v*(.+?)		[\r\n]+\s*\}\s*\z",
	                           #PB_RegularExpression_DotAll | #PB_RegularExpression_NoCase | #PB_RegularExpression_Extended)
		If ExamineRegularExpression(#RegExpTmp, txt$)
			While NextRegularExpressionMatch(#RegExpTmp)
				MenuEntryList()\Name = RegularExpressionGroup(#RegExpTmp, 2)
				MenuEntryList()\Class = RegularExpressionGroup(#RegExpTmp, 3)
				MenuEntryList()\Code = RegularExpressionGroup(#RegExpTmp, 4)
				AddGadgetItem(#LV, ind, MenuEntryList()\Name)
				fNoMitem = 0
			Wend
		EndIf
		FreeRegularExpression(#RegExpTmp)
	EndIf
	If fNoMitem
		AddGadgetItem(#LV, ind, SepCode$)
		MenuEntryList()\Name = SepCode$
		MenuEntryList()\Code = txt$
	EndIf
	SetChangeFlag()
EndProcedure

Procedure.s RgExReplace2(RgEx, Text$, Replacement$)
	Protected i, CountGr, Pos, Offset = 1
	Protected Replace$, Result.s
	If ExamineRegularExpression(RgEx, Text$)
			CountGr = CountRegularExpressionGroups(RgEx)
; 			If CountGr>9
; 				CountGr=9
; 			EndIf ; только обратные ссылки \1 .. \9
		While NextRegularExpressionMatch(RgEx)
			Pos = RegularExpressionMatchPosition(RgEx)
			Replace$ = ReplaceString(Replacement$, "\0", RegularExpressionMatchString(RgEx)) ; обратная ссылка \0
			For i=1 To CountGr
				Replace$ = ReplaceString(Replace$,"\" + Str(i),RegularExpressionGroup(RgEx, i))
			Next
; 			For i=CountGr+1 To 9 ; отсутствующие группы на пустые строки
; 				Replace$ = ReplaceString(Replace$,"\"+Str(i),"")
; 			Next
			; Result + часть строки между началом и первым совпадением или между двумя совпадениями + результат подстановки групп
			Result + Mid(Text$, Offset, Pos - Offset) + Replace$
			Offset = Pos + RegularExpressionMatchLength(RgEx)
		Wend
		ProcedureReturn Result + Mid(Text$, Offset) ; Result + остаток строки
	EndIf
	ProcedureReturn Text$ ; без изменений
EndProcedure



; Преобразование текста в текст для вставки в Scintilla
Procedure MakeUTF8Text(text.s)
	Static buffer.s
	buffer=Space(StringByteLength(text, #PB_UTF8))
	PokeS(@buffer, text, -1, #PB_UTF8)
	ProcedureReturn @buffer
EndProcedure

Procedure MakeScintillaText(text.s, *sciLength.Integer=0)
	Static sciLength : sciLength=StringByteLength(text, #PB_UTF8) ; #TextEncoding
	Static sciText.s : sciText = Space(sciLength)
	If *sciLength : *sciLength\i=sciLength : EndIf ;<--- Возвращает длину буфера scintilla  (требуется для определенной команды scintilla)
	PokeS(@sciText, text, -1, #PB_UTF8)			   ; #TextEncoding
	ProcedureReturn @sciText
EndProcedure


; Подсвечивание через индикаторы
Procedure Color(*regex, regexLength, n)
	Protected txtLen, StartPos, EndPos, firstMatchPos, ColorT = $8080FF

	; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
	ScintillaSendMessage(#Edit, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)
	
; 	у этой версии индикатора почему то нет стиля выделения текста 17
; 	Select n
; 		Case #LexerState_Comment
; 			ColorT = $71AE71
; 		Case #LexerState_Var
; 			ColorT = $729DD3
; 		Case #LexerState_Number
; 			ColorT = $ABCEE3
; 		Case #LexerState_Keyword
; 			ColorT = $FF9F00
; 		Case #LexerState_Preprocessor
; 			ColorT = $BBC200
; 		Case #LexerState_Operator
; 			ColorT = $8080FF
; 		Case #LexerState_Param
; 			ColorT = $72ADC0
; 		Case #LexerState_Path
; 			ColorT = $BDBB7E
; 		Case #LexerState_Func
; 			ColorT = $DBA6AA
; 		Case #LexerState_Echo
; 			ColorT = $49c980
; 		Case #LexerState_UUID
; 			ColorT = $DE97D9
; 		Case #LexerState_Device
; 			ColorT = $9CCBEB
; 	EndSelect
	

	; Устанавливает целевой диапазон поиска
	txtLen = ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH) ; получает длину текста
	ScintillaSendMessage(#Edit, #SCI_INDICSETSTYLE, n, 7)	 ; #INDIC_TEXTFORE = 17 создаёт индикатор под номером 7 (занятые по уиолчанию 0, 1, 2)
	ScintillaSendMessage(#Edit, #SCI_INDICSETFORE, n, ColorT) ; назначает цвет индикатора под номером 7 - зелёный

	EndPos = 0
	Repeat
		ScintillaSendMessage(#Edit, #SCI_SETTARGETSTART, EndPos)	   ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(#Edit, #SCI_SETTARGETEND, txtLen)		   ; до конца по длине текста
		firstMatchPos=ScintillaSendMessage(#Edit, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
		If firstMatchPos>-1																; если больше -1, то есть найдено, то
			StartPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETSTART)						; получает позицию начала найденного
			EndPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETEND)							; получает позицию конца найденного
			ScintillaSendMessage(#Edit, #SCI_SETINDICATORCURRENT, n)						; делает индикатор под номером 7 текущим
			ScintillaSendMessage(#Edit, #SCI_INDICATORFILLRANGE, StartPos, EndPos - StartPos)  ; выделяет текст используя текущий индикатор
		Else
			Break
		EndIf
	ForEver
EndProcedure

; Color_indicator(MakeScintillaText(tmp$, @TextLength), Len(tmp$), tmp)
; Подсвечивание через индикаторы
; Procedure Color_indicator(*regex, regexLength, EndPos)
; 	Protected txtLen, StartPos, firstMatchPos, ColorT = $8080FF, n = 7
; 
; 	; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
; 	ScintillaSendMessage(#Edit, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)
; 
; 	; Устанавливает целевой диапазон поиска
; 	txtLen = ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH) ; получает длину текста
; 	ScintillaSendMessage(#Edit, #SCI_INDICSETSTYLE, n, 6)	 ; #INDIC_TEXTFORE = 17 создаёт индикатор под номером 7 (занятые по уиолчанию 0, 1, 2)
; 	ScintillaSendMessage(#Edit, #SCI_INDICSETFORE, n, ColorT) ; назначает цвет индикатора под номером 7 - зелёный
; 
; ; 	EndPos = tmp
; ; 	делаем одиночный поиск
; 	Repeat
; 		ScintillaSendMessage(#Edit, #SCI_SETTARGETSTART, EndPos)	   ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
; 		ScintillaSendMessage(#Edit, #SCI_SETTARGETEND, txtLen)		   ; до конца по длине текста
; 		firstMatchPos=ScintillaSendMessage(#Edit, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
; 		If firstMatchPos>-1																; если больше -1, то есть найдено, то
; 			StartPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETSTART)						; получает позицию начала найденного
; 			EndPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETEND)							; получает позицию конца найденного
; 			ScintillaSendMessage(#Edit, #SCI_SETINDICATORCURRENT, n)						; делает индикатор под номером 7 текущим
; 			ScintillaSendMessage(#Edit, #SCI_INDICATORFILLRANGE, StartPos, EndPos - StartPos)  ; выделяет текст используя текущий индикатор
; 		Else
; 			Break
; 		EndIf
; 	ForEver
; EndProcedure

Procedure SelItem(idx)
	If SelectElement(MenuEntryList(), idx)
; 		If needsave And MessageRequester("Сохраненить?", "Сохраненить код пункта в дерево документа?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
; 				Debug "требуется сохранение документа"
; 		EndIf
		IsOpenSection = 1
		*SciMemText = UTF8(MenuEntryList()\Code)
		ScintillaSendMessage(#Edit, #SCI_SETTEXT, 0, *SciMemText)
		ScintillaSendMessage(#Edit, #SCI_SETSAVEPOINT) ; документ не требует сохранения
		ScintillaSendMessage(#Edit, #SCI_EMPTYUNDOBUFFER) ; забыть историю отмен, чтобы не сбрасывать гаджет в 0 или в предыдущий пункт
		FreeMemory(*SciMemText)
		SetGadgetText(#StrField, MenuEntryList()\Class)
	EndIf
EndProcedure

Procedure Color5(*regex, regexLength, Lexeme, EndPos, txtLen)
	Protected StartPos

	; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
	ScintillaSendMessage(#Edit, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)

	; Устанавливает целевой диапазон поиска
; 	txtLen = EndPos + txtLen

	Repeat
		ScintillaSendMessage(#Edit, #SCI_SETTARGETSTART, EndPos)	   ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(#Edit, #SCI_SETTARGETEND, txtLen)		   ; до конца по длине текста
		StartPos=ScintillaSendMessage(#Edit, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
		If StartPos>-1																; если больше -1, то есть найдено, то
; 			StartPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETSTART)						; получает позицию начала найденного
			EndPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETEND)							; получает позицию конца найденного
			ScintillaSendMessage(#Edit, #SCI_STARTSTYLING, StartPos, 0)						; позиция начала (с 50-го)
			ScintillaSendMessage(#Edit, #SCI_SETSTYLING, EndPos - StartPos, Lexeme) ; ширина и номер стиля
		Else
			Break
		EndIf
	ForEver
EndProcedure

Procedure SelHighlight(p, l)
	
	regex$ = "^[ 	]*function[ 	]+[_a-z\d]+"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Func, p, l)
	regex$ = "^[ 	]*insmod[ 	]+[_a-z\d]+"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Preprocessor, p, l)
	regex$ = "^[ 	]*?[_a-z\d]+[ 	]*$"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Func, p, l)
	regex$ = "^[ 	]*echo[ 	]+.+?$"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Echo, p, l)
	regex$ = "\<\$?[_a-z\d]+[ 	]*="
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Var, p, l)
	Color3("if|fi|else|then|insmod|chainloader|parttool|drivemap|set|initrd|search|function|linux|echo|export|loopback|probe|configfile|submenu|menuentry|videoinfo|ls|sleep",
	       #LexerState_Keyword, p, l)
	regex$ = "\<\d+\>"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Number, p, l)
	regex$ = "\<loop\>"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Device, p, l)
	regex$ = "\<[hfrc]d\d+\>"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Device, p, l)
	regex$ = "[;+!<>(){}\[\]=" + #q$ + "-]+"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Operator, p, l)
; 	Комментарии последние, так как перекрашивает текст поверх
; 	regex$ = "(?<=[\r\n])\h*#.*?(?=[\r\n]"
	regex$ = "[ 	]--[a-z\d-]+\>"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Param, p, l)
	regex$ = "/[a-z\d._/-]+"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Path, p, l)
	regex$ = "\${.+?}"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Var, p, l)
	regex$ = "\$[_a-z\d]+"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Var, p, l)
	regex$ = "[a-f\d]+-[a-f\d]+-[a-f\d]+-[a-f\d-]+"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_UUID, p, l)
	regex$ = "^[ 	]*#.*$"
	Color5(MakeScintillaText(regex$, @TextLength), Len(regex$), #LexerState_Comment, p, l)

EndProcedure


; regex$ = "\<else\>"
; Color2(, #LexerState_Keyword)

; Подсвечивание через стиль ключевых слов
Procedure Color3(KeyStr$, Lexeme, EndPos0, txtLen)
	Protected StartPos, EndPos, firstMatchPos, regexLength, *regex
	Protected NewList KeyStrList.s()
	SplitL(KeyStr$, KeyStrList(), "|")

	; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
	ScintillaSendMessage(#Edit, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)

	
	ForEach KeyStrList()
		*regex = MakeScintillaText("\<" + KeyStrList() + "\>", @regexLength)
; 		*regex = UTF8("\<" + KeyStrList() + "\>")
; 		regexLength = Len("\<" + KeyStrList() + "\>")
		
		EndPos = EndPos0
		Repeat
			ScintillaSendMessage(#Edit, #SCI_SETTARGETSTART, EndPos)	   ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
			ScintillaSendMessage(#Edit, #SCI_SETTARGETEND, txtLen)	 ; до конца по длине текста
			firstMatchPos=ScintillaSendMessage(#Edit, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
			If firstMatchPos>-1																; если больше -1, то есть найдено, то
				StartPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETSTART)						; получает позицию начала найденного
				EndPos=ScintillaSendMessage(#Edit, #SCI_GETTARGETEND)							; получает позицию конца найденного
				ScintillaSendMessage(#Edit, #SCI_STARTSTYLING, StartPos, 0)						; позиция начала (с 50-го)
				ScintillaSendMessage(#Edit, #SCI_SETSTYLING, EndPos - StartPos, Lexeme) ; ширина и номер стиля
			Else
				Break
			EndIf
		ForEver
		
; 		FreeMemory(*regex)
	Next

EndProcedure

Procedure SplitL(String.s, List StringList.s(), Separator.s = " ")
	
	Protected S.String, *S.Integer = @S
	Protected.i p, slen
	slen = Len(Separator)
	ClearList(StringList())
	
	*S\i = @String
	Repeat
		AddElement(StringList())
		p = FindString(S\s, Separator)
		StringList() = PeekS(*S\i, p - 1)
		*S\i + (p + slen - 1) << #PB_Compiler_Unicode
	Until p = 0
	*S\i = 0
	
EndProcedure





; Уведомления
Procedure SciNotification(Gadget, *scinotify.SCNotification)
	Protected Path$, pos, pos2, line
; 	Select Gadget
; 		Case 0 ; уведомление гаджету 0 (Scintilla)
	With *scinotify
		Select \nmhdr\code
			Case #SCN_STYLENEEDED ; нужна стилизация, подсветка текста (в предыдущей версии работали #SCN_CHARADDED и #SCN_MODIFIED)
; 				Debug 1
				pos = ScintillaSendMessage(#Edit, #SCI_GETENDSTYLED)
				pos2 = *scinotify.SCNotification\Position
				line = ScintillaSendMessage(#Edit, #SCI_LINEFROMPOSITION, pos) ; номер строки из позиции (в которой расположен курсор)
				pos = ScintillaSendMessage(#Edit, #SCI_POSITIONFROMLINE, line) ; позиция начала начала указанного номера строки
				If IsOpenSection
					pos = 0
					pos2 = ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH) ; получает длину текста
					IsOpenSection = 0
				EndIf
				SelHighlight(pos, pos2)											   ; подсветка только строки, в которой курсор
																				   ; подкраска, чтобы прекратить досить подсветкой каждую секунду
				ScintillaSendMessage(#Edit, #SCI_STARTSTYLING, 2147483646, 0)  ; позиция больше документа
				ScintillaSendMessage(#Edit, #SCI_SETSTYLING, 0, 0)			   ; ширина и номер стиля
			Case #SCN_SAVEPOINTREACHED
				SetGadgetAttribute(#btnApply, #PB_Button_Image, ImageID(4))
				needsave = 0
; 				Debug "REACHED"
			Case #SCN_SAVEPOINTLEFT
				SetGadgetAttribute(#btnApply, #PB_Button_Image, ImageID(15))
				needsave = 1
; 				Debug "LEFT"

; 			Case #SCN_MODIFIED												   ; реакция на модификацию документа (плаг пометки изменений)
; 				needsave = 1
; 				If \modificationType & #SC_MOD_INSERTTEXT
; 					If IsOpenSection
; 						needsave = 0
; 					EndIf
; 				EndIf
; 			Case #SCN_CHARADDED ; реакция на ввод символа, самый экономичный, можно добавить проверку ввода пробела или переноса строки
; 				Debug 1
; 					pos = ScintillaSendMessage(#Edit, #SCI_GETCURRENTPOS) ; позиция курсора чтобы получить номер строки
; 					line = ScintillaSendMessage(#Edit, #SCI_LINEFROMPOSITION, pos) ; номер строки из позиции (в которой расположен курсор)
; 					pos2 = ScintillaSendMessage(#Edit, #SCI_GETLINEENDPOSITION, line) ; позиция конца строки указанного номера строки
; 					pos = ScintillaSendMessage(#Edit, #SCI_POSITIONFROMLINE, line) ; позиция начала начала указанного номера строки
; 					SelHighlight(pos, pos2)										   ; подсветка только строки, в которой курсор
					
; 			Case #SCN_STYLENEEDED ; необходима подсветка (событие часто, да ещё иногда при простое, да ещё пытается не строку а весь текст)
; 				pos = ScintillaSendMessage(#Edit, #SCI_GETENDSTYLED)
; 				line = ScintillaSendMessage(#Edit, #SCI_LINEFROMPOSITION, pos) ; номер строки из позиции
; 				pos = ScintillaSendMessage(#Edit, #SCI_POSITIONFROMLINE, line) ; позиция из номера строки
; 				SelHighlight(pos, \Position)
; 				Debug "n"+ Str(line) + " " + Str(pos) + " " + Str(\Position)
    			
    
; 			Case #SCN_UPDATEUI ; реакция на обновление содержимого (прокрутка, выделение)
; 				If \updated & #SC_UPDATE_CONTENT ; если обновление содержимого #SC_UPDATE_CONTENT, то подсвечиваем строку
; 					pos = ScintillaSendMessage(#Edit, #SCI_GETCURRENTPOS) ; позиция курсора чтобы получить номер строки
; 					line = ScintillaSendMessage(#Edit, #SCI_LINEFROMPOSITION, pos) ; номер строки из позиции (в которой расположен курсор)
; 					pos2 = ScintillaSendMessage(#Edit, #SCI_GETLINEENDPOSITION, line) ; позиция конца строки указанного номера строки
; 					pos = ScintillaSendMessage(#Edit, #SCI_POSITIONFROMLINE, line) ; позиция начала начала указанного номера строки
; 					SelHighlight(pos, pos2) ; подсветка только строки, в которой курсор
; ; 					Debug "n"+ Str(line) + " " + Str(pos) + " " + Str(pos2)
; 				EndIf
				
; 			Case #SCN_MODIFIED ; реакция на модификацию документа (плаг пометки изменений)
; 				If \modificationType & #SC_MOD_INSERTTEXT
; 				Debug 2
; 					; если в типе модификации есть флаг вставки SC_MOD_INSERTTEXT, то (ввод символа или Ctrl+V)
; 					SelHighlight(\Position, \Position + \length)
; 				EndIf
; 			Case #SCN_URIDROPPED ; о броске файлов в окно
; 				Path$ = PeekS(*scinotify.SCNotification\text, -1, #PB_UTF8 | #PB_ByteLength)
; 				pos = FindString(Path$, Chr(10)) ; обрезка, оставляя 1 файл
; 				If pos
; 					Path$ = LSet(Path$ , pos-2)
; 				EndIf
; 				Path$ = RemoveString(Path$ , "file://", #PB_String_CaseSensitive, 1, 1) ; удалить 1 раз
; 				Debug Path$
; 				ReadFileR(Path$)
			Case #SCN_UPDATEUI
				If \updated & #SC_UPDATE_SELECTION ; если происходит выделение текста и перемещение текстового курсора
					If ScintillaSendMessage(#Edit, #SCI_GETSELECTIONEMPTY) ; Если 0, то выделен 1 и более символов, если 1 то ничего не выделено
						If flgHSel
							ScintillaSendMessage(#Edit, #SCI_INDICATORCLEARRANGE, 0, ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH))
						EndIf
					Else
						HighlightSelection()
					EndIf
				EndIf
		EndSelect
	EndWith
; 	EndSelect
EndProcedure


Procedure HighlightSelection()
	Protected length, Cursor, Anchor, *pos ; , Selected$
	Protected length2, StartPos, EndPos, firstMatchPos, *Search
	Protected inSrt, inEnd
	Cursor = ScintillaSendMessage(#Edit, #SCI_GETCURRENTPOS)
	Anchor = ScintillaSendMessage(#Edit, #SCI_GETANCHOR)
	If Anchor < Cursor
		Swap Cursor, Anchor
	EndIf
	length = Anchor - Cursor
	If Cursor <> ScintillaSendMessage(#Edit, #SCI_WORDSTARTPOSITION, Cursor, 1) Or Anchor <> ScintillaSendMessage(#Edit, #SCI_WORDENDPOSITION, Anchor, 1)
		ProcedureReturn
	EndIf


	*pos = ScintillaSendMessage(#Edit, #SCI_GETCHARACTERPOINTER) ; прямой доступ
; 	Selected$ = PeekS(*pos + Cursor, length, #PB_UTF8 | #PB_ByteLength)




	*Search = *pos + Cursor
	ScintillaSendMessage(#Edit, #SCI_INDICATORCLEARRANGE, 0, ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH))
	; Устанавливает целевой диапазон поиска
	inSrt = 0
	inEnd = ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH) ; получает длину текста
	ScintillaSendMessage(#Edit, #SCI_SETTARGETSTART, inSrt)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
	ScintillaSendMessage(#Edit, #SCI_SETTARGETEND, inEnd)	   ; до конца по длине текста

	ScintillaSendMessage(#Edit, #SCI_SETSEARCHFLAGS, #SCFIND_MATCHCASE)
; 	lengthStr = Len(SearchTxt$)

	ScintillaSendMessage(#Edit, #SCI_BEGINUNDOACTION)
	Repeat
		; 		нашли
		firstMatchPos = ScintillaSendMessage(#Edit, #SCI_SEARCHINTARGET, length, *Search)
		; 		Debug firstMatchPos
		If firstMatchPos = -1
			; выпрыг если не найдено
			Break
		EndIf

		flgHSel = 1
		StartPos = ScintillaSendMessage(#Edit, #SCI_GETTARGETSTART)        ; получает позицию начала найденного
		EndPos = ScintillaSendMessage(#Edit, #SCI_GETTARGETEND)			   ; получает позицию конца найденного
		length2 = EndPos - StartPos
; 		чтобы не подсвечивать само выделяемое слово
		If StartPos <> Cursor
; 			Count + 1 ; здесь можно осуществить подсчёт выделенных не затрачивая особых ресурсов
; 			Continue
			ScintillaSendMessage(#Edit, #SCI_INDICATORFILLRANGE, StartPos, length2)  ; выделяет текст используя текущий индикатор
		EndIf

		inSrt = firstMatchPos + length2 ; задать диапазон поиска
										; Устанавливает целевой диапазон поиска
		inEnd = ScintillaSendMessage(#Edit, #SCI_GETTEXTLENGTH) ; получает длину текста
																	; 	ScintillaSendMessage(#Edit, #SCI_SETTARGETRANGE, inSrt, inEnd) ; задать диапазон поиска
		ScintillaSendMessage(#Edit, #SCI_SETTARGETSTART, inSrt)	; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(#Edit, #SCI_SETTARGETEND, inEnd)	; до конца по длине текста

	ForEver
EndProcedure

; Получить выделенный текст из Scintilla
Procedure.s GetSelText()
	Protected txtLen, *buffer, text$
	txtLen = ScintillaSendMessage(#Edit, #SCI_GETSELTEXT, 0, 0) ; получает длину текста в байтах
	*buffer = AllocateMemory(txtLen + 2)         ; Выделяем память на длину текста и 1 символ на Null
	If *buffer                ; Если указатель получен, то
																	 ; получает текста
		ScintillaSendMessage(#Edit, #SCI_GETSELTEXT, txtLen + 1, *buffer)        ; получает текста
																				   ; Считываем значение из области памяти
		text$ = PeekS(*buffer, -1, #PB_UTF8)
		; 		MessageRequester("", text$)
		FreeMemory(*buffer)
		ProcedureReturn text$
	EndIf
	ProcedureReturn ""
EndProcedure

CompilerIf  #PB_Compiler_OS = #PB_OS_Linux

Procedure SizeWinInfo()
	ResizeGadget(#Edit2, #PB_Ignore, #PB_Ignore, WindowWidth(#WinInfo) - 10, WindowHeight(#WinInfo) - 10)
EndProcedure

Procedure.s GetInfo(prog$, key$)
	Protected PathPrg$, tmp, res$

	PathPrg$ = RTrim(GetPathPart(ProgramFilename()), "/")
	tmp = RunProgram(prog$, key$, PathPrg$, #PB_Program_Open | #PB_Program_Read)
	res$ = Chr(13)
	If tmp
		While ProgramRunning(tmp)
			If AvailableProgramOutput(tmp)
				res$ + ReadProgramString(tmp) + Chr(13)
			EndIf
		Wend
		CloseProgram(tmp)
	EndIf
; 	res$ = ReplaceString(res$, Chr(13) + "sd", Chr(13))
	res$ = Trim(res$, Chr(13))
	ProcedureReturn res$
EndProcedure

Structure btn
	id.i
	name.s
	arg.s
EndStructure

Procedure WinInfo()
	Protected prog$, key$, Width, Height, i, evg, evend, FontInfo$
	Protected NewList btn.btn()
	Static id_font
	
	prog$ = "lsblk"
	key$ = "-T -t -n -o name,UUID,MOUNTPOINT,FSTYPE,LABEL,SIZE -I8"
	FontInfo$ = "DejaVuSansMono"

	
	DisableWindow(#Window_0, 1)
	
	
; 	ExamineDesktops()
; 	Width = DesktopWidth(0))
	Width = WindowWidth(#Window_0) - 40
	Height = WindowHeight(#Window_0) - 40
; 	Limit(@Width, 500, DesktopWidth(0))
	If Width < 900
		Width = 900
	EndIf
	If Height > 600
		Height = 600
	EndIf
	If OpenWindow(#WinInfo, #PB_Ignore, #PB_Ignore, Width, Height, "Info (" + prog$ + ")", #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_0))
		
		If flgINI And OpenPreferences(ini$)
			If PreferenceGroup("info") And ExaminePreferenceKeys()
				i = 0
				evend = #btnLast
				While  NextPreferenceKey()
					AddElement(btn())
					btn()\id = #btnLast + i
					btn()\name = PreferenceKeyName()
					btn()\arg = PreferenceKeyValue()
					ButtonGadget(btn()\id, 55 * i + 0, 5, 50, 30, btn()\name)
					i + 1
				Wend
				evend = #btnLast + i - 1
			EndIf
			If Not id_font
				PreferenceGroup("Set")
				FontInfo$ = ReadPreferenceString("FontInfo" , "DejaVuSansMono")
			EndIf
			ClosePreferences()
		EndIf
		If ListSize(btn())
			FirstElement(btn())
			prog$ = btn()\name
			key$ = btn()\arg
		Else
			ButtonGadget(#btnlsblk, 5, 5, 50, 30, "lsblk")
			ButtonGadget(#btnblkid, 60, 5, 50, 30, "blkid")
		EndIf
		
		EditorGadget(#Edit2, 5, 40, Width - 10, Height - 10)
		
		If Not id_font And LoadFont(0, FontInfo$, 11)
			id_font = FontID(0)
		EndIf
		If id_font
			SetGadgetFont(#Edit2, id_font) ; Установить загруженный шрифт Arial 16 как новый стандарт
		EndIf
		SetGadgetText(#Edit2, GetInfo(prog$, key$))
		
		BindEvent(#PB_Event_SizeWindow, @SizeWinInfo(), #WinInfo)
		
		;-┌──Loop──┐
		Repeat
			Select WaitWindowEvent()
				Case #PB_Event_Gadget
					evg = EventGadget()
					Select evg
						Case #btnlsblk
							SetGadgetText(#Edit2, GetInfo("lsblk", "-T -t -n -o name,UUID,MOUNTPOINT,FSTYPE,LABEL,SIZE -I8"))
							SetWindowTitle(#WinInfo, "Info (lsblk)")
						Case #btnblkid
							SetGadgetText(#Edit2, GetInfo("blkid", ""))
							SetWindowTitle(#WinInfo, "Info (blkid)")
						Case #btnLast To evend
							i = evg - #btnLast
							SelectElement(btn(), i)
							SetGadgetText(#Edit2, GetInfo(btn()\name, btn()\arg))
							SetWindowTitle(#WinInfo, "Info (" + btn()\name + ")")
					EndSelect
				Case #PB_Event_CloseWindow
					Break
			EndSelect
		ForEver
	EndIf
	
	
	UnbindEvent(#PB_Event_SizeWindow, @SizeWinInfo(), #WinInfo)
	DisableWindow(#Window_0, 0)
	CloseWindow(#WinInfo)
	; 	EndIf
	
EndProcedure
	
	
CompilerEndIf


Procedure Limit(*Value.integer, Min, Max)
  If *Value\i < Min
    *Value\i = Min
  ElseIf *Value\i > Max
    *Value\i = Max
  EndIf
EndProcedure


	
Procedure WinFind()
	Protected tmp$, SearchText$, ReplacementText$, flgCase, Pos, i
	Static flgFindClass, flgFindCode, flgFinditem
	
	DisableWindow(#Window_0, 1)
	
;- 	GUI Search
	If OpenWindow(#WinFind, #PB_Ignore, #PB_Ignore, 475, 185, "Найти и заменить", #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_0))
		

		TextGadget(#txt1, 5, 8, 59, 17, "Найти")
		TextGadget(#txt2, 5, 42, 59, 17, "Замена")
		StringGadget(#strg1, 65, 5, 400, 27, "")
		StringGadget(#strg2, 65, 40, 400, 27, "")
		ButtonGadget(#btnReplaceAll, 345, 75, 120, 40, "Заменить всё")
		ButtonGadget(#btnCount, 345, 120, 120, 40, "Подсчитать")
		CheckBoxGadget(#chCase, 165, 75, 175, 25, "Учитывать регистр")
; 		CheckBoxGadget(#chRegExp, 5, 93, 185, 20, "Регулярное выражение")
		CheckBoxGadget(#chFindItem, 5, 75, 155, 25, "Искать в пунктах")
		If flgFinditem
			SetGadgetState(#chFindItem, #PB_Checkbox_Checked)
		EndIf
		CheckBoxGadget(#chFindClass, 5, 100, 155, 25, "Искать в классах")
		If flgFindClass
			SetGadgetState(#chFindClass, #PB_Checkbox_Checked)
		EndIf
		CheckBoxGadget(#chFindCode, 5, 125, 155, 25, "Искать в коде")
		If flgFindCode
			SetGadgetState(#chFindCode, #PB_Checkbox_Checked)
		EndIf
		TextGadget(#StatusBar, 5, 185 - 25, 475 - 5, 25, "AZJIO 2024")
		
; 		CompilerIf  #PB_Compiler_OS = #PB_OS_Windows
; 			If GetActiveGadget() = #StrField
; 				SendMessage_(GadgetID(#StrField), #WM_COPY, 0, 0)
; 			EndIf
; 		CompilerEndIf
		tmp$ = GetSelText()
		If Asc(tmp$) And (FindString(tmp$, #LF$) Or FindString(tmp$, #CR$))
			tmp$ = ""
		EndIf
		If Asc(tmp$)
			SetGadgetText(#strg1, tmp$)
		EndIf
		
		;-┌──Loop──┐
		Repeat
			Select WaitWindowEvent()
				Case #PB_Event_Gadget
					Select EventGadget()
						Case #btnCount
							i = 0
							SearchText$ = GetGadgetText(#strg1)
							If Not Asc(SearchText$)
								SetGadgetText(#StatusBar, "Поля поиска пусты")
								Continue
							EndIf
							ReplacementText$ = GetGadgetText(#strg2)
							If GetGadgetState(#chCase) & #PB_Checkbox_Checked
								flgCase = #PB_String_CaseSensitive
							Else
								flgCase = #PB_String_NoCase
							EndIf
							
							flgFinditem = Bool(GetGadgetState(#chFindItem) & #PB_Checkbox_Checked)
							flgFindClass = Bool(GetGadgetState(#chFindClass) & #PB_Checkbox_Checked)
							flgFindCode = Bool(GetGadgetState(#chFindCode) & #PB_Checkbox_Checked)
							If Not (flgFindCode + flgFindClass + flgFinditem)
								SetGadgetText(#StatusBar, "Не выбраны места для поиска, где искать?")
								Continue ; не где искать
							EndIf
							ForEach MenuEntryList()
								If flgFindClass
									Pos = 0
									Repeat
										Pos = FindString(MenuEntryList()\Class , SearchText$, Pos + 1, flgCase)
										i + 1
									Until Not Pos
									i - 1
								EndIf
; 								If Asc(MenuEntryList()\Name) = Asc(SepCode$)
								If MenuEntryList()\Name = SepCode$
									If flgFindCode
										Pos = 0
										Repeat
											Pos = FindString(MenuEntryList()\Code , SearchText$, Pos + 1, flgCase)
											i + 1
										Until Not Pos
										i - 1
									EndIf
								Else
									If flgFinditem
										Pos = 0
										Repeat
											Pos = FindString(MenuEntryList()\Code , SearchText$, Pos + 1, flgCase)
											i + 1
										Until Not Pos
										i - 1
									EndIf
								EndIf
							Next
							SetGadgetText(#StatusBar, "Найдено: " + Str(i))
							
						Case #btnReplaceAll
							SearchText$ = GetGadgetText(#strg1)
							If Not Asc(SearchText$)
								SetGadgetText(#StatusBar, "Поля поиска пусты")
								Continue
							EndIf
							ReplacementText$ = GetGadgetText(#strg2)
							If GetGadgetState(#chCase) & #PB_Checkbox_Checked
								flgCase = #PB_String_CaseSensitive
							Else
								flgCase = #PB_String_NoCase
							EndIf
							
							flgFinditem = Bool(GetGadgetState(#chFindItem) & #PB_Checkbox_Checked)
							flgFindClass = Bool(GetGadgetState(#chFindClass) & #PB_Checkbox_Checked)
							flgFindCode = Bool(GetGadgetState(#chFindCode) & #PB_Checkbox_Checked)
							If Not (flgFindCode + flgFindClass + flgFinditem)
								SetGadgetText(#StatusBar, "Не выбраны места для поиска, где искать?")
								Continue ; не где искать
							EndIf
							ForEach MenuEntryList()
								If flgFindClass
									MenuEntryList()\Class = ReplaceString(MenuEntryList()\Class, SearchText$, ReplacementText$, flgCase)
								EndIf
; 								If Asc(MenuEntryList()\Name) = Asc(SepCode$)
								If MenuEntryList()\Name = SepCode$
									If flgFindCode
										MenuEntryList()\Code = ReplaceString(MenuEntryList()\Code, SearchText$, ReplacementText$, flgCase)
									EndIf
								Else
									If flgFinditem
										MenuEntryList()\Code = ReplaceString(MenuEntryList()\Code, SearchText$, ReplacementText$, flgCase)
									EndIf
								EndIf
							Next
							SetGadgetText(#StatusBar, "Выполнено")
					EndSelect
				Case #PB_Event_CloseWindow
					Break
			EndSelect
		ForEver
	EndIf
	
	
	DisableWindow(#Window_0, 0)
	CloseWindow(#WinFind)
	; 	EndIf
	
EndProcedure
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 473
; FirstLine = 437
; Folding = 4--48--
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = !Интернет\Scintilla\Windows_x64\Grub2-generator.exe
; CompileSourceDirectory
; Compiler = PureBasic 6.04 LTS - C Backend (Windows - x86)
; EnableBuildCount = 0
; IncludeVersionInfo
; VersionField0 = 0.7.6.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = Grub2-generator
; VersionField4 = 0.7.6
; VersionField6 = Grub2-generator
; VersionField9 = AZJIO