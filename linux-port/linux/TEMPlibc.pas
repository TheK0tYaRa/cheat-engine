unit TEMPlibc;

{$mode objfpc}{$H+}

interface

uses unixtype;

Const
  clib = 'c';
  dllib = 'dl';
  cryptlib = 'crypt';
  threadslib = 'pthread';

{$I typesh.inc}
{$I bschedh.inc}
{$I glue.inc}
{$I pthreadtypesh.inc}
{$I semaphoreh.inc}
{$I stdinth.inc}
{$I suserh.inc}
{$I sptraceh.inc}

implementation

{$I types.inc}

end.

