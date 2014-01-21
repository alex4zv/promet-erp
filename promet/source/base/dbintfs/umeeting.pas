{*******************************************************************************
  Copyright (C) Christian Ulrich info@cu-tec.de

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or commercial alternative
  contact us for more information

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
*******************************************************************************}
unit umeeting;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uBaseDbClasses, db, uBaseDbInterface,uIntfStrConsts,
  uBaseERPDBClasses,utask,LCLProc;
type
  TMeetings = class;
  TMeetingEntrys = class(TBaseDBDataSet)
    procedure DataSetAfterCancel(aDataSet: TDataSet);
    procedure DataSetBeforeCancel(aDataSet: TDataSet);
  private
    FTempUsers : TUser;
    FOldPosNo: Integer;
    FDoNumber: Boolean;
    FIntDataSource : TDataSource;
    function GetownerName: string;
    function GetPosNo: TField;
    function GetUserName: string;
  protected
    FMeeting : TMeetings;
  public
    constructor Create(aOwner: TComponent; DM: TComponent;
      aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    destructor Destroy; override;
    procedure Open; override;
    procedure Change; override;
    procedure SetDisplayLabels(aDataSet: TDataSet); override;
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure FillDefaults(aDataSet: TDataSet); override;
    property OwnerName : string read GetownerName;
    property UserName : string read GetUserName;
    //Fields
    property PosNo : TField read GetPosNo;
  end;
  TMeetingUsers = class(TBaseDBDataSet)
  protected
    FMeeting : TMeetings;
  public
    procedure Change; override;
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure SetDisplayLabels(aDataSet: TDataSet); override;
  end;
  TMeetingLinks = class(TLinks)
  public
    procedure FillDefaults(aDataSet : TDataSet);override;
  end;
  TMeetings = class(TBaseDbList,IPostableDataSet)
  private
    FEntrys: TMeetingEntrys;
    FLinks: TMeetingLinks;
    FUsers: TMeetingUsers;
  public
    constructor Create(aOwner: TComponent; DM: TComponent;
      aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    function CreateTable: Boolean; override;
    destructor Destroy; override;
    procedure CascadicPost; override;
    procedure CascadicCancel; override;
    function DoPost: TPostResult;
    procedure FillDefaults(aDataSet : TDataSet);override;
    function GetTextFieldName: string;override;
    function GetStatusFieldName : string;override;
    function GetNumberFieldName : string;override;
    procedure DefineFields(aDataSet : TDataSet);override;
    property Entrys : TMeetingEntrys read FEntrys;
    property Users : TMeetingUsers read FUsers;
    property Links : TMeetingLinks read FLinks;
  end;

implementation
uses uBaseApplication,uProjects,uData,uMasterdata;
resourcestring
  strPresent                            = 'Anwesend';
procedure TMeetingLinks.FillDefaults(aDataSet: TDataSet);
begin
  inherited FillDefaults(aDataSet);
  aDataSet.FieldByName('RREF_ID').AsVariant:=(Parent as TMeetings).Id.AsVariant;
end;

procedure TMeetingUsers.Change;
begin
  inherited Change;
  if Assigned(FMeeting) then FMeeting.Change;
end;

procedure TMeetingUsers.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'MEETINGUSERS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('USER_ID',ftLargeint,0,False);
            Add('NAME',ftString,150,False);
            Add('IDCODE',ftString,4,False);
            Add('ACTIVE',ftString,1,False);
            Add('NOTE',ftString,200,False);
          end;
    end;
end;

procedure TMeetingUsers.SetDisplayLabels(aDataSet: TDataSet);
begin
  inherited SetDisplayLabels(aDataSet);
  SetDisplayLabelName(aDataSet,'ACTIVE',strPresent);
end;

constructor TMeetingEntrys.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  FIntDataSource := TDataSource.Create(Self);
  FIntDataSource.DataSet := DataSet;
  DataSet.AfterCancel:=@DataSetAfterCancel;
  DataSet.BeforeCancel:=@DataSetBeforeCancel;
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          Limit := 0;
          SortFields:='POSNO';
          SortDirection:=sdAscending;
        end;
    end;
  FTempUsers := TUser.Create(aOwner,DM);
end;

destructor TMeetingEntrys.Destroy;
begin
  FTempUsers.Destroy;
  FIntDataSource.Destroy;
  inherited Destroy;
end;

procedure TMeetingEntrys.Open;
var
  aRec: LargeInt;
begin
  inherited Open;
  aRec := GetBookmark;
  Last;
  FOldPosNo := PosNo.AsInteger;
  GotoBookmark(aRec);
end;

procedure TMeetingEntrys.Change;
begin
  inherited Change;
  if Assigned(FMeeting) then FMeeting.Change;
end;

procedure TMeetingEntrys.SetDisplayLabels(aDataSet: TDataSet);
begin
  inherited SetDisplayLabels(aDataSet);
  SetDisplayLabelName(aDataSet,'USER',strWorker);
  SetDisplayLabelName(aDataSet,'OWNER',strResponsable);
end;

procedure TMeetingEntrys.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'MEETINGENTRYS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('POSNO',ftInteger,0,True);
            Add('DESC',ftMemo,0,False);
            Add('LINK',ftString,200,False);
            Add('OWNER',ftString,20,False);
            Add('USER',ftString,20,False);
            Add('DUEDATE',ftDateTime,0,False);
            Add('PARENT',ftLargeint,0,False);
            Add('HASCHILDS',ftString,1,False);
            Add('EXPANDED',ftString,1,False);
          end;
    end;
end;

procedure TMeetingEntrys.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      PosNo.AsInteger := (FOldPosNo+1);
      FOldPosNo:=PosNo.AsInteger;
    end;
end;

procedure TMeetingEntrys.DataSetAfterCancel(aDataSet: TDataSet);
begin
  if FDoNumber then
    FOldPosNo:=PosNo.AsInteger;
end;

procedure TMeetingEntrys.DataSetBeforeCancel(aDataSet: TDataSet);
begin
  FDoNumber := DataSet.State=dsInsert;
end;

function TMeetingEntrys.GetownerName: string;
begin
  Result := '';
  if FieldByName('OWNER').AsString='' then exit;
  if not FTempUsers.DataSet.Active then
    Data.SetFilter(FTempUsers,'',0);
  debugln(FieldByName('OWNER').AsString);
  if FTempUsers.DataSet.Locate('ACCOUNTNO',FieldByName('OWNER').AsString,[loCaseInsensitive]) then
    Result := FTempUsers.FieldByName('NAME').AsString;
end;

function TMeetingEntrys.GetPosNo: TField;
begin
  Result := FieldByName('POSNO');
end;

function TMeetingEntrys.GetUserName: string;
begin
  Result := '';
  if FieldByName('USER').AsString='' then exit;
  if not FTempUsers.DataSet.Active then
    Data.SetFilter(FTempUsers,'',0);
  debugln(FieldByName('USER').AsString);
  if FTempUsers.DataSet.Locate('ACCOUNTNO',FieldByName('USER').AsString,[loCaseInsensitive]) then
    Result := FTempUsers.FieldByName('NAME').AsString;
end;

constructor TMeetings.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  FEntrys := TMeetingEntrys.Create(aOwner,DM,aConnection,DataSet);
  FEntrys.FMeeting := Self;
  FUsers := TMeetingUsers.Create(aOwner,DM,aConnection,DataSet);
  FUsers.FMeeting := Self;
  FLinks := TMeetingLinks.Create(Self,DM,aConnection);
end;

function TMeetings.CreateTable: Boolean;
begin
  Result:=inherited CreateTable;
  FEntrys.CreateTable;
  FUsers.CreateTable;
end;

destructor TMeetings.Destroy;
begin
  FreeAndNil(FEntrys);
  FreeAndNil(FUsers);
  inherited Destroy;
end;

procedure TMeetings.CascadicPost;
begin
  inherited CascadicPost;
  FEntrys.CascadicPost;
  FUsers.CascadicPost;
end;

procedure TMeetings.CascadicCancel;
begin
  inherited CascadicCancel;
  FEntrys.CascadicCancel;
  FUsers.CascadicCancel;
end;
function TMeetings.DoPost: TPostResult;
var
  ProjectLink: String = '';
  aProject: TProject = nil;
  asl: TStringList;
  arec: LargeInt;
  Added : Boolean = False;
  aTasks: TTask;
  aDataSet: TBaseDBDataset = nil;
  aLink: String;
  Hist : IBaseHistory;
  aHist: TBaseHistory;
  aDataSetClass: TBaseDBDatasetClass;
begin
  aLink := '';
  Result := prFailed;
  if not Self.DataSet.FieldByName('DATE').IsNull then
    begin
      Result:=prAlreadyPosted;
      exit;
    end;
  Data.StartTransaction(Connection);
  try
    with Entrys.DataSet do
      begin
        First;
        while not EOF do
          begin
            Added := False;
            if (copy(FieldByName('LINK').AsString,0,9) = 'PROJECTS@')
            or (copy(FieldByName('LINK').AsString,0,11) = 'PROJECTS.ID')
            then
              ProjectLink := FieldByName('LINK').AsString;
            if (FieldByName('LINK').AsString<>'') and (aLink <> FieldByName('LINK').AsString) then
              begin
                FreeAndNil(aDataSet);
                FreeAndNil(aProject);
                aLink := FieldByName('LINK').AsString;
                aDataSetClass := TBaseDBModule(DataModule).DataSetFromLink(aLink);
                aDataSet := aDataSetClass.Create(nil,DataModule,Connection);
                TBaseDbList(aDataSet).SelectFromLink(aLink);
                aDataSet.Open;
                if ProjectLink <> '' then
                  begin
                    aProject := TProject.Create(nil,DataModule,Connection);
                    aProject.SelectFromLink(ProjectLink);
                    aProject.Open;
                  end;
              end
            else if aLink <> '' then
              begin
                if Assigned(aProject) and (aProject.Count>0) then
                  begin
                    if FieldByName('OWNER').AsString <> '' then
                      begin //Task
                        aProject.Tasks.Open;
                        aProject.Tasks.Append;
                        asl := TStringList.Create;
                        asl.Text:=FieldByName('DESC').AsString;
                        if asl.Count>0 then
                          begin
                            aProject.Tasks.FieldByName('SUMMARY').AsString:=copy(asl[0],0,150);
                            if length(asl[0])>150 then
                              asl[0] := copy(asl[0],151,length(asl[0]))
                            else
                              asl.Delete(0);
                          end;
                        aProject.Tasks.FieldByName('DESC').AsString:=asl.Text;
                        asl.Free;
                        aProject.Tasks.FieldByName('OWNER').AsString:=FieldByName('OWNER').AsString;
                        aProject.Tasks.FieldByName('USER').AsVariant:=FieldByName('USER').AsVariant;
                        if FieldByName('USER').IsNull then
                          aProject.Tasks.FieldByName('USER').AsVariant:=FieldByName('OWNER').AsVariant;
                        if not FieldByName('DUEDATE').IsNull then
                          aProject.Tasks.FieldByName('DUEDATE').AsVariant:=FieldByName('DUEDATE').AsVariant;
                        aProject.Tasks.DataSet.Post;
                        arec := aProject.Tasks.GetBookmark;
                        aProject.Tasks.DataSet.Refresh;
                        aProject.Tasks.GotoBookmark(arec);
                        if not Entrys.CanEdit then
                          Entrys.DataSet.Edit;
                        Entrys.FieldByName('LINK').AsString:=Data.BuildLink(aProject.Tasks.DataSet);
                        if Entrys.CanEdit then
                          Entrys.DataSet.Post;
                        Added := True;
                      end;
                  end;
                if (not Added) and (FieldByName('OWNER').AsString <> '') then
                  begin //Task
                    aTasks := TTask.Create(nil,Data);
                    aTasks.Append;
                    asl := TStringList.Create;
                    asl.Text:=FieldByName('DESC').AsString;
                    if asl.Count>0 then
                      begin
                        aTasks.FieldByName('SUMMARY').AsString:=asl[0];
                        asl.Delete(0);
                      end;
                    aTasks.FieldByName('DESC').AsString:=asl.Text;
                    asl.Free;
                    aTasks.FieldByName('OWNER').AsString:=FieldByName('OWNER').AsString;
                    aTasks.FieldByName('USER').AsVariant:=FieldByName('USER').AsVariant;
                    if FieldByName('USER').IsNull then
                      aTasks.FieldByName('USER').AsVariant:=FieldByName('OWNER').AsVariant;
                    if not FieldByName('DUEDATE').IsNull then
                      aTasks.FieldByName('DUEDATE').AsVariant:=FieldByName('DUEDATE').AsVariant;
                    aTasks.DataSet.Post;
                    arec := aTasks.GetBookmark;
                    aTasks.DataSet.Refresh;
                    aTasks.GotoBookmark(arec);
                    if not Entrys.CanEdit then
                      Entrys.DataSet.Edit;
                    Entrys.FieldByName('LINK').AsString:=Data.BuildLink(aTasks.DataSet);
                    if Entrys.CanEdit then
                      Entrys.DataSet.Post;
                    Added := True;
                  end;
                if (not Added) and Assigned(aDataSet) and Supports(aDataSet, IBaseHistory, Hist) and (aDataSet.Count>0) then
                  begin
                    Added := True;
                    aHist := Hist.GetHistory;
                    aHist.AddItem(Data.Users.DataSet,FieldByName('DESC').AsString,Data.BuildLink(Self.DataSet),Self.DataSet.FieldByName('NAME').AsString,nil,ACICON_USEREDITED,'',True,True)
                  end;
              end;
            Next;
          end;
        if not Self.CanEdit then
          Self.DataSet.Edit;
        Self.DataSet.FieldByName('DATE').AsDateTime:=Now();
        Self.CascadicPost;
        Data.CommitTransaction(Connection);
        Result:=prSuccess;
      end;
      FreeAndNil(aProject);
      FreeAndNil(aDataSet);
    except
      on e : Exception do
        begin
          Result := prFailed;
          Data.RollbackTransaction(Connection);
          debugln(e.Message);
        end;
    end;
end;
procedure TMeetings.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      FieldByName('STATUS').AsString := 'P';
      FieldByName('STARTTIME').AsDateTime:=Now();
    end;
end;

function TMeetings.GetTextFieldName: string;
begin
  Result := 'NAME';
end;

function TMeetings.GetStatusFieldName: string;
begin
  Result:='STATUS';
end;

function TMeetings.GetNumberFieldName: string;
begin
  Result := 'SQL_ID';
end;

procedure TMeetings.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'MEETINGS';
      TableCaption:=strMeetings;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('NAME',ftString,200,False);
            Add('STATUS',ftString,4,True);
            Add('DESC',ftMemo,0,False);
            Add('DATE',ftDateTime,0,False);
            Add('STARTTIME',ftDateTime,0,False);
            Add('ENDTIME',ftDateTime,0,False);
            Add('CREATEDBY',ftString,4,False);
          end;
    end;
end;

end.

