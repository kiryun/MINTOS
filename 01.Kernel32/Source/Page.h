#ifndef __PAGE_H__
#define __PAGE_H__

#include "Types.h"

// macro
// 하위 32비트 용 속성 필드
#define PAGE_FLAGS_P        0x00000001 // present
#define PAGE_FLAGS_RW		0x00000002 // read/write
#define PAGE_FLAGS_US		0x00000004 // user/supervisor(플래그 설정 시 유저 레벨)
#define PAGE_FLAGS_PWT      0x00000008 // page level write-through
#define PAGE_FLAGS_PCD      0x00000010 // page level cache disable
#define PAGE_FLAGS_A		0x00000020 // Accessed
#define PAGE_FLAGS_D		0x00000040 // dirty
#define PAGE_FLAGS_PS		0x00000080 // page size
#define PAGE_FLAGS_G		0x00000100 // global
#define PAGE_FLAGS_PAT	    0x00001000 // page attribute table index
// 상위 32비트 용 속성 필드
#define PAGE_FLAGS_EXB	    0x80000000 // execute disable bit
// 기타
#define PAGE_FLAGS_DEFAULT  (PAGE_FLAGS_P | PAGE_FLAGS_RW)
#define PAGE_TABLESIZE      0x1000
#define PAGE_MAXENTRYCOUNT  512
#define PAGE_DEFAULTSIZE    0x200000

// structor
#pragma pack(push, 1)

// 페이지 엔트리에 대한 자료구조
typedef struct  kPageTableEntryStruct
{
    // PML4T와 PDPTE의 경우
    // 1비트 P, RW, US, PWT, PCD, A, D, PS, G 3비트 Avail, 1비트 PAT, 8비트 Reserved,
    // 20비트 BaseAddress
    // PDE의 경우
    // 1비트 P, RW, US, PWT, PCD, A, D, 1, G, 3비트 Avail, 1비트 pat, 8비트 Avail,
    // 11비트 Base Address
    DWORD dwAttributeAndLowerBaseAddress;
    // 8비트 Upper baseAddress, 12비트 reserved, 11비트 Avail, 1비트 EXB
    DWORD dwUpperBaseAddressAndEXB;
}PML4TENTRY, PDPTENTRY, PDENTRY, PTENTRY;
#pragma pack(pop)

// 함수
void kInitializePageTables();
void kSetPageEntryData( PTENTRY* pstEntry, DWORD dwUpperBaseAddress, 
                      DWORD dwLowerBaseAddress, DWORD dwLowerFlags, DWORD dwUpperFlags);

#endif /*__PAGE_H__*/