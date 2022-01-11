unit mmap;

{$mode delphi}

interface

uses
  Classes, SysUtils, unixporthelper,linuxbase,unixtype;

const
  FILE_MAP_READ = 4;

function CreateFileMapping(hFile: HANDLE; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName:LPCSTR ):HANDLE;
function MapViewOfFile(hFileMappingObject:HANDLE;dwDesiredAccess,dwFileOffsetHigh,
  dwFileOffsetLow:DWORD;dwNumberOfBytesToMap:SIZE_T):LPVOID;
function UnmapViewOfFile(lpBaseAddress:LPVOID):BOOL;
function CloseHandle(hObject:HANDLE):BOOL;

implementation

function CreateFileMappingA(hFile: HANDLE; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName: LPCSTR): HANDLE;
begin
  { TODO -cCreateFileMappingA : https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createfilemappinga }
end;

function CreateFileMappingW(hFile: HANDLE; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName:LPCWSTR ):HANDLE;
begin
  { TODO -cCreateFileMappingW : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-createfilemappingw }
end;

function CreateFileMapping(hFile: HANDLE; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName:LPCSTR ):HANDLE;
begin
  { TODO -cCreateFileMappingW : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-createfilemappingw }
  case AWSuffix of
    'A':(CreateFileMappingA(hFile, lpFileMappingAttributes, flProtect,
      dwMaximumSizeHigh, dwMaximumSizeLow, lpName));
    'W':(CreateFileMappingW(hFile, lpFileMappingAttributes, flProtect,
      dwMaximumSizeHigh, dwMaximumSizeLow, wchar_t(byte(lpName))));
  end;
end;

function MapViewOfFile(hFileMappingObject:HANDLE;dwDesiredAccess,dwFileOffsetHigh,
  dwFileOffsetLow:DWORD;dwNumberOfBytesToMap:SIZE_T):LPVOID;
begin
  { TODO -cMapViewOfFile : mmap the https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-mapviewoffile }
end;

function UnmapViewOfFile(lpBaseAddress:LPVOID):BOOL; //the hell is LPCVOID
begin
  { TODO -cUnmapViewOfFile : mmap the https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-unmapviewoffile }
end;

function CloseHandle(hObject:HANDLE):BOOL;
begin
  { TODO -cCloseHandle : https://docs.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle }
end;

end.

