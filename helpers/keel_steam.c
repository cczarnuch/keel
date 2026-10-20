/* Keel minimal steam.exe-like launcher (modelled on Proton steam_helper/steam.c):
 * sets HKCU\Software\Valve\Steam\ActiveProcess (pid = this process, SteamClientDll64, SteamClientDll),
 * SteamPath/SteamExe, creates Steam3Master_SharedMemLock event, then runs argv[1..] and waits. */
#include <windows.h>
#include <stdio.h>
static void setsz(HKEY k, const wchar_t *n, const wchar_t *v){ RegSetValueExW(k,n,0,REG_SZ,(const BYTE*)v,(lstrlenW(v)+1)*2); }
int wmain(int argc, wchar_t **argv){
  HKEY k; DWORD pid=GetCurrentProcessId(), one=1;
  const wchar_t *steam=L"C:\\Program Files (x86)\\Steam";
  if(!RegCreateKeyExW(HKEY_CURRENT_USER,L"Software\\Valve\\Steam",0,NULL,0,KEY_ALL_ACCESS,NULL,&k,NULL)){
    setsz(k,L"SteamPath",L"C:/Program Files (x86)/Steam"); setsz(k,L"SteamExe",L"C:/Program Files (x86)/Steam/steam.exe"); RegCloseKey(k);}
  if(!RegCreateKeyExW(HKEY_CURRENT_USER,L"Software\\Valve\\Steam\\ActiveProcess",0,NULL,0,KEY_ALL_ACCESS,NULL,&k,NULL)){
    RegSetValueExW(k,L"pid",0,REG_DWORD,(BYTE*)&pid,4);
    setsz(k,L"SteamClientDll64",L"C:\\Program Files (x86)\\Steam\\steamclient64.dll");
    setsz(k,L"SteamClientDll",L"C:\\Program Files (x86)\\Steam\\steamclient.dll");
    RegCloseKey(k);}
  CreateEventW(NULL,FALSE,FALSE,L"Steam3Master_SharedMemLock");
  CreateEventW(NULL,FALSE,FALSE,L"Global\\Valve_SteamIPC_Class");
  SetEnvironmentVariableW(L"SteamPath",steam);
  fwprintf(stderr,L"keel_steam: pid %lu\n",pid);
  if(argc<2) return 0;
  wchar_t *cmd=GetCommandLineW(); /* skip argv[0] */
  if(*cmd==L'"'){cmd++; while(*cmd&&*cmd!=L'"')cmd++; if(*cmd)cmd++;} else while(*cmd&&*cmd!=L' ')cmd++;
  while(*cmd==L' ')cmd++;
  STARTUPINFOW si={sizeof si}; PROCESS_INFORMATION pi;
  if(!CreateProcessW(NULL,cmd,NULL,NULL,FALSE,0,NULL,NULL,&si,&pi)){fwprintf(stderr,L"keel_steam: CreateProcess failed %lu\n",GetLastError());return 1;}
  WaitForSingleObject(pi.hProcess,INFINITE); DWORD rc=0; GetExitCodeProcess(pi.hProcess,&rc); return rc;
}
