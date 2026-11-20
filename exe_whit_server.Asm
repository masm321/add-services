option casemap:none
OPTION DOTNAME
include exe_whit_server.inc

; ---------------------------------------------------------------------------



ifndef atext
atext macro _name:REQ,_text:REQ,other:VARARG
	
	.data
	align 8
	_name db _text
	for _ehter:REQ,<other>
		db _ehter	;0d0ah
	endm	
	db 0
	.code
	exitm <_name>
endm
endif

IFNDEF LastError
LastError MACRO
        IFNDEF @@_e_r_r_o_r_@@
          .data?
            @@_e_r_r_o_r_@@ db 1024 dup (?)
          .code
        ENDIF
       ; pushad
       ; pushfd
        invoke GetLastError
        mov r8,rax
       ; invoke FormatMessageA,FORMAT_MESSAGE_FROM_SYSTEM,0,r8,0,addr @@_e_r_r_o_r_@@,1024,NULL
       ; popfd
       ; popad
        EXITM <offset @@_e_r_r_o_r_@@>
ENDM

endif
.const
logouterror	db "日志文件写入时错误",0
.data?
hfile_error_log dq ?
hWin		dq ?
.code
public hfile_error_log
logfree proc uses rbx rsi rdi
	LOCAL @aa:qword
	
	
	invoke CloseHandle,hfile_error_log
	mov rax,1
	
	ret

logfree endp
logini proc   uses rbx rsi rdi	_pcurrentdir_buffer:qword,_currentdir_buffer_length:qword,_hWin:qword
	LOCAL @log_currentdir [128]:qword
		
		invoke lstrlenA,_pcurrentdir_buffer
		.if  rax }_currentdir_buffer_length
		
			mov rax,0
			jmp exit
		.endif
		invoke RtlZeroMemory,addr @log_currentdir ,sizeof @log_currentdir
  		invoke lstrcatA,addr @log_currentdir,_pcurrentdir_buffer
  		invoke lstrcatA,addr @log_currentdir,addr atext (errorname_log,"\error.txt")
  		invoke CreateFileA,addr @log_currentdir,GENERIC_WRITE OR GENERIC_READ,FILE_SHARE_WRITE OR FILE_SHARE_READ,0,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
  		.if rax == INVALID_HANDLE_VALUE
  			invoke MessageBoxA,_hWin,addr atext(error_create_file,"创建日志文件失败"),0,MB_OK
  			mov rax,0
  			jmp exit
  		.endif
  		mov hfile_error_log,rax
  		
  		mov rax,1
	
exit:	
	
	
	ret

logini endp
logout proc  uses rbx rsi rdi r12 r13 r14 r15	_log_buffer:qword,_log_buffer_length:qword

	LOCAL @instrbuffer [40h]:qword	;8个参数应该够用了
	LOCAL @_SYSTEMTIME: _SYSTEMTIME
	LOCAL @ptemp_buffer:qword
	LOCAL @return_count:qword
	LOCAL @hheap:qword
	LOCAL @flags:qword
	
	and  @flags,0
	
	invoke GetProcessHeap
	mov @hheap,rax
	mov r8,_log_buffer_length
	add r8,80h
	invoke HeapAlloc,rax,HEAP_ZERO_MEMORY,r8
	.if rax == 0
		
		mov rax,0
		
		ret

	.endif
	mov @ptemp_buffer,rax
	invoke GetLocalTime,addr @_SYSTEMTIME					
	lea rsi,@instrbuffer
	mov rax,0
	mov ax,	@_SYSTEMTIME.wYear			
	mov [rsi],rax
	
	mov ax,	@_SYSTEMTIME.wMonth			
	mov [rsi+8],rax
	
	mov ax,	@_SYSTEMTIME.wDay			
	mov [rsi+10h],rax
	
	mov ax,	@_SYSTEMTIME.wHour			
	mov [rsi+18h],rax
	
	mov ax,	@_SYSTEMTIME.wMinute	
	mov [rsi+20h],rax
	
	mov ax,	@_SYSTEMTIME.wSecond		
	mov [rsi+28h],rax
	
	mov rax,_log_buffer
	mov [rsi+30h],rax
	
						
	invoke wvsprintfA, @ptemp_buffer,addr atext(log_out,"time %4d-%2d-%2d  %2d:%2d:%2d	%s",0dh,0ah),rsi
	
	invoke GetFileSize,hfile_error_log,0
	invoke SetFilePointer,hfile_error_log,rax,0,FILE_BEGIN
	invoke lstrlenA,@ptemp_buffer
	mov r8,rax
	invoke WriteFile,hfile_error_log, @ptemp_buffer,r8,addr  @return_count,0
	
	.if rax == 0
		
		;mov rbx,LastError ()
		
		;invoke MessageBoxA,hWin,rbx,addr logouterror,MB_OK
		
		jmp exit
		
	.endif
	mov  @flags,1				
	
exit:	
	invoke HeapFree,@hheap,0,@ptemp_buffer
	mov rax, @flags
	ret


logout endp


_recv proc  uses rbx rsi rdi r12 r13 r14 r15 _hSocket:qword,_ipbuffer:qword,_size:qword,_flags:qword
	LOCAL __sizecount:qword
	LOCAL __ipbuffer:qword 
	LOCAL @timecount:qword
	

	
	mov @timecount,0
	mov rax,_ipbuffer
	mov __ipbuffer,rax
	
	
	mov rax,_size
	mov __sizecount,rax
	zzzz:
	
		.while  sqword ptr  __sizecount }0
			invoke recv ,_hSocket,__ipbuffer,__sizecount,_flags; 包含flags标志位的结构数据发送服务器  若无错误发生，recv()返回读入的字节数。如果连接已中止，返回0。否则的话，返回SOCKET_ERROR错误，应用程序可通过WSAGetLastError()获取相应错误代码。
										; 在阻塞模式下recv，recvfrom操作将会阻塞到缓冲区里有至少一个字节（TCP）或者一个完整的UDP数据报才返回。
    										;在没有数据到来时，对它们的调用都将处于睡眠状态，不会返回。
			.if	eax == SOCKET_ERROR
				invoke	WSAGetLastError
				.if  eax == WSAEWOULDBLOCK
					invoke Sleep,64h ;延时重发
					.if sqword ptr @timecount  }20
						mov eax,0
						
						ret
					.else 
						inc @timecount
					.endif
				.else
					mov eax,0
					
					ret
				.endif
			.elseif  eax == 0 ;如果连接已中止，返回0
				
				ret	
				
			.else	;若无错误发生，recv()返回读入的字节数
				
				add __ipbuffer,rax
				sub __sizecount,rax
				mov @timecount,0
			.endif
		.endw
		mov eax,1
	
	
	ret

_recv endp

_send proc  uses rbx rsi rdi r10 r11 r12 r13 r14 r15 _hSocket:qword,_ipbuffer:qword,_size:qword,_flags:qword
	LOCAL __sizecount:qword
	LOCAL __ipbuffer:qword 
	LOCAL @timecount:qword
	
	mov @timecount,0
	mov rax,_ipbuffer
	mov __ipbuffer,rax
	mov rax,_size
	mov __sizecount,rax
	
	
		.while  sqword ptr  __sizecount }0
		
			invoke send ,_hSocket,__ipbuffer,__sizecount,_flags; 包含flags标志位的结构数据发送服务器  若无错误发生，send()返回所发送数据的总数
			
			.if	eax == SOCKET_ERROR
				invoke	WSAGetLastError
				.if  eax == WSAEWOULDBLOCK
					invoke Sleep,64h ;延时重发
					.if sqword ptr @timecount  }10
						mov eax,0   
						
						ret
					.else 
						inc @timecount
					.endif
					
				.else
					mov eax,0
					
					ret
				.endif
			.elseif  eax == 0 ;如果连接已中止，返回0
				
				ret
					
			.else
				
				add __ipbuffer,rax
				sub __sizecount,rax
				mov @timecount,0
				
			.endif
		.endw	
		mov eax,1
			
	ret

_send endp

 ;获取当前活动登录会话ID
GetActiveSessionId proc uses rbx rsi rdi _preturn_value:qword
	LOCAL @sessionCount:qword
	LOCAL @pSessionInfo:qword;:pWTS_SESSION_INFO
	WTS_CURRENT_SERVER_HANDLE equ  NULL ;操作本地服务器
	invoke WTSEnumerateSessionsA,WTS_CURRENT_SERVER_HANDLE, 0, 1, addr @pSessionInfo, addr @sessionCount
	.if eax {} 0
		mov rdi,@pSessionInfo
		mov rbx,0
		.while  @sessionCount {} 0
			
		 ; // 筛选活跃、控制台登录会话   
		 		WTSActive EQU 0
			.if [rdi+rbx+WTS_SESSION_INFO.State] == WTSActive
				mov ebx ,[rdi+rbx+WTS_SESSION_INFO.SessionId]
				
				mov rcx,_preturn_value
				mov [rcx],rbx
				invoke  WTSFreeMemory,@pSessionInfo
				invoke logout,addr find_Sessions_ok,sizeof find_Sessions_ok	
				mov rax,1
				ret
				
			.endif
			add rbx,sizeof WTS_SESSION_INFO
			dec @sessionCount
		.endw
		invoke  WTSFreeMemory,@pSessionInfo
	.endif
	invoke logout,addr find_Sessions_error,sizeof find_Sessions_error	
	mov rax,0
	ret
	
GetActiveSessionId endp



get_usb_hard_status proc uses rbx rsi rdi r10 r11 r12 r13 r14 r15
	LOCAL @hfile_usb:qword
	LOCAL @dcb:DCB
	local @timeouts:COMMTIMEOUTS
	LOCAL @return_count:qword
	LOCAL @temp_buffer [80h]:byte
		
			mov rbx,-1
			invoke CreateFileA,addr SymbolicLinkName_com,GENERIC_READ+GENERIC_WRITE,0,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	
			.if rax == INVALID_HANDLE_VALUE
				
				jmp exit
			.endif	
			mov @hfile_usb,rax
			invoke RtlZeroMemory,addr @dcb,sizeof @dcb
			;// 设置收发缓冲区
			
			invoke SetupComm,@hfile_usb,4096, 4096;   
			;// 清空缓冲区
			invoke  PurgeComm,@hfile_usb,PURGE_RXCLEAR + PURGE_TXCLEAR
			mov @dcb.DCBlength,sizeof @dcb 
			invoke  GetCommState,@hfile_usb,addr @dcb
			mov @dcb.BaudRate ,CBR_9600;  
			bts @dcb.fbits,fBinary	  
			
			;If this member is TRUE, binary mode is enabled. Windows does not support nonbinary mode transfers, so this member must be TRUE.
			
			mov @dcb.ByteSize ,8;    
			mov @dcb.Parity,NOPARITY;    
			mov @dcb.StopBits,ONESTOPBIT;    
			
		;	mov @dcb.fRtsControl,RTS_CONTROL_DISABLE;    
		;	mov @dcb.fOutxCtsFlow,0    
			invoke SetCommState,@hfile_usb,addr @dcb
			.if rax ==0
				invoke logout,addr atext(error_usb,"配置串口失败"),sizeof error_usb
				invoke CloseHandle,@hfile_usb
				
				jmp exit
			.endif
			
			;// 设置超时
			mov @timeouts.ReadIntervalTimeout,50;    
			mov @timeouts.ReadTotalTimeoutConstant , 200;    
			mov @timeouts.ReadTotalTimeoutMultiplier ,1;    
			mov @timeouts.WriteTotalTimeoutConstant , 200;    
			mov @timeouts.WriteTotalTimeoutMultiplier,1;    
			invoke  SetCommTimeouts,@hfile_usb,addr @timeouts
	
			;// 发送数据
			and @return_count,0
			invoke WriteFile,@hfile_usb,addr quere_status,sizeof quere_status-1,addr  @return_count,0
			invoke ReadFile,@hfile_usb,addr @temp_buffer,4,addr  @return_count,0
			
			.if @return_count ==4
				
				lea rsi,@temp_buffer
				lea rdi,close_status
				mov rcx,sizeof close_status-1
				cld
				repz cmpsb
				.if ZERO?
					mov rbx,0
					;invoke logout,addr atext(close_usb_realsense,"关闭realsense接口"),sizeof close_usb_realsense
				.else
					
				
					lea rsi,@temp_buffer
					lea rdi,open_status
					mov rcx,sizeof open_status-1
					cld
					repz cmpsb
					.if ZERO?
						mov rbx,1	
						;invoke logout,addr atext(open_usb_realsense,"打开realsense接口，相当于重启"),sizeof open_usb_realsense
						
					.endif
				.endif
			.endif
			
			invoke CloseHandle,@hfile_usb
			
	exit:		
		mov rax,rbx
		ret

get_usb_hard_status endp
main_recv_tcp_to_tcp proc uses rbx rsi rdi r12 r13 r14 r15 _hWin:qword
	LOCAL @readcount:qword
	LOCAL @retry_count:qword
	LOCAL @format_size [8]:qword
	local @usr_tolite_ip:qword
	LOCAL @temp_buffer [256]:byte
	LOCAL @baidu_face_id:dword
	LOCAL @baidu_face_hWnd:dword
	LOCAL @STARTUPINFO:STARTUPINFO
	LOCAL @PROCESS_INFORMATION:PROCESS_INFORMATION
	LOCAL @instrbuffer[8]:qword
	LOCAL @tokenPrivileges:TOKEN_PRIVILEGES 
		and @retry_count,0
		invoke logout,addr CreateThread_main_recv_tcp_to_tcp_text,sizeof CreateThread_main_recv_tcp_to_tcp_text		
		lea rax,hsocket_restart_baidu_face_LIST_ENTRY
		mov rsi,rax
		
		_again:
		.while rax== rax
			invoke Sleep,100
			invoke EnterCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
		;	invoke logout,addr restart_baidu_face_EnterCriticalSection,sizeof restart_baidu_face_EnterCriticalSection		
			lea rax,hsocket_restart_baidu_face_LIST_ENTRY
			.if rax == rsi
				;链表里没有数据，那就等待吧,或者已经遍历了一遍，最后一项会指向开头。
				;只要baidu_face在线，tcp_to_tcp就不会连接 exe_with_server,所以这里说会一直执行
				mov rsi,[rsi+LIST_ENTRY.Flink]
				invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
				invoke Sleep,1000
				;surface go 用于重启baidu_face.exe 的端口 所以经常没有连接，如果日志太多也不好，（占空间）
			;	invoke logout,addr restart_baidu_face_LIST_ENTRY_empt,sizeof restart_baidu_face_LIST_ENTRY_empt	
				jmp _again
			.endif
			mov @readcount,0
		@@:
			invoke ioctlsocket,[rsi+tcp_to_tcp.hsocket],FIONREAD,addr @readcount ;阻塞模式 在一次recv()中所接收的所有数据量。
                        ; 这通常与套接口中排队的数据总量相同。
                        ; 如果S是SOCK_DGRAM 型，则FIONREAD
                        ; 返回套接口上排队的第一个数据报大小。
                        ;正常返回0
       		.if rax == 0
                .if @readcount == 0		;没有需要接收的数据，如果套接口不超时就继续循环
                	
					inc [rsi+tcp_to_tcp.closecount]
					.if sqword ptr [rsi+tcp_to_tcp.closecount] } 30
						invoke logout,addr more_than_30,sizeof more_than_30	
						invoke shutdown,[rsi+tcp_to_tcp.hsocket],2;0 不能再读，1不能再写，2 读写都不能。
	   					invoke closesocket,[rsi+tcp_to_tcp.hsocket]
						mov rbx,[rsi+LIST_ENTRY.Blink]
						RemoveEntryList rsi			
						invoke GetProcessHeap
                       	invoke HeapFree,rax,0,rsi	
                        MOV RSI,RBX		
                       
                    .else
                    	invoke logout,addr nodata_ioctl_text,sizeof nodata_ioctl_text	
                    	invoke RtlZeroMemory,addr @temp_buffer,sizeof @temp_buffer
                    	invoke _send,[rsi+tcp_to_tcp.hsocket],addr @temp_buffer,1,0
                    
						invoke Sleep,100 
					.endif
					mov rsi,[rsi+LIST_ENTRY.Flink]
					invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
					jmp _again
				.else	;真正处理的地方
					
					.if @readcount { 4
						invoke logout,addr less_than_4,sizeof less_than_4	
						inc [rsi+tcp_to_tcp.closecount]
				
						lea rax,hsocket_restart_baidu_face_LIST_ENTRY
						mov rsi,[rsi+LIST_ENTRY.Flink]
						invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
						.continue;;数据不够
					
					.endif
					lea rdi,[rsi+tcp_to_tcp.recvbuffer]
				
					invoke _recv,[rsi+tcp_to_tcp.hsocket],rdi,4,0
					.if eax == 0
						invoke logout,addr recv_error,sizeof recv_error	
						invoke shutdown,[rsi+tcp_to_tcp.hsocket],2;0 不能再读，1不能再写，2 读写都不能。
	   					invoke closesocket,[rsi+tcp_to_tcp.hsocket]
						mov rbx,[rsi+LIST_ENTRY.Blink]
						RemoveEntryList rsi	
						invoke GetProcessHeap
                       	invoke HeapFree,rax,0,rsi
                        MOV RSI,RBX
						mov rsi,[rsi+LIST_ENTRY.Flink]
						invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
					
						.continue
					.endif
				.endif	
				lock and [rsi+tcp_to_tcp.closecount],0
					
				mov eax,[rdi]		;
					
				.if eax == -1;进程ID
					
					invoke logout,addr CreateThread_main_recv_tcp_to_tcp_1_text,sizeof CreateThread_main_recv_tcp_to_tcp_1_text		
					invoke _recv,[rsi+tcp_to_tcp.hsocket],addr @baidu_face_id,4,0
					lock and [rsi+tcp_to_tcp.closecount],0
				
				.elseif eax == -4;进程句柄
					invoke logout,addr CreateThread_main_recv_tcp_to_tcp_4_text,sizeof CreateThread_main_recv_tcp_to_tcp_4_text		
					invoke _recv,[rsi+tcp_to_tcp.hsocket],addr @baidu_face_hWnd,4,0
					lock and [rsi+tcp_to_tcp.closecount],0
				.elseif eax == -5;重启surface
					.if rax == rax
						
						
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						mov dword ptr [rdi],1
						invoke _send,[rsi+tcp_to_tcp.hsocket],rdi,4,0
						
						invoke logout,addr restart_surface,sizeof restart_surface		
						invoke GetCurrentProcess
						mov rbx,rax
						invoke OpenProcessToken,rbx,TOKEN_QUERY or TOKEN_ADJUST_PRIVILEGES,addr hToken
						.if rax == 0
						
							invoke logout,addr error_OpenProcessToken,sizeof error_OpenProcessToken	
						.else
							lea rsi,@tokenPrivileges
							mov dword ptr [rsi+TOKEN_PRIVILEGES.PrivilegeCount],1;
							lea  ecx,@tokenPrivileges
	
							mov [rsi+TOKEN_PRIVILEGES.Privileges.Attributes],SE_PRIVILEGE_ENABLED
	
							invoke LookupPrivilegeValueA ,NULL, addr SESHUTDOWNNAME, addr [rsi+TOKEN_PRIVILEGES.Privileges.Luid]
							invoke AdjustTokenPrivileges, hToken, FALSE, addr @tokenPrivileges, sizeof TOKEN_PRIVILEGES, NULL, NULL
							SHTDN_REASON_MAJOR_OTHER EQU 00000000h
							invoke InitiateSystemShutdownExA,0,addr restart_pc,5,TRUE,TRUE,SHTDN_REASON_MAJOR_OTHER
							
						;	nullptr,                     //本地计算机        
						;	L"服务触发系统重启",         //弹窗提示文本        
						;	dwTimeoutSec,                //倒计时秒        
						;	bForce,                      //TRUE强制杀进程       
						;	 TRUE,                        //TRUE=重启；FALSE=关机       
						;	 SHTDN_REASON_MAJOR_OTHER
								
						.endif
						
					.endif
				.elseif eax == -2;进程名		重启baidu_face.exe
					  .if rax == rax	
						invoke logout,addr CreateThread_main_recv_tcp_to_tcp_2_text,sizeof CreateThread_main_recv_tcp_to_tcp_2_text		
						
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
				
						invoke _recv,[rsi+tcp_to_tcp.hsocket],rdi,4,0
						
						lock and [rsi+tcp_to_tcp.closecount],0
						mov rbx,0
						mov ebx,[rdi]		;
					
					
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						invoke RtlZeroMemory,rdi,sizeof tcp_to_tcp.recvbuffer
						invoke _recv,[rsi+tcp_to_tcp.hsocket],rdi,rbx,0
						
						lock and [rsi+tcp_to_tcp.closecount],0
					
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						
						
						invoke RtlZeroMemory,addr baidu_face_name_and_dir_buffer,sizeof baidu_face_name_and_dir_buffer
						invoke lstrcat,addr baidu_face_name_and_dir_buffer,rdi
						
						lea rdi,[rdi+rbx]
						mov rcx,rbx
						mov al,"\"
						std		;反方向查找
						repnz scasb
						.if rcx == 0
							mov rsi,[rsi+LIST_ENTRY.Flink]
							invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
							
							.continue
						.endif
						cld	;恢复到默认
						mov byte ptr [rdi+1],0
						lea rdi,[rdi+2]
						
						
						invoke RtlZeroMemory,addr baidu_face_name_buffer,sizeof baidu_face_name_buffer
						invoke RtlZeroMemory,addr baidu_face_dir_buffer,sizeof baidu_face_dir_buffer
						invoke lstrcat,addr baidu_face_name_buffer,rdi
						invoke logout,addr baidu_face_name_buffer,sizeof baidu_face_name_buffer		;baidu_face.exe
						
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						invoke lstrcat,addr baidu_face_dir_buffer,rdi
						
						invoke logout,addr baidu_face_dir_buffer,sizeof baidu_face_dir_buffer		;C:\Users\Administrator\Downloads\baidu_face\bin
						
					;	invoke GetCurrentProcess
					;	mov rbx,rax
					;	invoke OpenProcessToken,rbx,TOKEN_ALL_ACCESS,addr hToken
					;	.if rax == 0
					;		mov rsi,[rsi+LIST_ENTRY.Flink]
					;		invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
					;		invoke logout,addr error_OpenProcessToken,sizeof error_OpenProcessToken	
					;		.continue
					;	.endif
						
					;	invoke LogonUserW,addr szUser,addr szDomain,addr szPass,LOGON32_LOGON_INTERACTIVE,LOGON32_PROVIDER_DEFAULT,addr hToken       ; 输出：用户Token
						
					;	invoke	WTSGetActiveConsoleSessionId
					;	mov dwSessionId,rax
						
						invoke GetActiveSessionId,addr dwSessionId
						.if rax == 0
							mov rsi,[rsi+LIST_ENTRY.Flink]
							invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
							invoke logout,addr error_GetActiveSessionId,sizeof error_GetActiveSessionId
							.continue
						.endif
						
						;// 获取登录用户原始令牌  
						invoke WTSQueryUserToken,dwSessionId,addr hToken
						.if rax == 0
							
							invoke logout,addr error_QueryUserToken,sizeof error_QueryUserToken	
							
						.endif
						
						; // 复制令牌，允许调整会话、作为主令牌使用
						;TOKEN_QUERY | TOKEN_ASSIGN_PRIMARY | TOKEN_ADJUST_DEFAULT
						;MAXIMUM_ALLOWED
					;	invoke DuplicateTokenEx,hToken,TOKEN_ALL_ACCESS,0,SecurityIdentification,TokenPrimary,addr hTokenDup
					;	invoke DuplicateTokenEx,hToken,MAXIMUM_ALLOWED,0,SecurityIdentification,TokenPrimary,addr hTokenDup
						
					;	invoke DuplicateTokenEx,hToken,TOKEN_QUERY + TOKEN_ASSIGN_PRIMARY +TOKEN_ADJUST_DEFAULT,0, SecurityImpersonation,TokenPrimary,addr hTokenDup
						invoke DuplicateTokenEx,hToken,MAXIMUM_ALLOWED,0, SecurityImpersonation,TokenPrimary,addr hTokenDup
						
						.if rax == 0
							invoke CloseHandle,hToken
							mov rsi,[rsi+LIST_ENTRY.Flink]
							invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
							invoke logout,addr error_DuplicateTokenEx,sizeof error_DuplicateTokenEx	
							.continue
						.endif
					
						;把服务hToken的SessionId替换成当前活动的Session(即替换到可与用户交互的winsta0下)
						;// 设置令牌绑定会话ID（关键：解决Session0隔离无界面）
						
						; TOKEN_SESSION_ID tokenSession = { dwSessionId };    
						mov rax,dwSessionId
						mov SessionId.SessionId,eax
						invoke SetTokenInformation,hTokenDup,TokenSessionId,addr SessionId,sizeof DWORD;TokenInformationLength
					;	令牌句柄必须打开时携带 TOKEN_ADJUST_DEFAULT / TOKEN_ADJUST_SESSIONID 等对应权限；
					;	修改部分类别（如 TokenSessionId）需要SE_TCB_NAME特权（仅 System / 本地服务具备）；
					;	普通管理员无法直接修改会话 ID。
						
						.if rax == 0
							invoke CloseHandle,hToken
							invoke CloseHandle,hTokenDup
							mov rsi,[rsi+LIST_ENTRY.Flink]
							invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
							invoke logout,addr error_SetTokenInformation,sizeof error_SetTokenInformation
							.continue
						.endif
						invoke RtlZeroMemory,addr @STARTUPINFO,sizeof @STARTUPINFO
						mov @STARTUPINFO.cb, sizeof STARTUPINFO
						lea rax,WinSta0_Default
						mov @STARTUPINFO.lpDesktop,rax;默认情况下，CreateProcessAsUser 在具有不可见且无法接收用户输入的桌面的非交互窗口工作站上创建新进程。
														; 若要启用与新进程的用户交互，必须在 STARTUPINFO 结构的 lpDesktop 成员中指定默认交互式窗口工作站和桌面
						mov @STARTUPINFO.wShowWindow , SW_SHOW
						mov @STARTUPINFO.dwFlags, STARTF_USESHOWWINDOW
						
						;创建进程环境块
						;生成该用户完整环境变量（否则缺少PATH、桌面、用户注册表）
						invoke CreateEnvironmentBlock,addr pEnv,hTokenDup,FALSE
						.if rax == 0
							invoke CloseHandle,hToken
							invoke CloseHandle,hTokenDup
							mov rsi,[rsi+LIST_ENTRY.Flink]
							invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
							invoke logout,addr error_CreateEnvironmentBlock,sizeof error_CreateEnvironmentBlock
						.endif
						
						invoke RtlZeroMemory,addr @instrbuffer,sizeof @instrbuffer
						invoke RtlZeroMemory,addr restart_self_buffer,sizeof restart_self_buffer
						mov rax,0
						mov eax,@baidu_face_id
						lea rdi,@instrbuffer
						mov [rdi],rax
						mov eax,@baidu_face_hWnd
						mov [rdi+8],rax
						invoke wvsprintfA,addr restart_self_buffer,addr restarttself_format ,rdi
					;	invoke wsprintf,addr restart_self_buffer,addr restarttself_format,rax
						invoke logout,addr restart_self_buffer,sizeof restart_self_buffer
						mov rax,pEnv
						;在活动的Session下创建进程
						invoke RtlZeroMemory,addr @PROCESS_INFORMATION,sizeof @PROCESS_INFORMATION
						dwCreationFlag equ CREATE_UNICODE_ENVIRONMENT + CREATE_NEW_CONSOLE
					;	dwCreationFlag equ NORMAL_PRIORITY_CLASS + CREATE_NEW_PROCESS_GROUP +CREATE_UNICODE_ENVIRONMENT + CREATE_NEW_CONSOLE; + CREATE_UNICODE_ENVIRONMENT  CREATE_NEW_PROCESS_GROUP
						invoke CreateProcessAsUserA,hTokenDup,addr baidu_face_name_and_dir_buffer,addr restart_self_buffer,0,0,0,dwCreationFlag,pEnv,addr baidu_face_dir_buffer,addr @STARTUPINFO,addr @PROCESS_INFORMATION
						;invoke CreateProcessAsUserA,hTokenDup,0,addr baidu_face_name_and_dir_buffer,0,0,0,dwCreationFlag,pEnv,addr baidu_face_dir_buffer,addr @STARTUPINFO,addr @PROCESS_INFORMATION
						.if rax == 0
							invoke logout,addr error_start_baidu_face,sizeof error_start_baidu_face
							invoke  GetLastError
						.endif
						;如果函数成功，则返回值为非零。
						invoke DestroyEnvironmentBlock,pEnv
						invoke CloseHandle,hTokenDup
						invoke CloseHandle,hToken
						
						
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						mov dword ptr [rdi],1
						invoke _send,[rsi+tcp_to_tcp.hsocket],rdi,4,0
						
					;BOOL CreateProcessAsUserA(  
					;HANDLE                hToken,        // ??????(????)  
					;LPCSTR                lpApplicationName, // ???????(??)  
					;LPSTR                 lpCommandLine,     // ??????(??)  
					;LPSECURITY_ATTRIBUTES lpProcessAttributes,  
					;LPSECURITY_ATTRIBUTES lpThreadAttributes,  
					;BOOL                  bInheritHandles,  
					;DWORD                 dwCreationFlags,  
					;LPVOID                lpEnvironment,  
					;LPCSTR                lpCurrentDirectory,  
					;LPSTARTUPINFOA        lpStartupInfo,  
					;LPPROCESS_INFORMATION lpProcessInformation);
						
					;	lea rax,baidu_face_name_buffer
					;	lea rcx,restart_self_buffer
					;	lea rdx,baidu_face_dir_buffer
					;	invoke  ShellExecute,  hWin, offset szShelOpen, addr start_exe, NULL, NULL,SW_HIDE
						
						;invoke  ShellExecute,0, addr szShelOpen,addr baidu_face_name_buffer,addr restart_self_buffer,addr baidu_face_dir_buffer,SW_SHOWNORMAL
				  .endif		
				.elseif eax == -6;获取realsense电源状态
					invoke logout,addr get_realsense_status,sizeof get_realsense_status		
					invoke get_usb_hard_status
					.if rax == 0;关闭
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						mov dword ptr [rdi],0
						invoke _send,[rsi+tcp_to_tcp.hsocket],rdi,4,0
						
					.elseif rax ==1;打开
						lea rdi,[rsi+tcp_to_tcp.recvbuffer]
						mov dword ptr [rdi],1
						invoke _send,[rsi+tcp_to_tcp.hsocket],rdi,4,0
							
					.endif
					
							
				.else
					invoke logout,addr recv_no_ok_data,sizeof recv_no_ok_data		
							
				
				.endif
					
		
			.endif
			mov rsi,[rsi+LIST_ENTRY.Flink]
			invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
		.endw
	ret

main_recv_tcp_to_tcp endp

foraccept_restart_baidu_face proc  uses rbx rsi rdi r12 r13 r14 r15 _event:qword;,pregedit_logion_trade_buffer:dword
	LOCAL @stSin:sockaddr_in
	LOCAL @paddrlen :qword 
	LOCAL @hSocket:qword
	LOCAL @heapbuffer:qword
	LOCAL @hSocket_restart_baidu_face:qword
	LOCAL @stWsa:WSADATA
	LOCAL @alread_run:qword
	LOCAL @tcp_keepalive:tcp_keepalive
	local @return_length:dword
	LOCAL @dwIP_tcp_to_tcp:dword
	
	;invoke InitializeCriticalSection,addr _RTL_CRITICAL_SECTION
	and @alread_run,0
	invoke logout,addr CreateThread_foraccept_restart_baidu_face_text,sizeof CreateThread_foraccept_restart_baidu_face_text		
	invoke	inet_addr,addr tcp_to_tcp_ip;10.0.0.30
	mov @dwIP_tcp_to_tcp,eax
	invoke	WSAStartup,0202h,addr @stWsa
	@@:
	re_stsart:
	
	invoke	socket,AF_INET,SOCK_STREAM,IPPROTO_TCP
	.if  eax {} INVALID_SOCKET
		mov	@hSocket_restart_baidu_face,rax
	.else
		invoke Sleep,1000
		invoke logout,addr INVALID_SOCKET_text,sizeof INVALID_SOCKET_text
		jmp @b
		
	.endif
	
	
	invoke htons,8884
	mov	@stSin.sin_port,ax
	mov	@stSin.sin_family,AF_INET
	;invoke	inet_addr,addr local_ip
	;mov	@stSin.sin_addr,eax
	mov	@stSin.sin_addr,INADDR_ANY
	invoke	bind,@hSocket_restart_baidu_face,addr @stSin,sizeof @stSin
	invoke listen,@hSocket_restart_baidu_face,7FFFFFFFh;指定正在等待连接的最大队列长度;If no error occurs, listen returns zero
	.if eax == SOCKET_ERROR
		invoke logout,addr listen_SOCKET_ERROR_text,sizeof listen_SOCKET_ERROR_text
		invoke Sleep,1000
		jmp @b
	.endif
	@@:
	mov  @paddrlen ,sizeof sockaddr_in
	invoke accept,	@hSocket_restart_baidu_face,addr @stSin,addr  @paddrlen;This returned value is a handle for the socket on which the actual connection is made.
	.if rax {} INVALID_SOCKET
		mov @hSocket,rax
		
		mov eax,@stSin.sin_addr.S_un.ADDRESS_UNION.S_addr 
		
		.if eax {} @dwIP_tcp_to_tcp	
			invoke logout,addr not_allowed_ip_address,sizeof not_allowed_ip_address
			jmp @b
		.endif
		
		invoke setsockopt,@hSocket,SOL_SOCKET, SO_KEEPALIVE,addr _keepAlive,sizeof _keepAlive
		TCP_KEEPIDLE equ 3
			
		TCP_KEEPINTVL equ 4
			
		TCP_KEEPCNT equ 5
		invoke setsockopt,@hSocket,IPPROTO_TCP, TCP_KEEPIDLE,addr _keepIdle, sizeof _keepIdle
		
		IOC_VENDOR    equ 18000000h
		IOC_IN        equ  80000000h
		SIO_KEEPALIVE_VALS equ IOC_IN or IOC_VENDOR or 4
		mov @tcp_keepalive.onoff,1
		mov @tcp_keepalive.keepalivetime,10 * 1000;       10秒没数据发心跳
		mov @tcp_keepalive.keepaliveinterval,5* 1000;心跳每5秒发一次
		invoke WSAIoctl, @hSocket,SIO_KEEPALIVE_VALS,addr @tcp_keepalive,sizeof @tcp_keepalive,0,0,addr @return_length,0,0
		
	;	invoke setsockopt,@hSocket,IPPROTO_TCP, TCP_KEEPINTVL,addr _keepInterval, sizeof _keepInterval
		
		invoke setsockopt, @hSocket,IPPROTO_TCP, TCP_KEEPCNT,addr _keepCount, sizeof _keepCount
		invoke setsockopt, @hSocket, SOL_SOCKET, SO_REUSEADDR, addr _on, sizeof _on;//这一行调用了 setsockopt() 函数，设置套接字选项。    
		    				;//具体来说，它启用了 SO_REUSEADDR 选项，允许在套接字关闭后立即重用该地址。这可以避免在关闭套接字后的一段时间内无法立即重新绑定相同地址的情况。

		invoke Sleep,100
		invoke GetProcessHeap
		mov rbx,rax
		invoke HeapAlloc,rbx,HEAP_ZERO_MEMORY,sizeof tcp_to_tcp
		.if rax {} 0
			mov @heapbuffer,rax
		.else
			invoke shutdown,@hSocket,2;0 不能再读，1不能再写，2 读写都不能。
			invoke closesocket,@hSocket
			invoke logout,addr HeapAlloc_ERROR_text,sizeof HeapAlloc_ERROR_text
			jmp @b
		.endif
		mov rdi,@heapbuffer
		mov eax,@stSin.sin_addr.S_un.ADDRESS_UNION.S_addr 
		mov [rdi+tcp_to_tcp.ipaddress],rax
		mov rax,@hSocket
		mov [rdi+tcp_to_tcp.hsocket],rax
		
		invoke EnterCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
		lea rax,hsocket_restart_baidu_face_LIST_ENTRY
		mov rdi,@heapbuffer
		lea rcx,[rdi+tcp_to_tcp._LIST_ENTRY]
		InsertTailList 	rax,rcx
		invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
		.if @alread_run == 0
			or @alread_run,1
			
			invoke CreateThread,0,0,addr main_recv_tcp_to_tcp,0,0,0
			
		.endif
		
		;invoke SetDlgItemTextA,hWnd,1015,addr _433_connect_ok
		;	invoke LeaveCriticalSection,addr _RTL_CRITICAL_SECTION
		
		jmp @b
	
	.else
		invoke WSAGetLastError
		
		.if eax == WSAEWOULDBLOCK; The socket is marked as nonblocking and no connections are present to be accepted.
 				invoke logout,addr WSAEWOULDBLOCK_text,sizeof WSAEWOULDBLOCK_text
			jmp @b
			;Server : accept() WSAEWOULDBLOCK
			
		.else
			invoke logout,addr WSAGetLastError_text,sizeof WSAGetLastError_text
			jmp re_stsart
			;"Server : accept() error %ld
		.endif
		
	.endif
	
	ret

foraccept_restart_baidu_face endp


handler_ex proc _dwControl:qword

	;当服务控制管理器向服务发送控制代码时，它会等待处理程序函数返回，
	;然后再将其他控制代码发送到其他服务。 控件处理程序应尽快返回
	;如果 SCM 在 30 秒内未返回，则返回错误。 如果服务在执行控件处理程序时服务必须执行冗长处理，
	;它应创建一个辅助线程来执行冗长处理，然后从控件处理程序返回。
	; 这可以防止服务将控制调度程序与控制调度程序关联起来，并阻止其他服务接收控制代码。
	
	.if _dwControl == SERVICE_CONTROL_PAUSE
		mov gSvcStatus.dwCurrentState ,SERVICE_PAUSED;
	.elseif _dwControl == SERVICE_CONTROL_CONTINUE
		mov gSvcStatus.dwCurrentState , SERVICE_RUNNING
	.elseif _dwControl == 	SERVICE_CONTROL_STOP
		
		;ReportSvcStatus(SERVICE_STOP_PENDING, NO_ERROR, 0);

        ; // Signal the service to stop.
        ; 停止服务
		mov gSvcStatus.dwServiceType,SERVICE_WIN32_OWN_PROCESS; 
   		mov gSvcStatus.dwCurrentState,SERVICE_STOP_PENDING
    	mov gSvcStatus.dwControlsAccepted ,SERVICE_ACCEPT_STOP
    	
   		invoke  SetServiceStatus,ServiceCtrlHandler, addr gSvcStatus
        invoke SetEvent,ghSvcStopEvent
       	mov exit_flags,1
		
        ;ReportSvcStatus( SERVICE_STOPPED, NO_ERROR, 0 );
	.elseif _dwControl == 	SERVICE_CONTROL_INTERROGATE
	.elseif _dwControl == 	SERVICE_CONTROL_SHUTDOWN ;SERVICE_CONTROL_SHUTDOWN控制代码只能由在关闭期间必须绝对清理的服务进行处理，
													;因为服务关闭) (大约 20 秒的时间有限。 在此时间到期后，无论服务关闭是否完成，系统关闭都会继续。 
													;请注意，如果系统保持关闭状态 (未重启或关闭) ，则服务将继续运行。 
													;如果服务注册接受 SERVICE_CONTROL_SHUTDOWN，它必须处理控制代码并及时停止。 
													;否则，服务可能会增加关闭系统所需的时间，因为系统必须等待服务关闭所允许的全部时间后，系统才能继续关闭。
		
	.endif
	invoke logout,addr handler_ex_text,sizeof handler_ex_text
	invoke  SetServiceStatus,ServiceCtrlHandler, addr gSvcStatus
	mov rax,0
	ret

handler_ex endp
ipserver_proc proc _dwNumServicesArgs:qword,_lpServiceArgVectors:qword
	
	; ServiceMain 函数
	;服务的入口点。LPSERVICE_MAIN_FUNCTION 类型定义指向此回调函数的指针。 ServiceMain 是应用程序定义的函数名称的占位符。
	
	;[in] dwNumServicesArgs lpServiceArgVectors 数组中的参数数。 
	
	;通过调用启动服务的 StartService 函数传递给服务的 null 终止参数字符串。 如果没有参数，此参数可以为 NULL。 
	;否则，第一个参数（lpServiceArgVectors[0]）是服务的名称，后跟任何其他参数（lpServiceArgVectors[1] 到 lpServiceArgVectors[dwNumServicesArgs-1]）。

	;如果用户从控制面板使用服务管理单元启动手动服务，
	;则 lpServiceArgVectors 参数的字符串来自服务的属性对话框（从服务管理单元中，右键单击服务条目，单击 属性，并在 Start 参数中输入参数。
	;SERVICE_STATUS_HANDLE RegisterServiceCtrlHandlerA(
  	;[in] LPCSTR             lpServiceName,
  	;[in] LPHANDLER_FUNCTION lpHandlerProc
	;	);
 		 	
 		 	;[in] lpServiceName 由调用线程运行的服务的名称。 这是创建服务时，CreateService 函数中指定的服务控制程序的服务名称。
 		 	;[in] lpHandlerProc 指向要注册的处理程序函数的指针。 有关详细信息，请参阅 HandlerEx。
 		 	;[in, optional] lpContext 任何用户定义的数据。 此参数传递给处理程序函数有助于在多个服务共享进程时标识服务。
 		 	;如果函数成功，则返回值为服务状态句柄。
			;如果函数失败，则返回值为零。 若要获取扩展的错误信息，请调用 GetLastError。
	invoke logout,addr StartServiceCtrlDispatcher_text,sizeof StartServiceCtrlDispatcher_text	
	mov 	rax,_lpServiceArgVectors
	mov rcx,[rax+SERVICE_TABLE_ENTRY.lpServiceName]
	lea rdx,handler_ex
	;invoke RegisterServiceCtrlHandlerEx(TEXT(SERVICE_NAME), ServiceHandle,NULL);//返回服务状态.
	invoke RegisterServiceCtrlHandlerA,rcx,rdx;addr handler_ex	;
	;如果函数成功，则返回值为服务状态句柄。如果函数失败，则返回值为零。
	.if rax {} 0
		
		mov  ServiceCtrlHandler,rax
		invoke logout,addr RegisterServiceCtrlHandlerA_text,sizeof RegisterServiceCtrlHandlerA_text
	.endif
	mov exit_flags,0
	
	
 	; Report initial status to the SCM
 	
 	; ReportSvcStatus( SERVICE_START_PENDING, NO_ERROR, 3000 );
 	
 	
 	;设置服务状态：启动中
 	
 	mov gSvcStatus.dwServiceType,SERVICE_WIN32_OWN_PROCESS;  SERVICE_WIN32;    //服务的类型是Win32服务
    mov gSvcStatus.dwCurrentState,SERVICE_START_PENDING
    mov gSvcStatus.dwControlsAccepted ,SERVICE_ACCEPT_STOP
    mov gSvcStatus.dwWin32ExitCode,NO_ERROR;0;  //服务用语报告启动或停止时候发生的错误代码.返回特定的错误代码就设置.
    mov gSvcStatus.dwServiceSpecificExitCode,0;  //服务特定的错误代码  
    mov gSvcStatus.dwCheckPoint,1;//跟进度条一样,服务在启动的时候会递增这个值
    mov gSvcStatus.dwWaitHint,3000 ;//挂起启动,停止,暂停.或继续操作所需要的估计
   	invoke  SetServiceStatus,ServiceCtrlHandler, addr gSvcStatus
   	
   	
   
   	
   	invoke logout,addr SetServiceStatus_SERVICE_START_PENDING_text,sizeof SetServiceStatus_SERVICE_START_PENDING_text
 	
   	
   	invoke CreateEventA,0,0,0,0
   	mov ghSvcStopEvent,rax
   	
   	invoke CreateThread,0,0,addr foraccept_restart_baidu_face,ghSvcStopEvent,0,0
   	
   
   	
   	;Report running status when initialization is complete.

   ; ReportSvcStatus( SERVICE_RUNNING, NO_ERROR, 0 );
   		;设置服务状态：运行中
   	mov gSvcStatus.dwCurrentState,SERVICE_RUNNING
   	mov gSvcStatus.dwCheckPoint,0
   	invoke  SetServiceStatus,ServiceCtrlHandler, addr gSvcStatus
   	
  
   	
   	invoke logout,addr SetServiceStatus_SERVICE_RUNNING_text,sizeof SetServiceStatus_SERVICE_RUNNING_text
   	
   	
   ;	.while TRUE
   		
   	;	.if exit_flags == 1
   			
   			
   	;		.break
   			
   	;	.endif
   		
   	;	invoke Sleep,100
   		
   ;	.endw
   	
   	
   	
  
   	invoke WaitForSingleObject,ghSvcStopEvent, INFINITE
	mov gSvcStatus.dwServiceType,SERVICE_WIN32_OWN_PROCESS; 
   	mov gSvcStatus.dwCurrentState,SERVICE_STOPPED
    mov gSvcStatus.dwControlsAccepted ,0
    mov gSvcStatus.dwWin32ExitCode,NO_ERROR
    mov gSvcStatus.dwServiceSpecificExitCode,0;    
    mov gSvcStatus.dwCheckPoint,0
    mov gSvcStatus.dwWaitHint,0
   	invoke  SetServiceStatus,ServiceCtrlHandler, addr gSvcStatus
   	
   	invoke logout,addr SetServiceStatus_SERVICE_STOPPED_text,sizeof SetServiceStatus_SERVICE_STOPPED_text
   	
	ret

ipserver_proc endp	


connect_server_with_ip_port proc _ipaddress:qword,_port:qword
		LOCAL @stWsa:WSADATA
		LOCAL @stSin:sockaddr_in
		LOCAL @hSocket:qword
		LOCAL @hheap:qword
		LOCAL @SecPkgContext_StreamSizes_buffer	:SecPkgContext_StreamSizes
		LOCAL @tcp_keepalive:tcp_keepalive
		local @return_length:dword
	
			invoke	WSAStartup,0202h,addr @stWsa
		
		
			invoke	socket,AF_INET,SOCK_STREAM,IPPROTO_TCP
			.if rax == INVALID_SOCKET
				invoke logout,addr http_WSAStartup_error,sizeof http_WSAStartup_error
				; invoke MessageBoxA,hWnd,addr errorsocket,addr errorsocket,MB_OK
				 mov rax,0
				jmp exit
		
			.endif
		
			mov	@hSocket,rax
			invoke setsockopt,@hSocket,SOL_SOCKET, SO_KEEPALIVE,addr _keepAlive,sizeof _keepAlive
			TCP_KEEPIDLE equ 3
			
			TCP_KEEPINTVL equ 4
			
			TCP_KEEPCNT equ 5
			invoke setsockopt,@hSocket,IPPROTO_TCP, TCP_KEEPIDLE,addr _keepIdle, sizeof _keepIdle
		
		
			IOC_VENDOR    equ 18000000h
			IOC_IN        equ  80000000h
			SIO_KEEPALIVE_VALS equ IOC_IN or IOC_VENDOR or 4
			mov @tcp_keepalive.onoff,1
			mov @tcp_keepalive.keepalivetime,10 * 1000;       10秒没数据发心跳
			mov @tcp_keepalive.keepaliveinterval,5* 1000;心跳每5秒发一次
			invoke WSAIoctl, @hSocket,SIO_KEEPALIVE_VALS,addr @tcp_keepalive,sizeof @tcp_keepalive,0,0,addr @return_length,0,0
		
			;invoke setsockopt,@hsocket_accept,IPPROTO_TCP, TCP_KEEPINTVL,addr _modbus_tcp_keepInterval, sizeof _modbus_tcp_keepInterval
			
			invoke setsockopt, @hSocket,IPPROTO_TCP, TCP_KEEPCNT,addr _keepCount, sizeof _keepCount
			invoke setsockopt, @hSocket, SOL_SOCKET, SO_REUSEADDR, addr _on, sizeof _on;//这一行调用了 setsockopt() 函数，设置套接字选项。    
		    				;//具体来说，它启用了 SO_REUSEADDR 选项，允许在套接字关闭后立即重用该地址。这可以避免在关闭套接字后的一段时间内无法立即重新绑定相同地址的情况。

			invoke	inet_addr,_ipaddress;
			.if eax  == INADDR_NONE
				invoke logout,addr inet_addr_error,sizeof inet_addr_error
				mov rax,0
				jmp exit
			.endif
			mov	@stSin.sin_addr,eax
			mov	@stSin.sin_family,AF_INET
			mov rax,_port
			invoke	htons,rax		;htonl()表示将32位的主机字节顺序转化为32位的网络字节顺序 htons()表示将16位的主机字节顺序转化为16位的网络字节顺序（ip地址是32位的端口号是16位的 ）
			mov	@stSin.sin_port,ax
		
		@@:
			invoke	connect,@hSocket,addr @stSin,sizeof @stSin
			.if	eax == SOCKET_ERROR
				invoke	WSAGetLastError
				.if eax {} WSAEWOULDBLOCK
					invoke Sleep,1000
					invoke  logout,addr  http_again_connect,sizeof  http_again_connect
				
					mov rax,0
					jmp exit
				.endif
			
			.endif
			
		
			mov rax,@hSocket
			
			
			ret
		exit:	
			
			
			mov rax,0
			
			ret
			
			
			
			
		
connect_server_with_ip_port endp

set_homebridge_ffmpeg_motion proc aa:qword
	
	LOCAL @hsock:qword
	LOCAL @readcount:QWORD
	
	LOCAL @retry_count:qword
	LOCAL @inst [8]:qword
	LOCAL @temp_buffer [128]:dword
	
	and @readcount,0
	
	
	invoke connect_server_with_ip_port,addr pi_lan,8883
	
	.if rax {} 0
		mov @hsock,rax
		invoke lstrlen,addr http_for_homebridge_ffmpeg_motion
		
		invoke _send,@hsock,addr http_for_homebridge_ffmpeg_motion,rax,0
		
		
		.while TRUE
			invoke Sleep,1000
			invoke ioctlsocket,@hsock,FIONREAD,addr @readcount ;阻塞模式 在一次recv()中所接收的所有数据量。
                        ; 这通常与套接口中排队的数据总量相同。
                        ; 如果S是SOCK_DGRAM 型，则FIONREAD
                        ; 返回套接口上排队的第一个数据报大小。
                        
                        ;正常返回0
                        
               		.if rax == 0
                       		.if @readcount == 0
				
					.if @retry_count { 20
					
						inc @retry_count
						.continue
						
					.else
						.break
					.endif
		
				.else
					
					.if @readcount { sizeof @readcount
					
						invoke _recv,@hsock,addr @temp_buffer,@readcount,0	;接收多少无所谓，只要发送成功就行
					.endif
				.endif	
			.else
				
				jmp exit
			
			.endif
		.endw
		
		
	exit:	
		invoke shutdown,@hsock,2;0 不能再读，1不能再写，2 读写都不能。
			
		invoke closesocket,@hsock
		
	.endif
	
	ret

set_homebridge_ffmpeg_motion endp

WinMain proc  hInst:qword,hPrevInst:qword,CmdLine:qword,CmdShow:qword
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL @ModuleFileName [256]:byte
	LOCAL @strhdr:AVISTREAMINFOW
	LOCAL @Havi:qword
	local @ps:qword;PAVISTREAM
		invoke GetModuleHandle, NULL
		mov    hInstance,rax
		
		
		;int 3
		;invoke for_invoke_bd_face_detect_rgb1,0
		;int 3
		
		invoke GetCommandLine
		mov    CommandLine,rax
		invoke GetModuleFileNameA,hInstance,addr @ModuleFileName,sizeof @ModuleFileName
		invoke GetModuleFileNameA,hInstance,addr currentdir,sizeof currentdir
		invoke lstrlenA,addr currentdir
		lea rdi,currentdir
		lea rdi,[rdi+rax]
		mov rcx,rax
		mov al,"\"
		std		;反方向查找
		repnz scasb
		cld	;恢复到默认
		mov byte ptr [rdi+1],0
		invoke logini,addr currentdir,sizeof currentdir,0
		
		;int 3
		;invoke connect_server_with_ip_port,addr exe_with_server_ip,8884
		;invoke set_homebridge_ffmpeg_motion,0
		;int 3
		;invoke AVIFileInit
		;invoke AVIFileOpenA,addr @Havi,addr szAviName,OF_WRITE + OF_CREATE,NULL
		
		;invoke RtlZeroMemory,addr @strhdr,sizeof @strhdr
		;mov @strhdr.fccType,streamtypeVIDEO
		;mov @strhdr.fccHandler,0
		;mov @strhdr.dwScale,1
		;mov @strhdr.dwRate,15
		
		;mov @strhdr.dwSuggestedBufferSize,memdc_all_count
		;invoke SetRect,addr @strhdr.rcFrame,0,0,memdc_width,memdc_higth
		invoke InitCommonControls
		invoke CoInitialize, NULL
		lea rax,hsocket_restart_baidu_face_LIST_ENTRY
		InitializeListHead rax
		
		invoke InitializeCriticalSection,addr _RTL_CRITICAL_SECTION_restart_baidu_face
		
	   .if rax==rax	
			invoke OpenSCManagerA, NULL, NULL, SC_MANAGER_ALL_ACCESS
	
			.if rax {} NULL
				mov hSCManager, rax
			.else
				invoke MessageBoxA, hWnd,addr err_scm, NULL, MB_OK + MB_ICONSTOP
			.endif
															;SERVICE_START | SERVICE_STOP | DELETE
			invoke OpenServiceA,hSCManager,addr service_64bit,SERVICE_START + SERVICE_STOP + DELETE;If the function succeeds, the return value is a handle to the service.If the function fails, the return value is NULL.
			.if rax == 0
				invoke GetLastError
			
				.if rax == ERROR_SERVICE_DOES_NOT_EXIST	
					mov rax,0
				
				.elseif eax == ERROR_ACCESS_DENIED		
					ret
				
				
				.elseif eax == ERROR_INVALID_HANDLE			
					ret
				
				.elseif eax == ERROR_INVALID_NAME	
			
					ret
				.endif	
			.endif
			.if rax {} 0
				mov hService, rax
			.else
				
				@@:
				
				invoke CreateServiceA, hSCManager, addr service_64bit,addr service_64bit, SC_MANAGER_ALL_ACCESS,\
				SERVICE_WIN32_OWN_PROCESS, SERVICE_DEMAND_START , \;SERVICE_AUTO_START
				SERVICE_ERROR_IGNORE, addr @ModuleFileName, NULL, NULL, NULL, NULL, NULL	
					
				.if rax {} NULL
				
					mov hService, rax
				.else
					invoke GetLastError
					.if rax == ERROR_ACCESS_DENIED		;	The handle to the SCM database does not have the SC_MANAGER_CREATE_SERVICE access right.
						
						
					.elseif rax== ERROR_CIRCULAR_DEPENDENCY  	;	A circular service dependency was specified.
						
					.elseif rax == ERROR_DUPLICATE_SERVICE_NAME	;The display name already exists in the service control manager database either as a service name or as another display name.	
					
					.elseif rax == ERROR_INVALID_HANDLE
					
					.elseif rax == ERROR_INVALID_NAME
					
					.elseif rax == ERROR_INVALID_PARAMETER	
						
					.elseif rax == ERROR_INVALID_SERVICE_ACCOUNT	
						
					.elseif rax == ERROR_SERVICE_EXISTS
						
					.elseif rax == ERROR_SERVICE_MARKED_FOR_DELETE
					.endif
					
					
					
					
					invoke MessageBoxA, hWnd,addr err_CreateService, NULL, MB_OK + MB_ICONSTOP
					ret
					
				.endif	
			.endif	
				
				lea rax,service_64bit
				mov SERVICE_TABLE_ENTRYA_buffer.lpServiceName  ,rax
				lea rax,ipserver_proc		;lpServiceProc指向 ServiceMain 函数的指针。
				
				mov SERVICE_TABLE_ENTRYA_buffer.lpServiceProc  ,rax
				invoke StartServiceCtrlDispatcherA,addr SERVICE_TABLE_ENTRYA_buffer
		
			
		.endif	
	
	
	
	ret
WinMain endp


end
