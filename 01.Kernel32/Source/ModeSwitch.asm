[BITS 32]   ; 이하 코드는 32비트 코드로 설정

; C언어에서 호출할 수있도록 이름을 노출함(Export)
global kReadCPUID, kSwitchAndExecute64bitKernel

Section .text   ; text 섹션을 정의

; CPUID를 반환
; PARAM: DWORD dwEAX, DWORD* pdwEAX, * pdwEAX, * pdwEBX, * pdwECX, * pdwEDX
kReadCPUID:
    push ebp        ; 베이스 포인터 레지스터(ebp)를 스택에 삽입
    mov ebp, esp    ; 베이스 포인터 레지스터(ebp)에 스택 포인터 레지스터(esp)의 값을 설정
    push eax        ; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서
    push ebx        ; 스택에 삽입된 value을 꺼내 원래 value로 복원
    push ecx
    push edx
    push esi

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; eax 레지스터의 value로 CPUID 명령어 실행
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, dword [ ebp + 8 ]  ; 파라미터 1(dwEAX)를 EAX 레지스터에 저장
    cpuid                       ; CPUID 명령어 실행

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 반환된 value을 파라미터에 저장
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; *pdwEAX
    mov esi, dword [ ebp + 12 ] ; 파라미터 2(pdwEAX)를 ESI 레지스터에 저장
    mov dword [ esi ], eax      ; pdwEAX가 포인터이므로 포인터가 가리키는 어드레스에
                                ; eax 레지스터의 value를 저장
    
    ; *pdwEBX
    mov esi, dword [ ebp + 16]  ; 파라미터 3(pdwEBX)를 esi레지스터에 저장
    mov dword [ esi ], ebx      ; pdwEBX가 포인터이므로 포인터가 가리키는 어드레스에
                                ; ebx 레지스터의 value를 저장 

    ; *pdwECX
    mov esi, dword [ ebp + 20]  ; 파라미터 4(pdwECX)를 esi레지스터에 저장
    mov dword [ esi ], ecx      ; pdwECX가 포인터이므로 포인터가 가리키는 어드레스에
                                ; ecx 레지스터의 value를 저장
    
    ; *pdwEDX
    mov esi, dword [ ebp + 24]  ; 파라미터 5(pdwEDX)를 esi레지스터에 저장
    mov dword [ esi ], edx      ; pdwEDX가 포인터이므로 포인터가 가리키는 어드레스에
                                ; edx 레지스터의 value를 저장
    
    ; 함수에서 사용이 끝난 esi 레지스터부터 ebp레지스터까지를 스택에 삽입된 value을 이용해서 복원
    pop esi     
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp ; ebp(base pointer register) 복원
    ret     ; 복귀

; IA-32e 모드로 전환하고 64비트 커널을 수행
; PARAM: 없음
kSwitchAndExecute64bitKernel:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; CR4 컨트롤 레지스터의 pae비트를 1로 설정
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, CR4    ; cr4를 eax레지스터에 저장
    or eax, 0x20    ; pae 비트(비트5)를 1로 설정
    mov cr4, eax    ; pae 비트가 1로 설정된 값을 cr4에 저장

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; cr3 컨트롤 레지스터에 pml4 테이블의 어드레스와 캐시 활성화
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, 0x100000   ; eax에 pml4 테이블이 존재하는 0x100000(1mb)를 저장
    mov cr3, eax        ; cr3 에 0x100000를 저장 ; page 시작부분을 0x100000로 저장(base 설정)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; IA32_EFER.LME를 1로 설정하여 IA-32e모드를 활성화
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ecx, 0xC0000080 ; IA32_EFER MSR 레지스터의 어드레스를 지정
    rdmsr               ; msr 레지스터를 읽기

    or eax, 0x0100      ; eax 레지스터에 저장된 IA32_EFER MSR의 하위 32비트에서
                        ; LME비트(비트 8)을 1로 설정
    wrmsr               ; MSR 레지스터에 쓰기

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; cr0를 nw(bit 29) = 0, cd(bit 30) = 0, pg(bit 31) = 1로
    ; 설정하여 write back 기능 활성화 , 캐시 기능, 페이징 기능을 활성화
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, cr0        ; eax에 cr0를 저장
    or eax, 0xE0000000  ; nw(bit 29), cd(bit 30), pg(bit 31)을 모두 1로 설정
    xor eax, 0x60000000 ; nw(bit 29)와 cd(bit 30)을 xor하여 0으로 설정
    mov cr0, eax        ; nw = 0, cd = 0, pg =1로 설정한 value를 다시 cr0에 저장

    jmp 0x08:0x200000   ; cs를 IA-32e모드용 코드 세그먼트 디스크립터로 교체하고
                        ; 0x200000(2mb)로 이동

    ; 여기는 실행되지 않음
    jmp $