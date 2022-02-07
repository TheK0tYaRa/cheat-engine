unit CEcontext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TEMPlibc;

{$include}

{context.h}

(*
 * context.h
 *
 *  Created on: May 18, 2015
 *      Author: eric
 *)

//{$ifndef} CONTEXT_H_
//#define CONTEXT_H_

//{$ifdef } HAS_LINUX_USER_H
//#include <linux/user.h>
//{$else}
//#include <sys/user.h>
//{$endif}

//#include <sys/ptrace.h>
//#include <linux/socket.h>

//{$ifdef } __aarch64__
//#include <elf.h>
//{$endif}



//#include <sys/socket.h>


{$ifdef CPU32} // __i386__
  type CONTEXT_REGS = user_regs_struct;
{$endif}

{$ifdef CPU64} // __x86_64__
  type CONTEXT_REGS = user_regs_struct;
{$endif}


{$ifdef CPUARM} // __arm__
  type CONTEXT_REGS = pt_regs;
{$endif}

{$ifdef CPUAARCH64} // __aarch64__
  type CONTEXT_REGS = user_pt_regs;
{$endif}

type
  PContext = ^CONTEXT;
  CONTEXT = record
    regs: CONTEXT_REGS;
  end;

                                                   {^}
function getRegisters(tid: integer; registerstore: CONTEXT_REGS): integer;
function setRegisters(tid: integer; registerstore: CONTEXT_REGS): integer;
//{$endif} /* CONTEXT_H_ */

{}

implementation

{context.c}

(*
 * context.c
 *
 *  Created on: May 18, 2015
 *      Author: eric
 *)


//#include "context.h"

function getRegisters(tid: integer; registerstore: CONTEXT_REGS): integer;
begin
{$ifndef NT_PRSTATUS}
  result := safe_ptrace(PTRACE_GETREGS, tid, 0, registerstore);
{$else}
  struct iovec iov;
  iov.iov_base=registerstore;
  iov.iov_len=sizeof(CONTEXT_REGS);
  result := safe_ptrace(PTRACE_GETREGSET, tid, (void*)NT_PRSTATUS, &iov);
{$endif}
end;

function setRegisters(tid: integer; registerstore: CONTEXT_REGS): integer;
begin
{$ifndef NT_PRSTATUS}
  result := safe_ptrace(PTRACE_SETREGS, tid, 0, registerstore);
{$else}
  struct iovec iov;
  iov.iov_base=registerstore;
  iov.iov_len=sizeof(CONTEXT_REGS);
  result := safe_ptrace(PTRACE_SETREGSET, tid, (void*)NT_PRSTATUS, &iov);
{$endif}
end;

{}

end.

