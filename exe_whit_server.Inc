
include win64.inc
include ksamd64.inc
include Macros\x64macros.inc
include Macros\x64calling.inc
include Macros\vasily.inc
include list-entry.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include advapi32.inc
include wtsapi32.inc
include	ws2_32.inc

include ole32.inc

include oleaut32.inc

include userenv.inc		;CreateEnvironmentBlock
include vfw32.inc

includelib Vfw32.Lib
includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib AdvAPI32.Lib
includelib	ws2_32.lib

includelib ole32.lib

includelib oleaut32.lib
includelib UserEnv.Lib
includelib WtsApi32.Lib
WinMain				PROTO :QWORD,:QWORD,:QWORD,:QWORD
WndProc				PROTO :QWORD,:QWORD,:QWORD,:QWORD


WTS_SESSION_INFO struct 8



    SessionId dd ?          ; // 会话 ID
    pWinStationName PVOID ?;  // 工作站名称 (如 "Console", "RDP-Tcp#0")
    State	DD ?;  // 会话状态		WTS_CONNECTSTATE_CLASS 0 WTSActive 会话处于活动状态 1 WTSConnected 会话已连接 2 WTSConnectQuery 会话正在连接 3 WTSShadow 会话正在被远程控制 4 WTSDisconnected 会话已断开 5 WTSIdle 会话空闲 6 WTSListen 会话正在监听 7 WTSReset 会话正在重置 8 WTSDown 会话已关闭 9 WTSInit 会话正在初始化
    
WTS_SESSION_INFO ends   



tcp_to_tcp struct
	_LIST_ENTRY	LIST_ENTRY <>
	
	hsocket			dq ?
	ipaddress		dq ?
	connect_flags		dq ?	;连接标识 具体是哪个客户端连接的
	closecount		dq ?
	revice_time		dq ?
	recvcount		dq ?;接收的数据计数
	
	recvbuffer	db 1024 dup (?) ;包含recv_tcp 结构
tcp_to_tcp ends
.data
	
	SymbolicLinkName_com 		db "\\.\com3",0
	
	;带反馈开
	open_usb		db 0a0h,01h,03h,0a4h,0;返回 a0 01 01 a2
	open_status		db 0a0h,01h,01h,0a2h,0
	
	;带反馈关
	close_usb		db 0a0h,01h,02h,0a3h,0;返回 a0 01 00 a1
	close_status	db 0a0h,01h,00h,0a1h,0
	
	;查询状态
	quere_status	db 0a0h,01h,05h,0a6h,0 
	
	
   	ClassName db "MainWinClass",0
   	AppName  db "Main Window",0
   	err_scm				db "Can't open scmange",0
	service_64bit			db "exe64bit-with-server",0
	err_CreateService		db "CreateService错误",0
	err_driver_start		db "驱动启动失败",0
	ok_driver_start			db "驱动启动成功",0
	
 _keepAlive 	dd  		1; // 开启keepalive属性
 _keepIdle 	dd  		8; // 如该连接在8秒内没有任何数据往来,则进行探测
 _keepInterval 	dd  		5; // 探测时发包的时间间隔为5 秒
 _keepCount 	dd 		3; // 探测尝试的次数.如果第1次探测包就收到响应了,则后2次的不再发.
 _on		dd 		1	;
 
_modbus_tcp_keepAlive 	dd  		1; // 开启keepalive属性
_modbus_tcp_keepIdle 	dd  		8; // 如该连接在10秒内没有任何数据往来,则进行探测
_modbus_tcp_keepInterval 	dd  		5;// 探测时发包的时间间隔为5 秒
_modbus_tcp_keepCount 	dd 		3; // 探测尝试的次数.如果第1次探测包就收到响应了,则后2次的不再发.
_modbus_tcp_on		dd 		1
	tcp_to_tcp_ip	db "10.0.0.30",0
	local_ip	db "10.0.0.50",0
	SESHUTDOWNNAME db "SeShutdownPrivilege",0
	restart_pc		db "tcp_to_tcp指令重启电脑",0
	szUser    dw 'a','d','m','i','n','i','s','t','r','a','t','o','r',0       ; 用户名 Unicode
	szPass    dw 'q','g','j','t','h','p','i','d','t',0               ; 密码
	szDomain  dw '.',0                                 ; 本机用 .
	error_GetActiveSessionId		db "error_GetActiveSessionId",0
	error_QueryUserToken			db "error_QueryUserToken",0
	find_Sessions_error				db "find_Sessions_error",0
	find_Sessions_ok				db "find_Sessions_ok",0
	error_CreateEnvironmentBlock	db "error_CreateEnvironmentBlock",0
	error_SetTokenInformation	db "error_SetTokenInformation",0
	error_DuplicateTokenEx		db "error_DuplicateTokenEx",0
	error_OpenProcessToken		db "error_OpenProcessToken",0
	not_allowed_ip_address	db "不允许的IP地址",0
	restarttself_format	db "/processwait:%d/processhWnd:%d--------",0 ;-------- 8字节防溢出
	error_start_baidu_face		db "启动baidu_face.exe 失败",0
	restart_surface				db "restart_surface",0
	get_realsense_status		db "get_realsense_status",0
	szShelOpen                  BYTE    "open", 0
	handler_ex_text					db "handler_ex_text",0
	StartServiceCtrlDispatcher_text	db "StartServiceCtrlDispatcher_text",0
	RegisterServiceCtrlHandlerA_text db "RegisterServiceCtrlHandlerA_text",0
	SetServiceStatus_SERVICE_START_PENDING_text			db "SetServiceStatus_SERVICE_START_PENDING_text",0
	SetServiceStatus_SERVICE_RUNNING_text db "SetServiceStatus_SERVICE_RUNNING_text",0
	SetServiceStatus_SERVICE_STOPPED_text	db "SetServiceStatus_SERVICE_STOPPED_text",0
	CreateThread_foraccept_restart_baidu_face_text db "CreateThread_foraccept_restart_baidu_face_text",0
	CreateThread_main_recv_tcp_to_tcp_text			db "CreateThread_main_recv_tcp_to_tcp_text",0
	CreateThread_main_recv_tcp_to_tcp_1_text	db "CreateThread_main_recv_tcp_to_tcp_1_text",0
	CreateThread_main_recv_tcp_to_tcp_2_text	db "CreateThread_main_recv_tcp_to_tcp_2_text",0
	CreateThread_main_recv_tcp_to_tcp_4_text	db "CreateThread_main_recv_tcp_to_tcp_4_text",0
	CreateThread_main_recv_tcp_to_tcp_5_text	db "重启surface",0
	CreateThread_main_recv_tcp_to_tcp_6_text	db "获取realsense电源状态",0
	nodata_ioctl_text							db "nodata_ioctl_text",0
	more_than_30								db "more_than_30 3秒内没接收到数据",0
	less_than_4									db "less_than_4",0
	recv_error									db "recv_error",0
	recv_no_ok_data								db "recv_no_ok_data",0
	restart_baidu_face_LIST_ENTRY_empt			db "restart_baidu_face_LIST_ENTRY_empt",0
	restart_baidu_face_EnterCriticalSection		db "restart_baidu_face_EnterCriticalSection",0
	start_exe									db "D:\RadASM\Masm\Projects\exe_whit_server\start.bat",0
	WinSta0_Default								db "winsta0\default",0
	
	
	http_WSAStartup_error						db "http_WSAStartup_error",0
	inet_addr_error							db "inet_addr_error",0
	http_again_connect						db "http_again_connect",0
	exe_with_server_ip						db "10.0.0.50",0
	pi_lan									db "10.0.0.30",0
	WSAGetLastError_text					db "WSAGetLastError_text",0
	WSAEWOULDBLOCK_text						db "WSAEWOULDBLOCK_text",0
	INVALID_SOCKET_text						db "INVALID_SOCKET_text",0
	listen_SOCKET_ERROR_text				db "listen_SOCKET_ERROR_text",0
	HeapAlloc_ERROR_text					db "HeapAlloc_ERROR_text",0
	
	szAviName								db "d:\hb.avi",0
	
	
	http_for_homebridge_ffmpeg_motion	db 'GET /motion?win10-face-notification HTTP/1.1'
					dw 0a0dh
					db 'Host: 10.0.0.30'
					dw 0a0dh
					db 'Accept: text/html, application/xhtml+xml, */*';告诉WEB服务器自己接受什么介质类型，/ 表示任何类型
					dw 0a0dh
					db 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36';该头域的内容包含发出请求的用户信息。 
			
					dw 0a0dh
				
					db "Content-Type: application/json"
					dw 0a0dh
					db 'Accept-Encoding: gzip, deflate'	;表示客户端支持gzip
				;	db 'Accept-Encoding: deflate'
					dw 0a0dh
					db 'Accept-Language: zh-CN'
					dw 0a0dh
					db 'Connection: Keep-Alive'
					dw 0a0dh
					db 'content-Length: 64';sizeof password_pi
				
					dw 0a0dh
					dw 0a0dh
					db 0
				
http_for_homebridge_ffmpeg_motion_size EQU $ -http_for_homebridge_ffmpeg_motion
	
	
TOKEN_SESSION_ID struct
	
	SessionId dd ?
	
TOKEN_SESSION_ID ends
	
	
.data?
	SessionId			TOKEN_SESSION_ID <>
 	hInstance			dq ?
	CommandLine			dq ?
	hWnd				dq ?

	hSCManager			dq ?
	hService			dq ?
	ServiceCtrlHandler	dq ?
	ghSvcStopEvent		dq ?
	hToken				dq ?
	hTokenDup			dq ?
	dwSessionId			dq ?
	pEnv				dq ?
	currentdir			db 256 dup (?)
	SERVICE_TABLE_ENTRYA_buffer SERVICE_TABLE_ENTRY <?>
	temp_buffer			db 256 dup (?)
	
	gSvcStatus SERVICE_STATUS <?>
	hsocket_restart_baidu_face_LIST_ENTRY  LIST_ENTRY  <>
	_RTL_CRITICAL_SECTION_restart_baidu_face		RTL_CRITICAL_SECTION  <?>
	
	
	restart_self_buffer db 256 dup (?)	;lpCommandLine lpCommandLine 是输入输出参数，API 内部会修改字符串，禁止传入 const char* 常量，必须使用数组缓冲区。
	
	baidu_face_dir_buffer		db 256 dup (?);让baidu_face 告诉 tcp_to_tcp ,然后tcp_to_tcp 再发给exe_whit_server
	
	baidu_face_name_buffer		db 256 dup (?)
	
	baidu_face_name_and_dir_buffer		db 256 dup (?)
	exit_flags					dq ?
	