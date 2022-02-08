unit CEcontext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TEMPlibc;

{content.h}

(*
 * context.h
 *
 *  Created on: May 18, 2015
 *      Author: eric
 *)

//{$ifndef } CONTEXT_H_
//#define CONTEXT_H_

{$ifdef HAS_LINUX_USER_H}
//#include <linux/user.h>
{$else}
//#include <sys/user.h>
{$endif}

//#include <sys/ptrace.h>
//#include <linux/socket.h>

{$ifdef aarch64} { #note : unsure }
//#include <elf.h>
{$endif}



//#include <sys/socket.h>

type
  PCONTEXT_REGS = ^CONTEXT_REGS;
{$ifdef CPUi386}
  CONTEXT_REGS = user_regs_struct;
{$endif}

{$ifdef CPUx86_64}
  CONTEXT_REGS = user_regs_struct;
{$endif}


{$ifdef CPUARM}
  CONTEXT_REGS = pt_regs;
{$endif}


{$ifdef aarch64}
  CONTEXT_REGS = user_pt_regs;
{$endif}

  PCONTEXT = ^CONTEXT;
  CONTEXT = record
    regs: CONTEXT_REGS;
  end;


function getRegisters(tid: Integer; registerstore: PCONTEXT_REGS): Integer;
function setRegisters(tid: Integer; registerstore: PCONTEXT_REGS): Integer;
//{$endif} (* CONTEXT_H_ *)

{}

implementation

{content.c}

(*
 * context.c
 *
 *  Created on: May 18, 2015
 *      Author: eric
 *)


//#include 'context.h'

function getRegisters(tid: Integer; registerstore: PCONTEXT_REGS): Integer;
begin
{$ifndef NT_PRSTATUS}
  Result := safe_ptrace(PTRACE_GETREGS, tid, 0, registerstore);
{$else}
  struct iovec iov;
  iov.iov_base := registerstore;
  iov.iov_len := sizeof(CONTEXT_REGS);
  Result := safe_ptrace(PTRACE_GETREGSET, tid, (void*)NT_PRSTATUS, (* C2PAS: RefOrBit? *)&iov);
{$endif}
end;

function setRegisters(tid: Integer; registerstore: PCONTEXT_REGS): Integer;
begin
{$ifndef NT_PRSTATUS}
  Result := safe_ptrace(PTRACE_SETREGS, tid, 0, registerstore);
{$else}
  struct iovec iov;
  iov.iov_base := registerstore;
  iov.iov_len := sizeof(CONTEXT_REGS);
  Result := safe_ptrace(PTRACE_SETREGSET, tid, (void*)NT_PRSTATUS, (* C2PAS: RefOrBit? *)&iov);
{$endif}
end;

{}

end.

