//#include <stdio.h>
//#include <stdlib.h>
//#include <pthread.h>
//#include <sys/select.h>
//#include <sys/socket.h>
//#include <sys/types.h>
//#include <string.h>
//#include <netinet/in.h>
//#include <netinet/tcp.h>
//#include <unistd.h>
//#include <sys/select.h>
//
//#include <zlib.h>
//
//#include <errno.h>
//#include <elf.h>
//#include <signal.h>
//#include <sys/prctl.h>
//
//#include <unistd.h>
//#include <errno.h>
//
//#include 'ceserver.h'
//#include 'porthelp.h'
//#include 'api.h'
//#include 'ceservertest.h'
//#include 'symbols.h'
//#include 'extensionfunctions.h'
//#include 'native-api.h'
//pthread_t pth;
//pthread_t identifierthread;
//volatile Integer done;
//Integer PORT;
//
//__thread Integer isDebuggerThread;
//__thread Integer debugfd;
//
//char versionstring[] := 'CHEATENGINE Network 2.0';
//
//ssize_t recvall (Integer s, void *buf, size_t size, Integer flags)
//begin
//  ssize_t totalreceived := 0;
//  ssize_t sizeleft := size;
//  unsigned char *buffer := (unsigned char*)buf;
//
//  // enter recvall
//  flags := flags or MSG_WAITALL;
//
//  while (sizeleft>0) do
//  begin
//    ssize_t i := recv(s, (* C2PAS: RefOrBit? *)&buffer[totalreceived], sizeleft, flags);
//
//    if (i=0) then
//    begin
//      debug_log('recv returned 0'#10'');
//      (* C2PAS: Exit *) Result := i;
//    end;
//
//    if (i=-1) then
//    begin
//      debug_log('recv returned -1'#10'');
//      if (errno=EINTR) then
//      begin
//        debug_log('errno = EINTR'#10'');
//        i := 0;
//      end
//      else
//      begin
//        debug_log('Error during recvall: %d. errno=%d'#10'',(Integer)i, errno);
//        (* C2PAS: Exit *) Result := i; //read error, or disconnected
//      end;
//
//    end;
//
//    totalreceived+ := i;
//    sizeleft- := i;
//  end;
//
//  // leave recvall
//  (* C2PAS: Exit *) Result := totalreceived;
//end;
//
//ssize_t sendall (Integer s, void *buf, size_t size, Integer flags)
//begin
//  ssize_t totalsent := 0;
//  ssize_t sizeleft := size;
//  unsigned char *buffer := (unsigned char*)buf;
//
//  while (sizeleft>0) do
//  begin
//    ssize_t i := send(s, (* C2PAS: RefOrBit? *)&buffer[totalsent], sizeleft, flags);
//
//    if (i=0) then
//    begin
//      (* C2PAS: Exit *) Result := i;
//    end;
//
//    if (i=-1) then
//    begin
//      if (errno=EINTR) then
//        i :=0
//      else
//      begin
//        debug_log('Error during sendall: %d. errno=%d'#10'',(Integer)i, errno);
//        (* C2PAS: Exit *) Result := i;
//      end;
//    end;
//
//    totalsent+ := i;
//    sizeleft- := i;
//  end;
//
//  (* C2PAS: Exit *) Result := totalsent;
//end;
//
//
//Integer DispatchCommand(Integer currentsocket, unsigned char command)
//begin
//  Integer r;
//
//  case (command) of
//  begin
//    CMD_GETVERSION:
//    begin
//      PCeVersion v;
//      Integer versionsize := strlen(versionstring);
//      v := (PCeVersion)malloc(sizeof(CeVersion)+versionsize);
//      v.stringsize := versionsize;
//      v.version := 1;
//
//      memcpy((char *)v+sizeof(CeVersion), versionstring, versionsize);
//
//      //version request
//      sendall(currentsocket, v, sizeof(CeVersion)+versionsize, 0);
//
//      free(v);
//
//      break;
//    end;
//
//    CMD_GETARCHITECTURE:
//    begin
//#ifdef __i386__
//      unsigned char arch := 0;
//#endif
//#ifdef __x86_64__
//      unsigned char arch := 1;
//#endif
//#ifdef __arm__
//      unsigned char arch := 2;
//#endif
//#ifdef __aarch64__
//      unsigned char arch := 3;
//#endif
//      if (SPECIFIED_ARCH <> 9) then
//      begin
//        arch := SPECIFIED_ARCH;
//      end;
//      sendall(currentsocket, (* C2PAS: RefOrBit? *)&arch, sizeof(arch), 0);
//      break;
//    end;
//
//    CMD_CLOSECONNECTION:
//    begin
//      debug_log('Connection %d closed properly'#10'', currentsocket);
//      fflush(stdout);
//      close(currentsocket);
//
//      (* C2PAS: Exit *) Result := nil;
//    end;
//
//    CMD_TERMINATESERVER:
//    begin
//      debug_log('Command to terminate the server received'#10'');
//      fflush(stdout);
//      close(currentsocket);
//      exit(0);
//    end;
//
//    CMD_STARTDEBUG:
//    begin
//      HANDLE h;
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&h, sizeof(h), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//        debug_log('Calling StartDebug(%d)'#10'', h);
//        r := StartDebug(h);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0);
//
//        if (r) then
//        begin
//          isDebuggerThread := 1;
//          debugfd := GetDebugPort(h);
//        end;
//      end;
//      break;
//    end;
//
//    CMD_WAITFORDEBUGEVENT:
//    begin
//      struct
//      begin
//        HANDLE pHandle;
//        Integer timeout;
//      end; wfd;
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&wfd, sizeof(wfd), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//        DebugEvent event;
//        memset((* C2PAS: RefOrBit? *)&event, 0, sizeof(event));
//
//        r := WaitForDebugEvent(wfd.pHandle, (* C2PAS: RefOrBit? *)&event, wfd.timeout);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), r?MSG_MORE:0);
//
//        if (r) then
//        begin
//          if (event.debugevent=SIGTRAP) then
//          begin
//            debug_log('!!!SIGTRAP!!!'#10'');
//            debug_log('event.address=%llx'#10'', event.address);
//          end;
//
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&event, sizeof(event),0);
//        end;
//      end;
//      break;
//    end;
//
//    CMD_CONTINUEFROMDEBUGEVENT:
//    begin
//      struct
//      begin
//        HANDLE pHandle;
//        Integer tid;
//        Integer ignore;
//      end; cfd;
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&cfd, sizeof(cfd), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//        // Calling ContinueFromDebugEvent
//        r := ContinueFromDebugEvent(cfd.pHandle, cfd.tid, cfd.ignore);
//        // Returned from ContinueFromDebugEvent
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0);
//      end;
//      break;
//    end;
//
//    CMD_SETBREAKPOINT:
//    begin
//      CeSetBreapointInput sb;
//
//      debug_log('CMD_SETBREAKPOINT. sizeof(sb)=%d'#10'', sizeof(sb));
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&sb, sizeof(sb), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//
//        debug_log('Calling SetBreakpoint'#10'');
//        r :=SetBreakpoint(sb.hProcess, sb.tid, sb.debugreg, (void *)sb.Address, sb.bptype, sb.bpsize);
//        debug_log('SetBreakpoint returned %d'#10'',r);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0);
//      end;
//      break;
//    end;
//
//    CMD_REMOVEBREAKPOINT:
//    begin
//      CeRemoveBreapointInput rb;
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&rb, sizeof(rb), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//
//        debug_log('Calling RemoveBreakpoint'#10'');
//        r := RemoveBreakpoint(rb.hProcess, rb.tid, rb.debugreg, rb.wasWatchpoint);
//        debug_log('RemoveBreakpoint returned: %d'#10'', r);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0);
//      end;
//      break;
//    end;
//
//    CMD_GETTHREADCONTEXT:
//    begin
//#pragma pack(1)
//      struct
//      begin
//        HANDLE hProcess;
//        Integer tid;
//        Integer type;
//      end; gtc;
//#pragma pack()
//
//      CONTEXT Context;
//      Integer result;
//
//      debug_log('CMD_GETTHREADCONTEXT:'#10'');
//
//      recvall(currentsocket, (* C2PAS: RefOrBit? *)&gtc, sizeof(gtc), MSG_WAITALL);
//
//      debug_log('Going to call GetThreadContext(%d, %d, %p, %d)'#10'', gtc.hProcess, gtc.tid, (* C2PAS: RefOrBit? *)&Context, gtc.type);
//      memset((* C2PAS: RefOrBit? *)&Context, 0, sizeof(Context));
//
//      result := GetThreadContext(gtc.hProcess, gtc.tid, (* C2PAS: RefOrBit? *)&Context, gtc.type);
//
//      debug_log('result=%d'#10'', result);
//
//      if (result) then
//      begin
//        uint32_t structsize := sizeof(Context);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&result, sizeof(result), MSG_MORE);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&structsize, sizeof(structsize), MSG_MORE);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&Context, structsize, 0); //and context
//      end
//      else
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&result, sizeof(result), 0);
//
//      break;
//
//    end;
//
//CMD_SETTHREADCONTEXT:
//    begin
//#pragma pack(1)
//      struct
//      begin
//        HANDLE hProcess;
//        Integer tid;
//        CONTEXT context;
//        Integer type;
//      end; stc;
//#pragma pack()
//
//      Integer result;
//
//      debug_log('CMD_SETTHREADCONTEXT:'#10'');
//
//      recvall(currentsocket, (* C2PAS: RefOrBit? *)&stc, sizeof(stc), MSG_WAITALL);
//
//      debug_log('Going to call SetThreadContext(%d, %d, %p, %d)'#10'', stc.hProcess, stc.tid, (* C2PAS: RefOrBit? *)&stc.context, stc.type);
//
//      result := SetThreadContext(stc.hProcess, stc.tid, (* C2PAS: RefOrBit? *)&stc.context, stc.type);
//
//      debug_log('result=%d'#10'', result);
//
//      sendall(currentsocket, (* C2PAS: RefOrBit? *)&result, sizeof(result), 0);
//
//      break;
//
//    end;
//
//    CMD_SUSPENDTHREAD:
//    begin
//      CeSuspendThreadInput st;
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&st, sizeof(st), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//
//        debug_log('Calling SuspendThread'#10'');
//        r := SuspendThread(st.hProcess, st.tid);
//        debug_log('SuspendThread returned'#10'');
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0);
//      end;
//      break;
//    end;
//
//    CMD_RESUMETHREAD:
//    begin
//      CeResumeThreadInput rt;
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&rt, sizeof(rt), MSG_WAITALL)>0) then
//      begin
//        Integer r;
//
//        debug_log('Calling ResumeThread'#10'');
//        r := ResumeThread(rt.hProcess, rt.tid);
//        debug_log('ResumeThread returned'#10'');
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0);
//      end;
//      break;
//    end;
//
//    CMD_CLOSEHANDLE:
//    begin
//      HANDLE h;
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&h, sizeof(h), MSG_WAITALL)>0) then
//      begin
//        CloseHandle(h);
//        Integer r := 1;
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r), 0); //stupid naggle
//
//      end
//      else
//      begin
//        debug_log('Error during read for CMD_CLOSEHANDLE'#10'');
//        close(currentsocket);
//        fflush(stdout);
//        (* C2PAS: Exit *) Result := 0;
//      end;
//      break;
//    end;
//
//    CMD_CREATETOOLHELP32SNAPSHOT:
//    begin
//      CeCreateToolhelp32Snapshot params;
//      HANDLE result;
//
//      debug_log('CMD_CREATETOOLHELP32SNAPSHOT'#10'');
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&params, sizeof(CeCreateToolhelp32Snapshot), MSG_WAITALL) > 0) then
//      begin
//        debug_log('Calling CreateToolhelp32Snapshot'#10'');
//        result := CreateToolhelp32Snapshot(params.dwFlags, params.th32ProcessID);
//        debug_log('result of CreateToolhelp32Snapshot=%d'#10'', result);
//
//        fflush(stdout);
//
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&result, sizeof(HANDLE), 0);
//
//      end
//      else
//      begin
//        debug_log('Error during read for CMD_CREATETOOLHELP32SNAPSHOT'#10'');
//        fflush(stdout);
//        close(currentsocket);
//        (* C2PAS: Exit *) Result := 0;
//      end;
//
//      break;
//    end;
//
//    CMD_MODULE32FIRST: //slightly obsolete now
//    CMD_MODULE32NEXT:
//    begin
//      HANDLE toolhelpsnapshot;
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&toolhelpsnapshot, sizeof(toolhelpsnapshot), MSG_WAITALL) >0) then
//      begin
//        LongBool result;
//        ModuleListEntry me;
//        CeModuleEntry *r;
//        Integer size;
//
//        if (command=CMD_MODULE32FIRST) then
//          result := Module32First(toolhelpsnapshot, (* C2PAS: RefOrBit? *)&me)
//        else
//          result := Module32Next(toolhelpsnapshot, (* C2PAS: RefOrBit? *)&me);
//
//        if (result) then
//        begin
//          size := sizeof(CeModuleEntry)+ strlen(me.moduleName);
//          r := (PCeModuleEntry)malloc(size);
//          r.modulebase := me.baseAddress;
//          r.modulesize := me.moduleSize;
//          r.modulenamesize :=strlen(me.moduleName);
//
//          // Sending %s size %x\n, me.moduleName, r->modulesize
//          memcpy((char *)r+sizeof(CeModuleEntry), me.moduleName, r.modulenamesize);
//        end
//        else
//        begin
//          size := sizeof(CeModuleEntry);
//          r := (PCeModuleEntry)malloc(size);
//          r.modulebase := 0;
//          r.modulesize := 0;
//          r.modulenamesize := 0;
//        end;
//
//        r.result := result;
//
//        sendall(currentsocket, r, size, 0);
//
//        free(r);
//      end;
//      break;
//    end;
//
//    CMD_PROCESS32FIRST: //obsolete
//    CMD_PROCESS32NEXT:
//    begin
//      HANDLE toolhelpsnapshot;
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&toolhelpsnapshot, sizeof(toolhelpsnapshot), MSG_WAITALL) >0) then
//      begin
//        ProcessListEntry pe;
//        LongBool result;
//        CeProcessEntry *r;
//        Integer size;
//
//        if (command=CMD_PROCESS32FIRST) then
//          result := Process32First(toolhelpsnapshot, (* C2PAS: RefOrBit? *)&pe)
//        else
//          result := Process32Next(toolhelpsnapshot, (* C2PAS: RefOrBit? *)&pe);
//
//        //  debug_log("result=%d\n", result);
//
//        if (result) then
//        begin
//          size :=sizeof(CeProcessEntry)+ strlen(pe.ProcessName);
//          r := (PCeProcessEntry)malloc(size);
//          r.processnamesize := strlen(pe.ProcessName);
//          r.pid := pe.PID;
//          memcpy((char *)r+sizeof(CeProcessEntry), pe.ProcessName, r.processnamesize);
//        end
//        else
//        begin
//          size := sizeof(CeProcessEntry);
//          r := (PCeProcessEntry)malloc(size);
//          r.processnamesize := 0;
//          r.pid := 0;
//        end;
//
//        r.result := result;
//
//        sendall(currentsocket, r, size, 0);
//
//        free(r);
//
//      end;
//      break;
//    end;
//
//    CMD_READPROCESSMEMORY:
//    begin
//      CeReadProcessMemoryInput c;
//
//      r := recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c), MSG_WAITALL);
//      if (r>0) then
//      begin
//        PCeReadProcessMemoryOutput o := nil;
//        o := (PCeReadProcessMemoryOutput)malloc(sizeof(CeReadProcessMemoryOutput)+c.size);
//
//        o.read := ReadProcessMemory(c.handle, (void *)(uintptr_t)c.address, (* C2PAS: RefOrBit? *)&o[1], c.size);
//
//        if (c.compress) then
//        begin
//          //compress the output
//#define COMPRESS_BLOCKSIZE (64*1024)
//          Integer i;
//          unsigned char *uncompressed := (* C2PAS: RefOrBit? *)&o[1];
//          uint32_t uncompressedSize := o.read;
//          uint32_t compressedSize := 0;
//          Integer maxBlocks := 1+(c.size / COMPRESS_BLOCKSIZE);
//
//          unsigned char **compressedBlocks := malloc(maxBlocks*sizeof(unsigned char *) ); //send in blocks of 64kb and reallocate the pointerblock if there's not enough space
//          Integer currentBlock := 0;
//
//          z_stream strm;
//          strm.zalloc := Z_NULL;
//          strm.zfree := Z_NULL;
//          strm.opaque := Z_NULL;
//          deflateInit((* C2PAS: RefOrBit? *)&strm, c.compress);
//
//          compressedBlocks[currentBlock] := malloc(COMPRESS_BLOCKSIZE);
//          strm.avail_out := COMPRESS_BLOCKSIZE;
//          strm.next_out := compressedBlocks[currentBlock];
//
//          strm.next_in := uncompressed;
//          strm.avail_in := uncompressedSize;
//
//          while (strm.avail_in) do
//          begin
//            r := deflate((* C2PAS: RefOrBit? *)&strm, Z_NO_FLUSH);
//            if (r <> Z_OK) then
//            begin
//              if (r=Z_STREAM_END) then
//                break
//              else
//              begin
//                debug_log('Error while compressing'#10'');
//                break;
//              end;
//            end;
//
//            if (strm.avail_out=0) then
//            begin
//              //new output block
//              currentBlock++;
//              if (currentBlock> := maxBlocks) then
//              begin
//                //list was too short, reallocate
//                debug_log('Need to realloc the pointerlist (p1)'#10'');
//
//                maxBlocks* := 2;
//                compressedBlocks := realloc(compressedBlocks, maxBlocks*sizeof(unsigned char*));
//              end;
//              compressedBlocks[currentBlock] := malloc(COMPRESS_BLOCKSIZE);
//              strm.avail_out := COMPRESS_BLOCKSIZE;
//              strm.next_out := compressedBlocks[currentBlock];
//            end;
//          end;
//          // finishing compressiong
//          while (1) do
//          begin
//
//            r := deflate((* C2PAS: RefOrBit? *)&strm, Z_FINISH);
//
//            if (r=Z_STREAM_END) then
//              break; //done
//
//            if (r <> Z_OK) then
//            begin
//              debug_log('Failure while finishing compression:%d'#10'', r);
//              break;
//            end;
//
//            if (strm.avail_out=0) then
//            begin
//              //new output block
//              currentBlock++;
//              if (currentBlock> := maxBlocks) then
//              begin
//                //list was too short, reallocate
//                debug_log('Need to realloc the pointerlist (p2)'#10'');
//                maxBlocks* := 2;
//                compressedBlocks := realloc(compressedBlocks, maxBlocks*sizeof(unsigned char*));
//              end;
//              compressedBlocks[currentBlock] := malloc(COMPRESS_BLOCKSIZE);
//              strm.avail_out := COMPRESS_BLOCKSIZE;
//              strm.next_out := compressedBlocks[currentBlock];
//            end;
//          end;
//          deflateEnd((* C2PAS: RefOrBit? *)&strm);
//
//          compressedSize := strm.total_out;
//          // Sending compressed data
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&uncompressedSize, sizeof(uncompressedSize), MSG_MORE); //followed by the compressed size
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&compressedSize, sizeof(compressedSize), MSG_MORE); //the compressed data follows
//          for (i := 0; i< := currentBlock; i++)
//          begin
//            if (i <> currentBlock) then
//              sendall(currentsocket, compressedBlocks[i], COMPRESS_BLOCKSIZE, MSG_MORE)
//            else
//              sendall(currentsocket, compressedBlocks[i], COMPRESS_BLOCKSIZE-strm.avail_out, 0); //last one, flush
//
//            free(compressedBlocks[i]);
//          end;
//          free(compressedBlocks);
//        end
//        else
//          sendall(currentsocket, o, sizeof(CeReadProcessMemoryOutput)+o.read, 0);
//
//        if (o) then
//          free(o);
//      end;
//      break;
//    end;
//
//    CMD_WRITEPROCESSMEMORY:
//    begin
//      CeWriteProcessMemoryInput c;
//
//      debug_log('CMD_WRITEPROCESSMEMORY:'#10'');
//
//      r := recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c), MSG_WAITALL);
//      if (r>0) then
//      begin
//        CeWriteProcessMemoryOutput o;
//        unsigned char *buf;
//
//        debug_log('recv returned %d bytes'#10'', r);
//        debug_log('c.size=%d'#10'', c.size);
//
//        if (c.size) then
//        begin
//          buf := (unsigned char *)malloc(c.size);
//
//          r := recvall(currentsocket, buf, c.size, MSG_WAITALL);
//          if (r>0) then
//          begin
//            debug_log('received %d bytes for the buffer. Wanted %d'#10'', r, c.size);
//            o.written := WriteProcessMemory(c.handle, (void *)(uintptr_t)c.address, buf, c.size);
//
//            r := sendall(currentsocket, (* C2PAS: RefOrBit? *)&o, sizeof(CeWriteProcessMemoryOutput), 0);
//            debug_log('wpm: returned %d bytes to caller'#10'', r);
//
//          end
//          else
//            debug_log('wpm recv error while reading the data'#10'');
//
//          free(buf);
//        end
//        else
//        begin
//          debug_log('wpm with a size of 0 bytes');
//          o.written := 0;
//          r := sendall(currentsocket, (* C2PAS: RefOrBit? *)&o, sizeof(CeWriteProcessMemoryOutput), 0);
//          debug_log('wpm: returned %d bytes to caller'#10'', r);
//        end;
//      end
//      else
//      begin
//        debug_log('RPM: recv failed'#10'');
//      end;
//      break;
//    end;
//
//    CMD_VIRTUALQUERYEXFULL:
//    begin
//      CeVirtualQueryExFullInput c;
//      CeVirtualQueryExFullOutput o;
//
//      r := recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c), MSG_WAITALL);
//      if (r>0) then
//      begin
//        RegionInfo *rinfo := nil;
//        uint32_t count := 0;
//        if (VirtualQueryExFull(c.handle, c.flags, (* C2PAS: RefOrBit? *)&rinfo, (* C2PAS: RefOrBit? *)&count)) then
//        begin
//          Integer i;
//
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&count, sizeof(count),0);
//
//          for (i := 0; i<count; i++)
//            sendall(currentsocket, (* C2PAS: RefOrBit? *)&rinfo[i], sizeof(RegionInfo),0);
//
//          if (rinfo) then
//            free(rinfo);
//        end;
//      end;
//      break;
//    end;
//    CMD_GETREGIONINFO:
//    CMD_VIRTUALQUERYEX:
//    begin
//      CeVirtualQueryExInput c;
//      r := recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c), MSG_WAITALL);
//      if (r>0) then
//      begin
//        RegionInfo rinfo;
//        CeVirtualQueryExOutput o;
//
//        if (sizeof(uintptr_t)=4) then
//        begin
//          if (c.baseaddress>0xFFFFFFFF) then
//          begin
//            o.result := 0;
//            sendall(currentsocket, (* C2PAS: RefOrBit? *)&o, sizeof(o), 0);
//            break;
//          end;
//        end;
//
//        char mapsline[200];
//
//        if (command=CMD_VIRTUALQUERYEX) then
//          o.result := VirtualQueryEx(c.handle, (void *)(uintptr_t)c.baseaddress, (* C2PAS: RefOrBit? *)&rinfo, nil)
//        else
//        if (command=CMD_GETREGIONINFO) then
//          o.result := VirtualQueryEx(c.handle, (void *)(uintptr_t)c.baseaddress, (* C2PAS: RefOrBit? *)&rinfo, mapsline);
//
//        o.protection := rinfo.protection;
//        o.baseaddress := rinfo.baseaddress;
//        o.type :=rinfo.type;
//        o.size := rinfo.size;
//
//        if (command=CMD_VIRTUALQUERYEX) then
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&o, sizeof(o), 0)
//        else
//        if (command=CMD_GETREGIONINFO) then
//        begin
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&o, sizeof(o), MSG_MORE);
//          begin
//            uint8_t size := strlen(mapsline);
//            sendall(currentsocket, (* C2PAS: RefOrBit? *)&size, sizeof(size), MSG_MORE);
//            sendall(currentsocket, mapsline, size, 0);
//          end;
//        end;
//      end;
//      break;
//    end;
//    CMD_OPENPROCESS:
//    begin
//      Integer pid := 0;
//
//      r := recvall(currentsocket, (* C2PAS: RefOrBit? *)&pid, sizeof(Integer), MSG_WAITALL);
//      if (r>0) then
//      begin
//        Integer processhandle;
//
//        debug_log('OpenProcess(%d)'#10'', pid);
//        processhandle := OpenProcess(pid);
//
//        debug_log('processhandle=%d'#10'', processhandle);
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&processhandle, sizeof(Integer), 0);
//      end
//      else
//      begin
//        debug_log('Error'#10'');
//        fflush(stdout);
//        close(currentsocket);
//        (* C2PAS: Exit *) Result := nil;
//      end;
//      break;
//    end;
//
//    CMD_GETSYMBOLLISTFROMFILE:
//    begin
//      //get the list and send it to the client
//      //zip it first
//      uint32_t symbolpathsize;
//
//      debug_log('CMD_GETSYMBOLLISTFROMFILE'#10'');
//
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&symbolpathsize, sizeof(symbolpathsize), MSG_WAITALL)>0) then
//      begin
//        char *symbolpath := (char *)malloc(symbolpathsize+1);
//        symbolpath[symbolpathsize] := '\0';
//
//        if (recvall(currentsocket, symbolpath, symbolpathsize, MSG_WAITALL)>0) then
//        begin
//          unsigned char *output := nil;
//
//          debug_log('symbolpath=%s'#10'', symbolpath);
//
//          if (memcmp('/dev/', symbolpath, 5) <> 0) then //don't even bother if it's a /dev/ file
//            GetSymbolListFromFile(symbolpath, (* C2PAS: RefOrBit? *)&output);
//
//          if (output) then
//          begin
//            debug_log('output is not NULL (%p)'#10'', output);
//
//            fflush(stdout);
//
//            debug_log('Sending %d bytes'#10'', *(uint32_t *)(* C2PAS: RefOrBit? *)&output[4]);
//            sendall(currentsocket, output, *(uint32_t *)(* C2PAS: RefOrBit? *)&output[4], 0); //the output buffer contains the size itself
//            free(output);
//          end
//          else
//          begin
//            debug_log('Sending 8 bytes (fail)'#10'');
//            uint64_t fail := 0;
//            sendall(currentsocket, (* C2PAS: RefOrBit? *)&fail, sizeof(fail), 0); //just write 0
//          end;
//        end
//        else
//        begin
//          debug_log('Failure getting symbol path'#10'');
//          close(currentsocket);
//        end;
//        free(symbolpath);
//      end;
//      break;
//    end;
//
//    CMD_LOADEXTENSION:
//    begin
//      //Load the extension if it isn't loaded yet
//      //LOADEXTENSION(handle)
//      uint32_t handle;
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&handle, sizeof(handle),0)>0) then
//      begin
//        Integer result := loadCEServerExtension(handle);
//
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&result, sizeof(result),0);
//      end;
//
//      break;
//    end;
//
//    CMD_ALLOC:
//    begin
//      //ALLOC(processhandle, preferedbase, size)
//      CeAllocInput c;
//      debug_log('CESERVER: CMD_ALLOC'#10'');
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c),0)>0) then
//      begin
//        debug_log('c.hProcess=%d'#10'', c.hProcess);
//        debug_log('c.preferedBase=%llx'#10'', c.preferedBase);
//        debug_log('c.size=%d'#10'', c.size);
//
//        uint64_t address := ext_alloc(c.hProcess, c.preferedBase, c.size);
//
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&address, sizeof(address),0);
//      end;
//
//      break;
//    end;
//
//    CMD_FREE:
//    begin
//      CeFreeInput c;
//      debug_log('CESERVER: CMD_FREE'#10'');
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c),0)>0) then
//      begin
//        uint32_t r;
//        r := ext_free(c.hProcess, c.address, c.size);
//
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r),0);
//      end;
//
//      break;
//    end;
//
//    CMD_CREATETHREAD:
//    begin
//      CeCreateThreadInput c;
//      debug_log('CESERVER: CMD_CREATETHREAD'#10'');
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c),0)>0) then
//      begin
//        uint64_t th;
//        HANDLE h;
//        th :=ext_createThread(c.hProcess, c.startaddress, c.startaddress);
//
//        debug_log('returned from ext_createthread'#10'');
//
//        if (th) then //create a handle for this object
//        begin
//          uint64_t *threadobject := (uint64_t *)malloc(sizeof(uint64_t));
//
//          *threadobject := th;
//          h := CreateHandleFromPointer(threadobject, htNativeThreadHandle);
//        end
//        else
//          h := 0;
//
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&h, sizeof(h),0);
//      end;
//      break;
//    end;
//
//    CMD_LOADMODULE:
//    begin
//      CeLoadModuleInput c;
//
//      debug_log('CESERVER: CMD_LOADMODULE'#10'');
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c),0)>0) then
//      begin
//        char modulepath[c.modulepathlength+1];
//
//        if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&modulepath, c.modulepathlength,0)>0) then
//        begin
//          uint32_t result;
//          modulepath[c.modulepathlength] := 0;
//
//          result := ext_loadModule(c.hProcess, modulepath);
//
//          sendall(currentsocket, (* C2PAS: RefOrBit? *)&result, sizeof(result),0);
//        end;
//      end;
//      break;
//    end;
//
//    CMD_SPEEDHACK_SETSPEED:
//    begin
//      CeSpeedhackSetSpeedInput c;
//      debug_log('CESERVER: CMD_SPEEDHACK_SETSPEED'#10'');
//      if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c),0)>0) then
//      begin
//        uint32_t r;
//        r := ext_speedhack_setSpeed(c.hProcess, c.speed);
//
//        sendall(currentsocket, (* C2PAS: RefOrBit? *)&r, sizeof(r),0);
//      end;
//
//      break;
//    end;
//
//	CMD_AOBSCAN:
//	begin
//		CeAobScanInput c;
//		debug_log('CESERVER: CMD_AOBSCAN'#10'');
//		if (recvall(currentsocket, (* C2PAS: RefOrBit? *)&c, sizeof(c), 0) > 0) then
//		begin
//
//			Integer n := c.scansize;
//			char* data := (char*)malloc(n*2);
//			uint64_t* match_addr := (Integer*)malloc(sizeof(uint64_t) * MAX_HIT_COUNT);
//
//			if (recvall(currentsocket, data, n*2, 0)>0) then
//			begin
//				char* pattern := (char*)malloc(n);
//				char* mask := (char*)malloc(n);
//
//				memcpy(pattern, data, n);
//				memcpy(mask, (* C2PAS: RefOrBit? *)&data[n], n);
//				Integer ret := AOBScan(c.hProcess, pattern, mask, c.start, c.end, c.inc,c.protection, match_addr);
//				debug_log('HIT_COUNT:%d'#10'', ret);
//				free(pattern);
//				free(mask);
//				sendall(currentsocket, (* C2PAS: RefOrBit? *)&ret, 4, 0);
//				sendall(currentsocket, match_addr, sizeof(uint64_t)* ret, 0);
//			end;
//			free(data);
//			free(match_addr);
//		end;
//
//		break;
//	end;
//  end;
//end;
//
//Integer CheckForAndDispatchCommand(Integer currentsocket)
//begin
//  Integer r;
//  unsigned char command;
//
//  r := recv(currentsocket, (* C2PAS: RefOrBit? *)&command, 1, MSG_DONTWAIT);
//  if (r=1) then
//  begin
//    DispatchCommand(currentsocket, command);
//    (* C2PAS: Exit *) Result := 1;
//  end;
//
//  (* C2PAS: Exit *) Result := 0;
//end;
//
//void *newconnection(void *arg)
//begin
//  Integer s := (uintptr_t)arg;
//  unsigned char command;
//
//  Integer currentsocket := s;
//
//  isDebuggerThread := 0;
//  debugfd := -1;
//  //printf("new connection. Using socket %d\n", s);
//  while (done=0) do
//  begin
//    Integer r;
//    //check if this is a debugger thread
//    if (isDebuggerThread and (debugfd <> -1)) then
//    begin
//      //wait for s and debugfd
//      fd_set readfds;
//      Integer maxfd := s;
//      Integer sret;
//
//      FD_ZERO((* C2PAS: RefOrBit? *)&readfds);
//      FD_SET(s, (* C2PAS: RefOrBit? *)&readfds);
//      FD_SET(debugfd, (* C2PAS: RefOrBit? *)&readfds);
//
//      if (debugfd>maxfd) then
//        maxfd := debugfd;
//      //  Waiting for multiple sockets
//      sret := select(maxfd+1, (* C2PAS: RefOrBit? *)&readfds, nil, nil,nil );
//      //  Wait done
//      if (sret=-1) then
//      begin
//        if (errno=EINTR) then
//        begin
//          debug_log('Interrupted by signal. Checking again'#10'');
//          continue;
//        end
//        else
//        begin
//          debug_log('WTF?: %d'#10'', errno);
//          while (1) do sleep(60);
//        end;
//      end;
//
//      if (FD_ISSET(debugfd, (* C2PAS: RefOrBit? *)&readfds) and FD_ISSET(s, (* C2PAS: RefOrBit? *)&readfds)) then
//      begin
//        //alternate between s and debugfd if both are constantly readable
//        if (currentsocket=debugfd) then
//          currentsocket := s
//        else
//          currentsocket := debugfd;
//      end
//      else //not both readable
//      if (FD_ISSET(debugfd, (* C2PAS: RefOrBit? *)&readfds)) then
//        currentsocket := debugfd
//      else
//      if (FD_ISSET(s, (* C2PAS: RefOrBit? *)&readfds)) then
//        currentsocket := s
//      else //none readable (shouldn't really happen, but whatever...), wait again
//        continue;
//    end
//    else
//      currentsocket := s;
//
//    r := recvall(currentsocket, (* C2PAS: RefOrBit? *)&command, 1, MSG_WAITALL);
//
//    if (r>0) then
//    begin
//      DispatchCommand(currentsocket, command);
//    end
//    else
//    if (r=-1) then
//    begin
//      debug_log('read error on socket %d (%d)'#10'', s, errno);
//      fflush(stdout);
//      close(currentsocket);
//      (* C2PAS: Exit *) Result := nil;
//    end
//    else
//    if (r=0) then
//    begin
//      debug_log('Peer has disconnected'#10'');
//      fflush(stdout);
//      close(currentsocket);
//      (* C2PAS: Exit *) Result := nil;
//    end;
//  end;
//
//  close(s);
//
//  (* C2PAS: Exit *) Result := nil;
//end;
//
//void *IdentifierThread(void *arg)
//begin
//  Integer i;
//  Integer s;
//  Integer v := 1;
//#pragma pack(1)
//  struct
//  begin
//    uint32_t checksum;
//    uint16_t port;
//  end; packet;
//#pragma pack()
//
//  socklen_t clisize;
//  struct sockaddr_in addr, addr_client;
//
//  debug_log('IdentifierThread active'#10'');
//
//  fflush(stdout);
//
//  s := socket(PF_INET, SOCK_DGRAM, 0);
//  i := setsockopt(s, SOL_SOCKET, SO_BROADCAST, (* C2PAS: RefOrBit? *)&v, sizeof(v));
//
//  memset((* C2PAS: RefOrBit? *)&addr, 0, sizeof(addr));
//
//  addr.sin_family := PF_INET;
//  addr.sin_addr.s_addr := INADDR_ANY;
//  addr.sin_port := htons(3296);
//  i := bind(s, (struct sockaddr *)(* C2PAS: RefOrBit? *)&addr, sizeof(addr));
//
//  if (i> := 0) then
//  begin
//    while (1) do
//    begin
//      memset((* C2PAS: RefOrBit? *)&addr_client, 0, sizeof(addr_client));
//      addr_client.sin_family := PF_INET;
//      addr_client.sin_addr.s_addr := INADDR_ANY;
//      addr_client.sin_port := htons(3296);
//
//      clisize := sizeof(addr_client);
//
//      i :=recvfrom(s, (* C2PAS: RefOrBit? *)&packet, sizeof(packet), 0, (struct sockaddr *)(* C2PAS: RefOrBit? *)&addr_client, (* C2PAS: RefOrBit? *)&clisize);
//
//      //i=recv(s, &v, sizeof(v), 0);
//      if (i> := 0) then
//      begin
//
//        debug_log('Identifier thread received a message :%d'#10'',v);
//        debug_log('sizeof(packet)=%ld'#10'', sizeof(packet));
//
//        debug_log('packet.checksum=%x'#10'', packet.checksum);
//        packet.checksum* := 0xce;
//        packet.port := PORT;
//        debug_log('packet.checksum=%x'#10'', packet.checksum);
//
//        // packet.checksum=00AE98E7 - y=8C7F09E2
//
//        fflush(stdout);
//
//        i := sendto(s, (* C2PAS: RefOrBit? *)&packet, sizeof(packet), 0, (struct sockaddr *)(* C2PAS: RefOrBit? *)&addr_client, clisize);
//        debug_log('sendto returned %d'#10'',i);
//      end
//      else
//        debug_log('recvfrom failed'#10'');
//
//      fflush(stdout);
//    end;
//  end
//  else
//    debug_log('bind failed'#10'');
//
//  debug_log('IdentifierThread exit'#10'');
//
//  (* C2PAS: Exit *) Result := 0;
//end;
//
//#ifdef SHARED_LIBRARY
//Integer ceserver()
//else
//Integer main(Integer argc, char *argv[])
//#endif
//begin
//  Integer s;
//  Integer b;
//  Integer l;
//  Integer a;
//
//  initAPI();
//
//  socklen_t clisize;
//  struct sockaddr_in addr, addr_client;
//
//  PORT := 52736;
//
//  #ifndef SHARED_LIBRARY
//  Integer TEST_MODE := 0;
//  Integer TEST_PID := 0;
//  Integer opt;
//
//  opterr := 0;
//
//  Integer argv_attach_pid;
//  Integer argv_search_option;
//  Integer argv_port;
//  Integer argv_arch;
//  Integer argv_pid;
//  while ((opt := getopt(argc, argv, 'a:m:p:s:t:')) <> -1) do
//  begin
//    case(opt) of
//    begin
//      'a':
//          errno := 0;
//          argv_attach_pid := strtol(optarg,nil,10);
//          if (errno <> ERANGE and errno <> EINVAL) then
//            ATTACH_PID := argv_attach_pid;
//          break;
//      'm':
//          errno := 0;
//          argv_search_option := strtol(optarg,nil,10);
//          if (errno <> ERANGE and errno <> EINVAL) then
//            MEMORY_SEARCH_OPTION := argv_search_option;
//          break;
//      'p':
//          errno := 0;
//          argv_port := strtol(optarg,nil,10);
//          if (errno <> ERANGE and errno <> EINVAL and argv_port <> 0) then
//            PORT := argv_port;
//          break;
//      's':
//          errno := 0;
//          argv_arch := strtol(optarg,nil,10);
//          if (errno <> ERANGE and errno <> EINVAL) then
//             SPECIFIED_ARCH := argv_arch;
//          break;
//      't':
//          errno := 0;
//          TEST_MODE := 1;
//          argv_pid := strtol(optarg,nil,10);
//          if (errno <> ERANGE and errno <> EINVAL) then
//            TEST_PID := argv_pid;
//          break;
//      else
//          debug_log('Usage: %s [-a <attach_pid>] [-m <search_option>] [-p <port>] [-t <pid>] arg1 ...'#10'', argv[0]);
//          break;
//    end;
//  end;
//  #endif
//
//  debug_log('listening on port %d'#10'',PORT);
//
//  done := 0;
//
//  debug_log('&s=%p'#10'', (* C2PAS: RefOrBit? *)&s);
//  #ifdef SHARED_LIBRARY
//    debug_log('ceserver=%p'#10'',ceserver);
//  else
//    debug_log('main=%p'#10'', main);
//  #endif
//  debug_log('sizeof(off_t)=%d'#10'',sizeof(off_t));
//  debug_log('sizeof(off64_t)=%d'#10'',sizeof(off64_t));
//
//  debug_log('CEServer. Waiting for client connection'#10'');
//
//  //if (broadcast)
//  pthread_create((* C2PAS: RefOrBit? *)&identifierthread, nil, IdentifierThread, nil);
//
//  s := socket(AF_INET, SOCK_STREAM, 0);
//  debug_log('socket=%d'#10'', s);
//
//  memset((* C2PAS: RefOrBit? *)&addr, 0, sizeof(addr));
//  addr.sin_family := AF_INET;
//  addr.sin_port := htons(PORT);
//  addr.sin_addr.s_addr := INADDR_ANY;
//
//  Integer optval := 1;
//  setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (* C2PAS: RefOrBit? *)&optval, sizeof (optval));
//
//  b := bind(s, (struct sockaddr *)(* C2PAS: RefOrBit? *)&addr, sizeof(addr));
//  debug_log('bind=%d'#10'', b);
//
//  if (b <> -1) then
//  begin
//    l := listen(s, 32);
//
//    debug_log('listen=%d'#10'', l);
//
//    clisize := sizeof(addr_client);
//    memset((* C2PAS: RefOrBit? *)&addr_client, 0, sizeof(addr_client));
//
//    #ifndef SHARED_LIBRARY
//    if (TEST_MODE = 1) then
//    begin
//      debug_log('TESTMODE'#10'');
//      pthread_create((* C2PAS: RefOrBit? *)&pth, nil, (void *)CESERVERTEST, TEST_PID);
//    end;
//    #endif
//
//    fflush(stdout);
//
//    while (done=0) do
//    begin
//      Integer b := 1;
//      a := accept(s, (struct sockaddr *)(* C2PAS: RefOrBit? *)&addr_client, (* C2PAS: RefOrBit? *)&clisize);
//
//      debug_log('accept=%d'#10'', a);
//
//      fflush(stdout);
//
//      setsockopt(a, IPPROTO_TCP, TCP_NODELAY, (* C2PAS: RefOrBit? *)&b, sizeof(b));
//
//      if (a <> -1) then
//      begin
//        pthread_create((* C2PAS: RefOrBit? *)&pth, nil, (void *)newconnection, (void *)(uintptr_t)a);
//      end;
//    end;
//  end;
//
//  debug_log('Terminate server'#10'');
//
//  close(s);
//
//  (* C2PAS: Exit *) Result := 0;
//end;
//
//#ifdef SHARED_LIBRARY
//__attribute__((constructor))
//Integer fork_process()
//begin
//    debug_log('main process pid: %d'#10'', getpid());
//
//    prctl(PR_SET_DUMPABLE, 1, 0, 0, 0);
//
//    pid_t pid := fork();
//    if (pid < 0) then
//    begin
//        debug_log('fork');
//    end
//    else if (pid = 0) then
//    begin
//        debug_log('child process pid: %d'#10'', getpid());
//        ceserver();
//    end;
//
//end;
//#endif
