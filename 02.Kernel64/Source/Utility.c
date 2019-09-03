#include "Utility.h"

// 메모리를 특정 값으로 채움
void kMemSet(void* pvDestination, BYTE bData, int iSize)
{
    int i;

    for(i=0; i<iSize; i++){
        ((char*)pvDestination)[i] = bData;
    }
}

// 메모리에 복사
int kMemCpy(void* pvDestination, const void* pvSource, int iSize)
{
    int i;

    for(i=0; i<iSize; i++){
        ((char*)pvDestination)[i] = ((char*)pvSource)[i];
    }

    return iSize;
}

// 메모리 비교
int kMemCmp(const void* pvDestination, const void* pvSource, int iSize)
{
    int i;
    char cTemp;

    for(i=0; i<iSize; i++){
        cTemp = ((char*)pvDestination)[i] - ((char*)pvSource)[i];
        if(cTemp != 0){
            return (int)cTemp;
        }
    }

    return 0;
}

// 문자열을 x, y 위치에 출력
void kPrintString(int iX, int iY, const char* pcString)
{
    CHARACTER* pstScreen = (CHARACTER*)0xB8000;
    int i;

    // x, y 좌표를 이용해서 문자열을 출력할 어드레스를 계산
    pstScreen += (iY * 80) +iX;

    // NULL이 나올 때까지 문자열 출력
    for(i=0; pcString[i] != 0; i++){
        pstScreen[i].bCharactor = pcString[i];
    }
}