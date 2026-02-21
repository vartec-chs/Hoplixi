; Пользовательский шаблон Inno Setup для Windows EXE.

#define MyAppName "Hoplixi"
#define MyAppVersion "1.0.0"
#define MyAppBuild "1"
#define MyAppPublisher "Hoplixi"
#define MyAppExeName "Hoplixi.exe"
#define MyAppId "c6d1c972-acc4-46af-996d-936b9a1f43d8"
#define ProjectRoot "..\\.."

#define MyFileExt ".hplxdb"
#define MyProgId "Hoplixi.File"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion} (build {#MyAppBuild})
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
SetupIconFile={#ProjectRoot}\\windows\\runner\\resources\\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=.
OutputBaseFilename=HoplixiSetup-{#MyAppVersion}-build-{#MyAppBuild}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autorun"; Description: "Запускать приложение вместе с Windows"; Flags: unchecked

[Files]
Source: "{#ProjectRoot}\\build\\windows\\x64\\runner\\Release\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"
Name: "{autodesktop}\\{#MyAppName}"; Filename: "{app}\\{#MyAppExeName}"; Tasks: desktopicon

; ================= FILE ASSOCIATION =================

[Registry]

; .hplxdb -> Hoplixi.File
Root: HKCU; Subkey: "Software\Classes\{#MyFileExt}"; ValueType: string; ValueData: "{#MyProgId}"; Flags: uninsdeletevalue

; ProgID
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}"; ValueType: string; ValueData: "Hoplixi Vault Database"; Flags: uninsdeletekey

; Icon
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}\DefaultIcon"; ValueType: string; ValueData: "{app}\{#MyAppExeName},0"

; Open command
Root: HKCU; Subkey: "Software\Classes\{#MyProgId}\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

; ================================================

[Run]
Filename: "{app}\\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName,'&','&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  ErrorCode: Integer;
  ConfigPath: string;
  Content: string;
begin
  if CurStep = ssPostInstall then
  begin
    // --- Записываем install_config.json рядом с exe ---
    ConfigPath := ExpandConstant('{app}\install_config.json');

    Content :=
      '{' + #13#10 +
      '  "lang": "' + ActiveLanguage() + '",' + #13#10 +
      '  "autorun": ' + IntToStr(Ord(IsTaskSelected('autorun'))) + #13#10 +
      '}';

    SaveStringToFile(ConfigPath, Content, False);

    // --- Обновляем иконки в проводнике ---
    Exec('ie4uinit.exe', '-show', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode);
  end;
end;
