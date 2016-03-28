# Generate C Functions wrappers for the Ring programming language
# To execute : run parsec test.cf [test.c]
# Author : Mahmoud Fayed <msfclipper@yahoo.com>

/* Data Structure & Usage
		C_FUNC_INS
	List [  C_INS_CODE    , C_FUNC_CODE  ]	
	     [  C_INS_FUNCTION, C_FUNC_OUTPUT, C_FUNC_NAME , C_FUNC_PARA , C_CLASS_NAME]
	     [  C_INS_REGISTER, C_FUNC_OUTPUT, C_FUNC_NAME , C_FUNC_PARA , C_CLASS_NAME]
	     [  C_INS_STRUCT  , C_FUNC_STRUCTDATA  ]	
	     [  C_INS_RUNCODE , C_FUNC_CODE ]
	     [  C_INS_CLASS   , C_FUNC_CODE ]
	The first record is used for generating code written in <code> and </code>
	The second record is used for function prototype 
	The third record is used for function registration only <register> and </register>
	we can put comments between <comment> and </comment>
	The record no. 4 is used for defining functions to create/destroy
	struct. used for <struct> and </struct>
	We can put function start when we generate function for strucutres
	between <funcstart> and </funcstart>
	We can execute ring code during code generation by using
	<runcode> and </runcode>
	We can define classes between <class> and </class>
	using <nodllstartup> we can avoid #include "ring.h", We need this to write our startup code. 
	using <libinitfunc> we can change the function name that register the library functions
	using <ignorecpointertype> we can ignore pointer type check         
	using <filter> and </filter> we can include/execlude parts of the configuration file
	based on a condition
	for example <filter> iswindows() 
			... functions related to windows
		    </filter>
*/

C_INS_FUNCTION  = 1
C_INS_CODE	= 2
C_INS_REGISTER  = 3
C_INS_COMMENT   = 4
C_INS_STRUCT    = 5
C_INS_FUNCSTART = 6
C_INS_RUNCODE   = 7
C_INS_CLASS	= 8

C_FUNC_INS	= 1
C_FUNC_OUTPUT 	= 2
C_FUNC_NAME 	= 3
C_FUNC_PARA 	= 4

C_CLASS_NAME    = 5

C_FUNC_CODE 	= 2

C_FUNC_STRUCTDATA = 2

C_TYPE_VOID 	= 1
C_TYPE_NUMBER 	= 2
C_TYPE_STRING 	= 3
C_TYPE_POINTER 	= 4
C_TYPE_UNKNOWN 	= 5

$cFuncStart = ""
$aStructFuncs = []

aNumberTypes = ["int","float","double","bool","unsigned char","size_t",
"long int","int8_t","int16_t","int32_t","int64_t",
"uint8_t","uint16_t","uint32_t","uint64_t"]

aStringTypes = ["const char *","char const *","char *"]

aNewMethodName = []	# list store new method name ["class name","method name","new method name"]
C_NMN_CLASSNAME = 1
C_NMN_METHODNAME = 2
C_NMN_NEWMETHODNAME = 3

aBeforeReturn = []	# array include arrays ["type","code after calling the method
			# Ex: ["QString",".toStdString().c_str()"]
C_BR_TYPENAME = 1
C_BR_CODE     = 2

$cClassName = ""
$cNewPara = ""
$cClassParent = ""

$aClassesList = []
C_CLASSESLIST_NAME = 1
C_CLASSESLIST_PARA = 2
C_CLASSESLIST_PARENT = 3
C_CLASSESLIST_CODENAME = 4
C_CLASSESLIST_PASSVMPOINTER = 5
C_CLASSESLIST_ABSTRACT = 6

$lNodllstartup = false	# when used, ring.h will not be included automatically
$cLibInitFunc = "ringlib_init"

$lIgnoreCPointerTypeCheck = false

Func Main
	if len(sysargv) < 3
		See "Input : filename.cf is missing!" + nl
		bye
	ok
	cFile = sysargv[3]
	cStr = read(cFile)
	if iswindows()
		cStr = substr(cStr,char(13)+char(10),nl)
	ok
	aList = str2list(cStr)
	aData = []
	lFlag = C_INS_FUNCTION
	for cLine in aList
		cLine = trim(cLine)
		see "ReadLine : " + cLine + nl
		if cLine = NULL and lflag != C_INS_CODE
			loop
		ok
		if cLine = "<code>"
			lflag = C_INS_CODE
			loop
		but cLine = "<register>"
			lflag = C_INS_REGISTER
			loop
		but cLine = "<comment>"
			lFlag = C_INS_COMMENT
			loop
		but cLine = "<struct>"
			lFlag = C_INS_STRUCT
			loop
		but cLine = "<funcstart>"
			lFlag = C_INS_FUNCSTART
			loop
		but cLine = "<runcode>"
			lFlag = C_INS_RUNCODE
			loop
		but cLine = "<class>"
			lFlag = C_INS_CLASS
			loop
		but cLine = "<nodllstartup>"
			$lNodllstartup = true
			loop
		but left(cLine,13) = "<libinitfunc>"
			$cLibInitFunc = trim(substr(cLine,14))
			loop
		but cLine = "<ignorecpointertype>"
			$lIgnoreCPointerTypeCheck = true
			loop
		but left(cLine,8) = "<filter>"
			cFilter = "lInclude = " + trim(substr(cLine,9))
			see "Execute Filter : " + cFilter + nl
			eval(cFilter)
			See "Filter output : " + lInclude + nl
			lFilterFlag = lFlag 
			if lInclude = false
				lFlag = C_INS_COMMENT							
			ok
			loop
		but cLine = "</filter>"
			lFlag = lFilterFlag 
			loop
		but cLine = "</code>" or cLine = "</register>" or 
		    cLine = "</comment>" or cLine = "</struct>" or
		    cLine = "</funcstart>" or cLine = "</runcode>" or
		    cLine = "</class>" 
			lFlag = C_INS_FUNCTION			
			loop
		ok
		if lFlag = C_INS_FUNCTION 
			aData + ThreeParts(cLine)
			aData[len(aData)] + $cClassName
		but lFlag = C_INS_REGISTER
			aData + ThreeParts(cLine)
			aData[len(aData)][1] = C_INS_REGISTER
			aData[len(aData)] + $cClassName
		but lFlag = C_INS_CODE
			aData + [C_INS_CODE,cLine]
		but lFlag = C_INS_STRUCT
			aData + [C_INS_STRUCT,cLine]			
		but lFlag = C_INS_FUNCSTART
			$cFuncStart = trim(lower(cLine)) + "_"
		but lFlag = C_INS_RUNCODE
			aData + [C_INS_RUNCODE,cLine]
		but lFlag = C_INS_CLASS
			aData + [C_INS_CLASS,cLine]
			cValue = trim(cLine)
			if left(lower(cValue),5) = "name:"
				$cClassName = trim(substr(cValue,6))
			ok
		ok
	next
	cCode = GenCode(aData)
	if len(sysargv) = 3
		see cCode
	else
		WriteFile(sysargv[4],cCode)
	ok
	if len(sysargv) = 5  # Generate Ring Classes for C++ Classes
		cCode = GenRingCode(aData)
		WriteFile(sysargv[5],cCode)
	ok

Func WriteFile cFileName,cCode
	See "Writing file : " + cFileName + nl + 
	    "Size : " + len(cCode) + " Bytes" + nl
	aCode = str2list(cCode)
	fp = fopen(cFileName,"wb")
	for cLine in aCode
		fwrite(fp,cLine+char(13)+char(10))	
	next
	fclose(fp)

Func ThreeParts cLine
	# Get three parts (output - function name - parameters)
	nPos1 = substr(cLine,"(")
	for x = nPos1 to 1 step -1
		switch cLine[x] 	
		on " " 
			nPos2 = x
			cFuncName = substr(cLine,nPos2+1,nPos1-nPos2-1)
			exit
		on "*"
			nPos2 = x + 1
			cFuncName = substr(cLine,nPos2,nPos1-nPos2)
			exit
		off
	next

	cFuncOutput = left(cLine,nPos2-1)
	cFuncPara = substr(cLine,nPos1+1,len(cLine)-nPos1-1)
	return [C_INS_FUNCTION,cFuncOutput,cFuncName,ParaList(cFuncPara)]

Func ParaList cPara
	# convert string of parameters separated by , to a list
	aList = []
	nPos = substr(cPara,",") 
	while nPos
		aList + ParaTypeNoName( left(cPara,nPos-1) )
		cPara = substr(cPara,nPos+1)
		nPos = substr(cPara,",") 
	end
	aList + ParaTypeNoName( cPara )
	return aList

Func ParaTypeNoName cLine
	# get the parameter type and name, remove name and keep the type only
	cLine = trim(cLine)
	for x = len(cLine) to 1 step -1
		if cLine[x] = "*" or cLine[x] = " "
			return left(cLine,x)
		ok
	next
	return cLine

Func VarTypeID cType
	# get type as string - return type as number
	# 1 = void 2 = Number   3 = String   4 = Pointer  5 - UnKnown
	cType = Trim(cType)
	if cType = "void"
		return C_TYPE_VOID
	but find(aNumberTypes,cType) > 0
		return C_TYPE_NUMBER
	but find(aStringTypes,cType) > 0
		return C_TYPE_STRING
	but right(cType,1) = "*"
		return C_TYPE_POINTER
	else
		return C_TYPE_UNKNOWN
	ok

Func GenCode aList
	cCode = ""
	cCode += GenDLLStart()
	# Generate Classes List at first
	for aFunc in aList
		if aFunc[C_FUNC_INS] = C_INS_CLASS
			cValue = trim(aFunc[C_INS_CODE])
			if left(lower(cValue),5) = "name:"
				cClassName = trim(substr(cValue,6))
				See "Class Name : " + cClassName + nl
				$aClassesList + [cClassName,"","","",false,false]
			ok
		ok
	next
		
	#
	for aFunc in aList
		if aFunc[C_FUNC_INS] = C_INS_FUNCTION
			if $cClassName = ""
				cCode += GenFuncCode(aFunc)
			else
				cCode += GenMethodCode(aFunc)
			ok
		but aFunc[C_FUNC_INS] = C_INS_CODE
			cCode += aFunc[C_INS_CODE] + nl
		but aFunc[C_FUNC_INS] = C_INS_STRUCT
			cCode += GenStruct(aFunc)
		but aFunc[C_FUNC_INS] = C_INS_RUNCODE
			Try
				eval(aFunc[C_INS_CODE])
			Catch
				See "Error executing code : " + aFunc[C_INS_CODE] + nl
			Done
		but aFunc[C_FUNC_INS] = C_INS_CLASS
			cValue = trim(aFunc[C_INS_CODE])
			if left(lower(cValue),5) = "name:"
				$cClassName = trim(substr(cValue,6))
				See "Class Name : " + $cClassName + nl
				# $aClassesList + [$cClassName,"","","",false,false]
			but left(lower(cValue),5) = "para:"
				$cNewPara = trim(substr(cValue,6))
				See "Parameters : " + $cNewPara + nl
				nIndex = find($aClassesList,$cClassName,1)
				$aClassesList[nIndex][C_CLASSESLIST_PARA] = $cNewPara
			but left(lower(cValue),7) = "parent:"
				$cClassParent = trim(substr(cValue,8))
				See "Class Parent : " + $cClassParent + nl
				nIndex = find($aClassesList,$cClassName,1)
				$aClassesList[nIndex][C_CLASSESLIST_PARENT] = $cClassParent
			but left(lower(cValue),9) = "codename:"
				cCodeName = trim(substr(cValue,10))
				See "Class Code Name : " + cCodeName + nl
				nIndex = find($aClassesList,$cClassName,1)
				$aClassesList[nIndex][C_CLASSESLIST_CODENAME] = cCodeName
			but lower(cValue) = "passvmpointer"
				nIndex = find($aClassesList,$cClassName,1)
				$aClassesList[nIndex][C_CLASSESLIST_PASSVMPOINTER] = true
			but lower(cValue) = "abstract"
				nIndex = find($aClassesList,$cClassName,1)
				$aClassesList[nIndex][C_CLASSESLIST_ABSTRACT] = true
				SEE "Class : Abstract" + nl		
			but lower(cValue) = "nonew"
				nIndex = find($aClassesList,$cClassName,1)
				del($aClassesList,nIndex)		
			ok
		ok
	next
	cCode += GenNewFuncForClasses(aList)
	cCode += GenDeleteFuncForClasses(aList)
	cCode += GenFuncPrototype(aList)
	return cCode

Func GenDLLStart
	if $lNodllstartup return "" ok
	return 	'#include "ring.h"' + nl + nl +
		'#ifdef _WIN32' + nl +
		"#define RING_DLL __declspec(dllexport)" + nl + 
		'#else' + nl +
		"#define RING_DLL extern" + nl +
		'#endif' + nl + nl 

Func GenFuncPrototype aList
	cCode = "RING_DLL void "+$cLibInitFunc+"(RingState *pRingState)" + nl +
		"{" + nl
	for aFunc in aList
		if aFunc[C_FUNC_INS] = C_INS_FUNCTION OR aFunc[C_FUNC_INS] = C_INS_REGISTER
			if len(aFunc) >= C_CLASS_NAME
				cClassName = aFunc[C_CLASS_NAME]
			else
				cClassName = $cClassName
			ok
			cCode += GenTabs(1) + 'ring_vm_funcregister("' 
			if cClassName != ""
				cCode += lower(cClassName) + "_" 
			ok
			cCode += lower(aFunc[C_FUNC_NAME]) + '",' +
				  "ring_"
			if cClassName != ""
				cCode += cClassName + "_" 
			ok
			cCode += aFunc[C_FUNC_NAME] + ");" + nl
		ok
	next
	for cFunc in $aStructFuncs
			cCode += GenTabs(1) + 'ring_vm_funcregister("' + cFunc + '",' +
				  "ring_"+cFunc + ");" + nl
	next
	cCode += "}" + nl
	return cCode

Func GenFuncCode aList
	cCode = nl+"RING_FUNC(" + "ring_"+aList[C_FUNC_NAME] + ")" + nl +
	 	"{" + nl +
	 	GenFuncCodeCheckParaCount(aList) +
	 	GenFuncCodeCheckParaType(aList) +
		GenFuncCodeCallFunc(aList)+
	 	"}" + nl + nl 
	return cCode

Func GenFuncCodeCheckParaCount aList
	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	cCode = GenTabs(1) + "if ( RING_API_PARACOUNT != "+nCount+" ) {" + nl +
		GenTabs(2) +"RING_API_ERROR("
	switch nCount
	on 1 
		cCode += "RING_API_MISS1PARA"
	on 2
		cCode += "RING_API_MISS2PARA"
	on 3
		cCode += "RING_API_MISS3PARA"
	on 4
		cCode += "RING_API_MISS4PARA"
	other
		cCode += "RING_API_BADPARACOUNT"
	off
	cCode += ");" + nl +
		GenTabs(2) +"return ;" + nl +
		GenTabs(1) +"}" + nl
	return cCode

Func GenFuncCodeCheckParaType aList
	cCode = ""
	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	if nCount > 0
		for t = 1 to len(aPara)
			x = aPara[t]
			switch VarTypeID(x)
			on C_TYPE_NUMBER
				cCode += GenTabs(1) + "if ( ! RING_API_ISNUMBER("+t+") ) {" + nl +
					 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
					 GenTabs(2) + "return ;" + nl +
					 GenTabs(1) + "}" + nl
			on C_TYPE_STRING
				cCode += GenTabs(1) + "if ( ! RING_API_ISSTRING("+t+") ) {" + nl +
					 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
					 GenTabs(2) + "return ;" + nl +
					 GenTabs(1) + "}" + nl
			on C_TYPE_POINTER
				if GenPointerType(x) = "int" or GenPointerType(x) = "double"
					# pointer to int, i.e. int *
					cCode += GenTabs(1) + "if ( ! RING_API_ISSTRING("+t+") ) {" + nl +
						 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
						 GenTabs(2) + "return ;" + nl +
						 GenTabs(1) + "}" + nl
				else
					cCode += GenTabs(1) + "if ( ! RING_API_ISPOINTER("+t+") ) {" + nl +
						 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
						 GenTabs(2) + "return ;" + nl +
						 GenTabs(1) + "}" + nl
				ok
			off
		next
	ok
	return cCode

Func GenFuncCodeCallFunc aList
	cCode = GenTabs(1)
	lRet = true
	lUNKNOWN = false
	lRetPointer = false
	switch VarTypeID(aList[C_FUNC_OUTPUT])
		on C_TYPE_VOID
			lRet = false
		on C_TYPE_NUMBER
			cCode += "RING_API_RETNUMBER("
		on C_TYPE_STRING
			cCode += "RING_API_RETSTRING("
		on C_TYPE_POINTER
			lRetPointer = true
			cCode += "RING_API_RETCPOINTER("
		on C_TYPE_UNKNOWN
			cCode += "{" + nl + 
				GenTabs(2) + aList[C_FUNC_OUTPUT] + " *pValue ; " + nl +
				GenTabs(2) + "pValue = (" + aList[C_FUNC_OUTPUT] + 
				" *) malloc(sizeof("+aList[C_FUNC_OUTPUT]+")) ;" + nl +
				GenTabs(2) + "*pValue = " 
			lRet = false
			lUNKNOWN = true
	off
	cCode += aList[C_FUNC_NAME] + "(" +
		GenFuncCodeGetParaValues(aList) + ")"
	if lRet		
		if lRetPointer
			cCode += ',"' + GenPointerType(aList[C_FUNC_OUTPUT]) + '"'
		ok
		cCode += ")"
	ok
	cCode +=  ";" + nl
	cCode += GenFuncCodeFreeNotAssignedPointers(aList)
	if lUNKNOWN 	# Generate code to convert struct to struct *
		cCode += GenTabs(2) + 'RING_API_RETCPOINTER(pValue,"' + trim(aList[C_FUNC_OUTPUT]) +
			 '");' + nl + GenTabs(1) + "}" + nl
	ok
	# Accept int values, when the C function take int * as parameter
	cCode += GenFuncCodeGetIntValues(aList)
	return cCode

Func GenFuncCodeGetParaValues aList
	cCode = ""
	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	if nCount > 0
		for t = 1 to len(aPara)
			if t > 1	# separator between parameters	
				cCode += ","
			ok
			x = aPara[t]
			switch VarTypeID(x)
			on C_TYPE_NUMBER
				cCode += " (" + x + ") " + "RING_API_GETNUMBER(" + t + ")"
			on C_TYPE_STRING
				cCode += "RING_API_GETSTRING(" + t + ")"
			on C_TYPE_POINTER
				if GenPointerType(x) = "int"
					cCode += "RING_API_GETINTPOINTER(" + t + ")"
				but GenPointerType(x) = "double"
					cCode += "RING_API_GETDOUBLEPOINTER(" + t + ")"
				else
					cCode += "(" + GenPointerType(x) + " *) RING_API_GETCPOINTER(" + t +',"'+GenPointerType(x)+ '")'
				ok
			on C_TYPE_UNKNOWN
				cCode += "* (" + x + " *) RING_API_GETCPOINTER(" + t +',"'+trim(x)+'")'
			off
		next
	ok
	return cCode

Func GenFuncCodeGetIntValues aList
	cCode = ""
	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	if nCount > 0
		for t = 1 to len(aPara)
			x = aPara[t]
			if VarTypeID(x) = C_TYPE_POINTER
				if GenPointerType(x) = "int"
					cCode += GenTabs(1) + 
					"RING_API_ACCEPTINTVALUE(" + t + ") ;" + nl
				ok
			ok
		next
	ok
	return cCode

Func GenFuncCodeFreeNotAssignedPointers aList
	cCode = ""
	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	if nCount > 0
		for t = 1 to len(aPara)
			x = aPara[t]
			if VarTypeID(x) = C_TYPE_UNKNOWN
				cCode += GenTabs(1) + "if (RING_API_ISCPOINTERNOTASSIGNED(" + t + "))" + nl
				cCode += GenTabs(2) + "free(RING_API_GETCPOINTER("+t+',"'+GenPointerType(x)+'"));' + nl
			ok
		next
	ok
	return cCode

Func GenPointerType x
	x = substr(x,"const","")
	x = substr(x,"*","")
	x = trim(x)
	return x

Func GenTabs x
	return copy(char(9),x)

Func ParaCount aList
	# get list of paramters, return parameters count
	if len(aList) > 1
		return len(aList)
	else
		if VarTypeID(alist[1]) = C_TYPE_VOID
			return 0
		else
			return 1
		ok
	ok

Func GenStruct	aFunc
	# this function parse struct information 
	# struct_name { struct_members }
	# strucut_members are separated by comma (,)	
	aStructMembers = []
	cLine = aFunc[C_FUNC_STRUCTDATA]
	nPos = substr(cLine,"{")
	if nPos > 0
		# Get Struct Members and store it in aStructMembers
		cStruct = trim(left(cLine,nPos-1))		
		cStructMembers = substr(cLine,nPos+1)
		nPos = substr(cStructMembers,"}")
		if nPos > 0
			cStructMembers = left(cStructMembers,nPos-1)
			cStructMembers = substr(cStructMembers,",",nl)
			aStructMembers = str2list(cStructMembers)
			for x in aStructMembers x = trim(x) next		
		ok
	else
		cStruct = trim(cLine)
	ok
	# We have struct_name in cStruct and struct_members in aStructMembers
	cCode = ""
	# Generate Functions to Create the Struct
	cFuncName = $cFuncStart+"new_"+lower(cStruct)
	$aStructFuncs + cFuncName
	cCode += "RING_FUNC(ring_"+cFuncName+")" + nl +
			"{" + nl + 
			GenTabs(1) + cStruct + " *pMyPointer ;" + nl +
			GenTabs(1) + "pMyPointer = (" + cStruct + " *) malloc(sizeof(" +
			cStruct + ")) ;" + nl +
			GenTabs(1) + "if (pMyPointer == NULL) " + nl +
			GenTabs(1) + "{" + nl +
			GenTabs(2) + "RING_API_ERROR(RING_OOM);" + nl + 
			GenTabs(2) + "return ;" + nl +
			GenTabs(1) + "}" + nl +
			GenTabs(1) + "RING_API_RETCPOINTER(pMyPointer,"+
			'"'+cStruct  +'");' + nl +
			"}" + nl + nl
	# Generate Functions to Destroy the Struct
	cFuncName = $cFuncStart+"destroy_"+lower(cStruct)
	$aStructFuncs + cFuncName
	cCode += "RING_FUNC(ring_"+cFuncName+")" + nl +
			"{" + nl + 
			GenTabs(1) + cStruct + " *pMyPointer ;" + nl +
			GenTabs(1) + "if ( RING_API_PARACOUNT != 1 ) {" + nl +
			GenTabs(2) +"RING_API_ERROR(RING_API_MISS1PARA) ;" + nl +
			GenTabs(2) + "return ;" + nl +
			GenTabs(1) + "}" + nl +
			GenTabs(1) + "if ( ! RING_API_ISPOINTER(1) ) { " + nl +
			GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
			GenTabs(2) + "return ;" + nl + 
			GenTabs(1) + "}" + nl +
			GenTabs(1) + "pMyPointer = RING_API_GETCPOINTER(1," +
			'"'+cStruct  +'");' + nl +
			GenTabs(1) + "free(pMyPointer) ;" + nl +						
			"}" + nl + nl
	# Generate Functions to Get Struct Members Values
	# We expect the members to be of type (numbers)
	# To Do : Generate Functions to Set Struct Members Values
	# To Do : Deal with struct members of type : strings
	for x in aStructMembers
		cItem = substr(x,".","_")
		cFuncName = $cFuncStart+"get_"+lower(cStruct)+"_"+cItem
		$aStructFuncs + cFuncName
		cCode += "RING_FUNC(ring_"+cFuncName+")" + nl +
			"{" + nl + 
			GenTabs(1) + cStruct + " *pMyPointer ;" + nl +
			GenTabs(1) + "if ( RING_API_PARACOUNT != 1 ) {" + nl +
			GenTabs(2) +"RING_API_ERROR(RING_API_MISS1PARA) ;" + nl +
			GenTabs(2) + "return ;" + nl +
			GenTabs(1) + "}" + nl +
			GenTabs(1) + "if ( ! RING_API_ISPOINTER(1) ) { " + nl +
			GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
			GenTabs(2) + "return ;" + nl + 
			GenTabs(1) + "}" + nl +
			GenTabs(1) + "pMyPointer = RING_API_GETCPOINTER(1," +
			'"'+cStruct  +'");' + nl +			
			GenTabs(1) + "RING_API_RETNUMBER(pMyPointer->"+x+");" + nl +
			"}" + nl + nl
	next
	return cCode

Func GenMethodCode aList
	cCode = nl+"RING_FUNC(" + "ring_"+$cClassName+"_"+
				aList[C_FUNC_NAME] + ")" + nl +
	 	"{" + nl +
	 	GenMethodCodeCheckParaCount(aList) +
		GenMethodCodeCheckIgnorePointerType() +
	 	GenMethodCodeCheckParaType(aList) +
		GenMethodCodeCallFunc(aList)+
	 	"}" + nl + nl 
	return cCode


Func GenMethodCodeCheckIgnorePointerType
	if $lIgnoreCPointerTypeCheck	
		return GenTabs(1) + "RING_API_IGNORECPOINTERTYPE ;" + nl
	ok

Func GenMethodCodeGetClassCodeName
	nIndex = find($aClassesList,$cClassName,1)
	if $aClassesList[nIndex][C_CLASSESLIST_CODENAME] != NULL
		cClassCodeName = $aClassesList[nIndex][C_CLASSESLIST_CODENAME]
	else
		cClassCodeName = $aClassesList[nIndex][C_CLASSESLIST_NAME]
	ok
	return cClassCodeName

Func GenMethodCodeCheckParaCount aList

	cClassCodeName = GenMethodCodeGetClassCodeName()

	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara) + 1
	cCode =  GenTabs(1) + cClassCodeName + " *pObject ;" + nl +
	 	 GenTabs(1) + "if ( RING_API_PARACOUNT != "+nCount+" ) {" + nl +
		 GenTabs(2) +"RING_API_ERROR("
	switch nCount
	on 1 
		cCode += "RING_API_MISS1PARA"
	on 2
		cCode += "RING_API_MISS2PARA"
	on 3
		cCode += "RING_API_MISS3PARA"
	on 4
		cCode += "RING_API_MISS4PARA"
	other
		cCode += "RING_API_BADPARACOUNT"
	off
	cCode += ");" + nl +
		GenTabs(2) +"return ;" + nl +
		GenTabs(1) +"}" + nl
	return cCode

Func GenMethodCodeCheckParaType aList
	cClassCodeName = GenMethodCodeGetClassCodeName()
	cCode = GenTabs(1) + "if ( ! RING_API_ISPOINTER(1) ) {" + nl +
			 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
			 GenTabs(2) + "return ;" + nl +
			 GenTabs(1) + "}" + nl +
			 GenTabs(1) + "pObject = ("+
			 cClassCodeName+" *) RING_API_GETCPOINTER(1," + '"'+
			 $cClassName+'"' + ");"+nl

	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	if nCount > 0
		for t = 1 to len(aPara)
			x = aPara[t]
			t++ # avoid the object pointer
			switch VarTypeID(x)
			on C_TYPE_NUMBER
				cCode += GenTabs(1) + "if ( ! RING_API_ISNUMBER("+t+") ) {" + nl +
					 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
					 GenTabs(2) + "return ;" + nl +
					 GenTabs(1) + "}" + nl
			on C_TYPE_STRING
				cCode += GenTabs(1) + "if ( ! RING_API_ISSTRING("+t+") ) {" + nl +
					 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
					 GenTabs(2) + "return ;" + nl +
					 GenTabs(1) + "}" + nl
			on C_TYPE_POINTER
				if GenPointerType(x) = "int" or GenPointerType(x) = "double"
					# pointer to int, i.e. int *
					cCode += GenTabs(1) + "if ( ! RING_API_ISSTRING("+t+") ) {" + nl +
						 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
						 GenTabs(2) + "return ;" + nl +
						 GenTabs(1) + "}" + nl
				else
					cCode += GenTabs(1) + "if ( ! RING_API_ISPOINTER("+t+") ) {" + nl +
						 GenTabs(2) + "RING_API_ERROR(RING_API_BADPARATYPE);" + nl +
						 GenTabs(2) + "return ;" + nl +
						 GenTabs(1) + "}" + nl
				ok
			off
			t-- # ignore effect of avoiding the object pointer
		next
	ok
	return cCode

Func GenMethodCodeCallFunc aList
	cCode = GenTabs(1)
	lRet = true
	lUNKNOWN = false
	lRetPointer = false
	switch VarTypeID(aList[C_FUNC_OUTPUT])
		on C_TYPE_VOID
			lRet = false
		on C_TYPE_NUMBER
			cCode += "RING_API_RETNUMBER("
		on C_TYPE_STRING
			cCode += "RING_API_RETSTRING("
		on C_TYPE_POINTER
			lRetPointer = true
			cCode += "RING_API_RETCPOINTER("
		on C_TYPE_UNKNOWN
			if find($aClassesList,aList[C_FUNC_OUTPUT],1) > 0
				cCode += "{" + nl + 
				GenTabs(2) + aList[C_FUNC_OUTPUT] + " *pValue ; " + nl +
				GenTabs(2) + "pValue = new " + aList[C_FUNC_OUTPUT] + 
				"() ;" + nl +
				GenTabs(2) + "*pValue = " 
			else
				cCode += "{" + nl + 
				GenTabs(2) + aList[C_FUNC_OUTPUT] + " *pValue ; " + nl +
				GenTabs(2) + "pValue = (" + aList[C_FUNC_OUTPUT] + 
				" *) malloc(sizeof("+aList[C_FUNC_OUTPUT]+")) ;" + nl +
				GenTabs(2) + "*pValue = " 
			ok

			lRet = false
			lUNKNOWN = true
	off
	cCode += "pObject->"+aList[C_FUNC_NAME] + "(" +
		GenMethodCodeGetParaValues(aList) + ")"

	#Check before return list for any 
	if len(aBeforeReturn) > 0
		nIndex = find(aBeforeReturn,aList[C_FUNC_OUTPUT],C_BR_TYPENAME)
		if nIndex > 0
			cCode += aBeforeReturn[nIndex][C_BR_CODE]
		ok

	ok

	if lRet		
		if lRetPointer
			cCode += ',"' + GenPointerType(aList[C_FUNC_OUTPUT]) + '"'
		ok
		cCode += ")"
	ok
	cCode +=  ";" + nl
	
	cCode += GenFuncCodeFreeNotAssignedPointers(aList)

	if lUNKNOWN 	# Generate code to convert struct to struct *
		cCode += GenTabs(2) + 'RING_API_RETCPOINTER(pValue,"' + trim(aList[C_FUNC_OUTPUT]) +
			 '");' + nl + GenTabs(1) + "}" + nl
	ok
	# Accept int values, when the C function take int * as parameter
	cCode += GenFuncCodeGetIntValues(aList)
	return cCode

Func GenMethodCodeGetParaValues aList
	cCode = ""
	aPara = aList[C_FUNC_PARA]
	nCount = ParaCount(aPara)
	if nCount > 0
		for t = 1 to len(aPara)
			if t > 1	# separator between parameters	
				cCode += ","
			ok
			x = aPara[t]
			t++ # avoid the object pointer
			switch VarTypeID(x)
			on C_TYPE_NUMBER
				cCode += " (" + x + ") " + "RING_API_GETNUMBER(" + t + ")"
			on C_TYPE_STRING
				cCode += "RING_API_GETSTRING(" + t + ")"
			on C_TYPE_POINTER
				if GenPointerType(x) = "int"
					cCode += "RING_API_GETINTPOINTER(" + t + ")"
				but GenPointerType(x) = "double"
					cCode += "RING_API_GETDOUBLEPOINTER(" + t + ")"
				else
					cCode += "(" + GenPointerType(x) + " *) " + 
					"RING_API_GETCPOINTER(" + t +',"'+GenPointerType(x)+ '")'
				ok
			on C_TYPE_UNKNOWN
				cCode += "* (" + x + " *) RING_API_GETCPOINTER(" + t +',"'+trim(x)+'")'
			off
			t-- # ignore effect of avoiding the object pointer
		next
	ok
	return cCode

Func GenNewFuncForClasses aList
	cCode = ""
	for aSub in $aClassesList
		if aSub[C_CLASSESLIST_ABSTRACT] = true
			loop
		ok
		cName = aSub[1]	cPara = aSub[2]
		if aSub[C_CLASSESLIST_CODENAME] != NULL
			cCodeName = aSub[C_CLASSESLIST_CODENAME]
		else
			cCodeName = cName
		ok
		cFuncName = "ring_" + cName + "_new"
		mylist = [C_INS_REGISTER,"void","new",ParaList(cPara),cName]
		aList + mylist
		cCode += "RING_FUNC(" + cFuncName + ")" + nl + 
			"{" + nl +
				GenTabs(1) + GenMethodCodeCheckIgnorePointerType() +
				GenTabs(1) + cCodeName + " *pObject = " +
				"new " + cCodeName + "(" + 				
				GenFuncCodeGetParaValues(myList) 
				if aSub[C_CLASSESLIST_PASSVMPOINTER] 
					cCode += ", (VM *) pPointer"
				ok
				cCode += ");" + nl +
				GenTabs(1) + "RING_API_RETCPOINTER(pObject,"+
					'"'+cName+'"' + ");"+ nl +
			"}" + nl + nl
	next
	return cCode

Func GenDeleteFuncForClasses aList
	cCode = ""
	for aSub in $aClassesList
		cName = aSub[1]	cPara = "void"
		if aSub[C_CLASSESLIST_ABSTRACT] = true
			loop
		ok
		if aSub[C_CLASSESLIST_CODENAME] != NULL
			cCodeName = aSub[C_CLASSESLIST_CODENAME]
		else
			cCodeName = cName
		ok
		cFuncName = "ring_" + cName + "_delete"
		mylist = [C_INS_REGISTER,"void","delete",ParaList(cPara),cName]
		aList + mylist
		cCode += "RING_FUNC(" + cFuncName + ")" + nl + 
			"{" + nl +
				GenTabs(1) + cCodeName + " *pObject ; " +nl +
				GenTabs(1) +"if ( RING_API_PARACOUNT != 1 )" + nl +
    				GenTabs(1) +"{" + nl +
        			GenTabs(2) +"RING_API_ERROR(RING_API_MISS1PARA);" + nl +
        			GenTabs(2) +"return ;" + nl +
    				GenTabs(1) +"}" + nl +
    				GenTabs(1) +"if ( RING_API_ISPOINTER(1) )" + nl +
    				GenTabs(1) +"{" + nl +
            			GenTabs(2) +'pObject = ('+cCodeName+' *) RING_API_GETCPOINTER(1,"'+cCodeName+'");' + nl +
            			GenTabs(2) +"delete pObject ;" + nl +
    				GenTabs(1) +"}" + nl +				
			"}" + nl + nl
	next
	return cCode


Func GenRingCode aList
	# This function generate Ring Classes that wraps C++ Classes
	cCode = ""
	cClassName = ""
	aClasses = []
	cCode += GenRingCodeFuncGetObjectPointer()
	for aFunc in aList
		if aFunc[C_FUNC_INS] = C_INS_FUNCTION or
		   aFunc[C_FUNC_INS] = C_INS_REGISTER 
			# Check the start of a New Class
			if aFunc[C_CLASS_NAME] != cClassName
				cClassName = aFunc[C_CLASS_NAME]
				if find(aClasses,cClassName) = 0
					cCode += nl+"Class " + cClassName 
					nIndex = find($aClassesList,cClassName,1) 
					if nIndex > 0
						  if $aClassesList[nIndex][C_CLASSESLIST_PARENT] != ""
						 	cCode += " from " + $aClassesList[nIndex][C_CLASSESLIST_PARENT]
						  ok
						  cCode += nl+nl+
						  GenTabs(1) + "pObject" + nl + nl +
						  GenTabs(1) + "Func init " + 
						  GenRingCodeParaList(ParaList($aClassesList[nIndex][C_CLASSESLIST_PARA])) + nl +
						  GenTabs(2) + "pObject = " + cClassName + "_new(" + 
						  GenRingCodeParaListUse(ParaList($aClassesList[nIndex][C_CLASSESLIST_PARA])) +")"+nl+
						  GenTabs(2) + "return self" + nl + nl +
						  GenTabs(1) + "Func delete" + nl + 
						  GenTabs(2) + "pObject = " + cClassName+"_delete(pObject)" + nl  					
					else
						cCode += nl + nl
					ok
					aClasses + cClassName
				else
					loop
				ok
			ok
			# Define the method
			if aFunc[C_FUNC_NAME] = "new" loop ok
			cMethodName = aFunc[C_FUNC_NAME]
			cMethodName = GenRingCodeNewMethodName(cClassName,cMethodName)
			cCode += nl + GenTabs(1) + "Func " + cMethodName + " "
			aPara = aFunc[C_FUNC_PARA]
			cCode += GenRingCodeParaList(aPara)
			
			lRetObj = false
			if find($aClassesList,aFunc[C_FUNC_OUTPUT],1) > 0
				lRetObj = true
				cCode += nl + GenTabs(2) + "pTempObj = new " + aFunc[C_FUNC_OUTPUT] + nl +
					 GenTabs(2)+"pTempObj.pObject = "
			but find($aClassesList,GenPointerType(aFunc[C_FUNC_OUTPUT]),1) > 0
				lRetObj = true
				cCode += nl + GenTabs(2) + "pTempObj = new " + GenPointerType(aFunc[C_FUNC_OUTPUT]) + nl +
					 GenTabs(2)+"pTempObj.pObject = "
			else
				cCode += nl + GenTabs(2) + "return " 
			ok
			if find($aClassesList,cClassName,1) > 0
				cCode += cClassName + "_" + aFunc[C_FUNC_NAME]+"(pObject"
				cParaCode = GenRingCodeParaListUse(aPara)
				if cParaCode != NULL
					cCode += ","+cParaCode
				ok
			else
				cCode += cClassName + "_" + aFunc[C_FUNC_NAME]+"(" +
				GenRingCodeParaList(aPara)			
			ok
			cCode += ")" + nl
			if lRetObj
				cCode += GenTabs(2) + "return pTempObj" + nl
			ok
		ok
	next
	return cCode

Func GenRingCodeParaList aPara
	cCode = ""
	for x = 1 to len(aPara)
		if aPara[x] = "void" loop ok
		if x != 1 cCode += "," ok
		cCode += "P"+x
	next
	return cCode

Func GenRingCodeParaListUse aPara
	cCode = ""
	for x = 1 to len(aPara)
		if aPara[x] = "void" loop ok
		if x != 1 cCode += "," ok
		cValue = "P"+x
		if VarTypeID(aPara[x]) = C_TYPE_POINTER or
		   VarTypeID(aPara[x]) = C_TYPE_UNKNOWN							
			cCode += "GetObjectPointerFromRingObject(" + cValue + ")"
		else
			cCode += cValue	
		ok 	
	next
	return cCode

Func GenRingCodeFuncGetObjectPointer
	return "
Func GetObjectPointerFromRingObject pObj
     if isobject(pObj)
	if isattribute(pObj,'pObject')
		return pObj.pObject
	else 
		raise('Error, The parameter is not a GUI object!')
	ok
     ok	
     return pObj		
"

Func GenRingCodeNewMethodName cClassName,cMethodName
	for x in aNewMethodName
		if trim(lower(x[C_NMN_CLASSNAME])) = trim(lower(cClassName)) and
		   trim(lower(x[C_NMN_METHODNAME])) = trim(lower(cMethodName))
			return x[C_NMN_NEWMETHODNAME]
		ok
	next
	return cMethodName	