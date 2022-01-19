unit mmap;

{$mode delphi}

interface

uses
  Classes, SysUtils, unixporthelper,linuxbase,unixtype;

const
  FILE_MAP_READ = 4;

function CreateFileMapping(hFile: THandle; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName:LPCSTR ): THandle;
function MapViewOfFile(hFileMappingObject: THandle;dwDesiredAccess,dwFileOffsetHigh,
  dwFileOffsetLow:DWORD;dwNumberOfBytesToMap:SIZE_T):LPVOID;
function UnmapViewOfFile(lpBaseAddress:LPVOID):BOOL;

function VirtualAllocEx(hProcess: Thandle; lpAddress: Pointer; dwSize: QWord;
  flAllocationType: DWORD; flProtect: DWORD): Pointer;
function VirtualFreeEx(hProcess: Thandle; lpAddress: Pointer; dwSize: QWord;
  dwFreeType: DWORD): Boolean;
function VirtualProtectEx(hProcess: Thandle; lpAddress: Pointer; dwSize: QWord;
  flNewProtect: DWORD; var lpflOldProtect: LongWord):Boolean;

implementation

function CreateFileMappingA(hFile: THandle; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName: LPCSTR): THandle;
begin
  { TODO -cCreateFileMappingA : https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createfilemappinga }
end;

function CreateFileMappingW(hFile: THandle; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName:LPCWSTR ): THandle;
begin
  { TODO -cCreateFileMappingW : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-createfilemappingw }
end;

function CreateFileMapping(hFile: THandle; lpFileMappingAttributes: LPSECURITY_ATTRIBUTES;
  flProtect, dwMaximumSizeHigh, dwMaximumSizeLow: DWORD; lpName:LPCSTR ): THandle;
begin
  { TODO -cCreateFileMappingW : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-createfilemappingw }
  case AWSuffix of
    'A':(CreateFileMappingA(hFile, lpFileMappingAttributes, flProtect,
      dwMaximumSizeHigh, dwMaximumSizeLow, lpName));
    'W':(CreateFileMappingW(hFile, lpFileMappingAttributes, flProtect,
      dwMaximumSizeHigh, dwMaximumSizeLow, wchar_t(byte(lpName))));
  end;
end;

function MapViewOfFile(hFileMappingObject: THandle;dwDesiredAccess,dwFileOffsetHigh,
  dwFileOffsetLow:DWORD;dwNumberOfBytesToMap:SIZE_T):LPVOID;
begin
  { TODO -cMapViewOfFile : mmap the https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-mapviewoffile }
end;

function UnmapViewOfFile(lpBaseAddress:LPVOID):BOOL; //the hell is LPCVOID
begin
  { TODO -cUnmapViewOfFile : mmap the https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-unmapviewoffile }
end;

function VirtualAllocEx(hProcess: Thandle; lpAddress: Pointer; dwSize: QWord;
  flAllocationType: DWORD; flProtect: DWORD): Pointer;
begin
  { #todo -cVirtualAllocEx : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualallocex }
end;

function VirtualFreeEx(hProcess: Thandle; lpAddress: Pointer; dwSize: QWord;
  dwFreeType: DWORD): Boolean;
begin
  { #todo -cVirtualFreeEx : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualfreeex }
end;

function VirtualProtectEx(hProcess: Thandle; lpAddress: Pointer; dwSize: QWord;
  flNewProtect: DWORD; var lpflOldProtect: LongWord):Boolean;
begin
  { #todo -cVirtualProtectEx : https://docs.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualprotectex }
end;

end.

