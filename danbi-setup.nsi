; 상수정의
!define APP_NAME      "Danbi"
!define SUB_NAME      "danbi"
!define DSP_NAME      "단비"
!define EXE_NAME      "danbi.exe"          ; Nuitka --output-filename 값
!define BUILD_DIR     "main.dist"          ; Nuitka 빌드 결과 폴더명
!define PUBLISHER     "Kiro SHIN"
!define CERT_FILE     "codesign.cer"
!define CERT_CODE     "25A7A1C8DA4B989847181110594E7BF5"
!define INST_DIR      "${SUB_NAME}-client"       ; 인스톨폴더
!define OUT_FILE      "${SUB_NAME}-setup.exe"
!define UNINST_KEY    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

; -----------------------------------------
; NSIS 환경설정
; -----------------------------------------
VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=1033 "FileVersion" "${VERSION}.0"
VIAddVersionKey /LANG=1033 "ProductVersion" "${VERSION}.0"
VIAddVersionKey /LANG=1033 "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=1033 "CompanyName" "${PUBLISHER}"
VIAddVersionKey /LANG=1033 "FileDescription" "${OUT_FILE}"
VIAddVersionKey /LANG=1033 "OriginalFilename" "${OUT_FILE}"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Copyright © ${PUBLISHER}"

; --- 임포트(64비트전용) ---
Unicode true
!include "x64.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

; 기본 설정
Name "${APP_NAME}"
OutFile "${OUT_FILE}"
RequestExecutionLevel admin
InstallDir "$PROGRAMFILES64\${INST_DIR}"

; 설치 시작 전 프로세스 정리 - 강제 종료 (삭제/덮어쓰기 에러 방지)
Function .onInit
    ${DisableX64FSRedirection}
    ExecWait 'taskkill /F /IM ${EXE_NAME} /T >nul 2>&1'
FunctionEnd

; -----------------------------------------
; 설치 섹션
; -----------------------------------------
Section "Install"
  ${DisableX64FSRedirection}
  
  ; 기존 폴더 싹 정리 - 없으면 무시
  RMDir /r "$INSTDIR"

  ; 설치 폴더 생성 - 없으면 생성
  SetOutPath "$INSTDIR"

  ; 프로그램 실행 파일 복사
  File /r "${BUILD_DIR}\*.*"

  ; 언인스톨러 파일 생성
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; 기존 공개 인증서(.cer) 있으면 삭제 - ExecWait 만 쓰면 창 뜸. 그래서 nsExec + Pop 조합으로.
  nsExec::Exec 'certutil -delstore "Root" "${CERT_CODE}"'
  Pop $0

  ; 공개 인증서(.cer)를 임시 폴더에 복사한 뒤 설치 - ExecWait 만 쓰면 창 뜸. 그래서 nsExec + Pop 조합으로.
  InitPluginsDir
  File "/oname=$PLUGINSDIR\${CERT_FILE}" "${CERT_FILE}"
  nsExec::Exec 'certutil -addstore -f "Root" "$PLUGINSDIR\${CERT_FILE}"'
  Pop $0

  ; --- 버전 및 크기 자동 추출 ---
  ; 파일에서 버전 정보 추출
  ${GetFileVersion} "$INSTDIR\${EXE_NAME}" $0

  ; 설치된 폴더의 실제 크기 계산
  ${GetSize} "$INSTDIR" "/S=0K" $1 $2 $3
  IntFmt $1 "0x%08X" $1

  ; 제어판(appwiz.cpl)에 등록(레지스트리)
  SetRegView 64
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\${EXE_NAME}"
  WriteRegStr HKLM "${UNINST_KEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayVersion" "$0"
  WriteRegDWORD HKLM "${UNINST_KEY}" "EstimatedSize" "$1"

  ; 바로가기 생성 등
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\${DSP_NAME}.lnk" "$INSTDIR\${EXE_NAME}"
  CreateShortcut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$DESKTOP\${DSP_NAME}.lnk" "$INSTDIR\${EXE_NAME}"
SectionEnd

; -----------------------------------------
; 제거 섹션
; -----------------------------------------
Section "Uninstall"
  ; 64비트 리다이렉션 해제 및 레지스트리 뷰 설정
  ${DisableX64FSRedirection}
  SetRegView 64

  ; 제거 전 프로그램 종료 (폴더 삭제 에러 방지)
  ExecWait 'taskkill /F /IM ${EXE_NAME} /T >nul 2>&1'

  ; 사용자데이터 삭제 여부 확인
  MessageBox MB_YESNO|MB_ICONQUESTION "사용자 데이터를 모두 삭제하시겠습니까?" IDNO skip_appdata
    DetailPrint "사용자 데이터 삭제 중..."
    RMDir /r "$LOCALAPPDATA\${SUB_NAME}"
  skip_appdata:

  ; 설치 폴더 내의 모든 파일 및 폴더 삭제 - ExecWait 만 쓰면 창 뜸. 그래서 nsExec + Pop 조합으로.
  nsExec::Exec 'certutil -delstore "Root" "${CERT_CODE}"'
  Pop $0
  RMDir /r "$INSTDIR"

  ; 시작 메뉴 폴더 및 바로가기 삭제
  RMDir /r "$SMPROGRAMS\${APP_NAME}"

  ; 바탕화면 바로가기 및 레지스트리 삭제
  Delete "$DESKTOP\${DSP_NAME}.lnk"
  DeleteRegKey HKLM "${UNINST_KEY}"

SectionEnd
