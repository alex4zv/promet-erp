{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit DateControls;

interface

uses
  DateControlsReg, DatePicker, DBDatePicker, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('DateControlsReg', @DateControlsReg.Register);
end;

initialization
  RegisterPackage('DateControls', @Register);
end.
