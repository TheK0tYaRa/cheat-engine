unit ceserver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  HandleList_max = Integer;

  handleType = (htEmpty := 0,htProcesHandle,htThreadHandle,
    htTHSProcess,htTHSModule,htNativeThreadHandle
    );

  HandleListEntry = record
    &type: handleType;
    pointer: ^pointer;
  end;
  HandleList = ^HandleListEntry; { volatile }

  HANDLESEARCHCALLBACK = function(data: pointer; searchdata: pointer): longint; cdecl;

function OpenProcess(const pid: DWORD): THandle;

implementation

function sprintf(__s: Pchar; __format: Pchar; args: Pointer): longint; cdecl; external 'clib' name 'sprintf';

function SearchHandleList(&type: integer; cb: HANDLESEARCHCALLBACK; const searchdata): Integer;
var
  i: integer;
begin
  for i := 1 to HandleList_max-1 do
  begin
    if HandleList[i].&type == &type then               //
      if cb(HandleList[i].pointer, searchdata) then  //
        Exit(i);                                     //
  end;

  result := 0;
end;

function OpenProcess(const pid: DWORD): THandle;
var
  processpath: {Array [1..100] of} PChar;
  handle: integer;
begin
  //check if the process exists

  sprintf(processpath, '/proc/%d/', pid);


  //check if this process has already been opened
  handle := SearchHandleList(htProcesHandle, SearchHandleListProcessCallback, *pid);
  if (handle) then
  begin
    debug_log("Already opened. Returning same handle\n");
    PProcessData p=(PProcessData)GetPointerFromHandle(handle);
    p->ReferenceCount++;
    return handle;
  end;

  //still here, so not opened yet


  if (chdir(processpath)==0) then
  begin
    //success

    //create a process info structure and return a handle to it
    PProcessData p=(PProcessData)malloc(sizeof(ProcessData));

    memset(p, 0, sizeof(ProcessData));

    p->ReferenceCount=1;
    p->pid=pid;
    p->path=strdup(processpath);

    sprintf(processpath,"/proc/%d/maps", pid);
    p->maps=strdup(processpath);

    if MEMORY_SEARCH_OPTION == 0 then
    begin
      sprintf(processpath,"/proc/%d/mem", pid);
      p->mem=open(processpath, O_RDONLY);
    end;


    pthread_mutex_init(&p->extensionMutex, NULL);
    p->hasLoadedExtension=0;
    p->extensionFD=0;


    p->isDebugged=0;

    p->threadlistmax=0;
    p->threadlistpos=0;
    p->threadlist=NULL;

    p->debuggedThreadEvent.threadid=0;

    pthread_mutex_init(&p->debugEventQueueMutex, NULL);

    /*
    p->queuedDebugEventList=NULL;
    p->queuedDebugEventListPos=0;
    p->queuedDebugEventListMax=0;
    */

    TAILQ_INIT(&p->debugEventQueue);

    result := CreateHandleFromPointer(p, htProcesHandle);
  end;
  else
    result := 0; //could not find the process

end;

end.

