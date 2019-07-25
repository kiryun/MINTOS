#ifndef __TYPES_H__
#define __TYPES_H__

#define BYTE unsigned char
#define WORD unsigned short
#define DWORD unsigned int
#define QWORD unsigned long
#define BOOL unsigned char

#define TRUE 1
#define FALSE 0
#define NULL 0

#pragma pack(push, 1) // 구조체의 크기 정렬(Size Align)에 관련된 지시어
                      // 구조체의 크기를 1바이트로 정렬하여 추가적인 메모리 공간 더 할당X

//비디오 모드 중 텍스트 모드 화면을 구성하는 자료구조
typedef struct kCharactorStruct
{
    BYTE bCharactor;
    BYTE bAttribute;
}CHARACTER; // 텍스트 모드 화면을 구성하는 문자 하나를 나타내는 구조체
            // 텍스트 모드용 비디오 메모리(0xB8000)에 문자를 편하게 출력할 목적

#pragma pack(pop)
#endif /*__TYPES_H__*/