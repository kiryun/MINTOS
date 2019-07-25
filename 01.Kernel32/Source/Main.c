#include "Types.h"

void kPrintString( int iX, int iY, const char* pcString );

// Main
// c코드의 엔트리 포인트 함수
// 0x10200 어드레스에 위치
// 보호모드 엔트리 포인트(EntryPoint.s)에서 최초로 실행되는 C코드
// Main()함수를 가장 앞쪽으로 위치 시켜, 컴파일 시에 코드 섹션의 가장 앞쪽에 위치하게 한 것
void Main(void)
{
    // 메시지 표시
    kPrintString(0, 3, "C Language Kernel Started!");
  
    // 무한 루프
    while(1);
}

// 문자열 출력함수
// x,y에 문자열을 출력해주는 함수
// 텍스트모드용 비디오 메모리 어드레스(0xB8000)에 문자를 갱신 시킨다.
void kPrintString( int iX, int iY, const char* pcString )
{
    CHARACTER* pstScreen = (CHARACTER*)0xB8000;
    int i;

    pstScreen += (iY * 80) + iX;
    for(i = 0; pcString[i] != 0; i++){
        pstScreen[i].bCharactor = pcString[i];
    }
}