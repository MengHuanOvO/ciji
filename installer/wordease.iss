; 词迹 Ciji - Windows 安装包（Inno Setup 6）
#define MyAppName "词迹 Ciji"
#define MyAppVersion "0.1.6"
#define MyAppExeName "ciji.exe"

[Setup]
AppId={{C55F8D4A-9E2B-4B6F-8C1A-3D0E5F7A9B21}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=WordLab
DefaultDirName={autopf}\Ciji
DefaultGroupName=词迹 Ciji
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=..\..\outputs
OutputBaseFilename=CijiSetup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent