{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit pVisualPrometApp;

interface

uses
  uBaseVisualApplication, ubasevisualapplicationtools, uBaseVisualControls, 
  uFormAnimate, uPassword, uPrometFrames, uPrometFramesInplaceDB, 
  uprometframesinplace, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('pVisualPrometApp', @Register);
end.
