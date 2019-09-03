[BITS 64]    ; 이하의 코드는 64비트 코드로 설정

SECTION .text   ; text섹션을 정의

; C언어에서 호출할 수 있도록 이름을 노출함
global kInPortByte, kOutPortByte, kLoadGDTR, kLoadTR, kLoadIDTR

; 포트로 부터 1바이트를 읽음
; PARAM: 포트번호
kInPortByte:
    push rdx    ; 함수에서 임시로 사용하는 레지스터를 스택에 저장
                ; 함수의 마지막 부분에서 스택에 삽입된 값을 꺼내 복원

    mov rdx, rdi    ; rdx에 파라미터 1(포트번호)를 저장
    mov rax, 0      ; rdx 초기화
    in al, dx       ; dx에 저장된 포트 어드레스에서 한바이트를 읽어
                    ; al에 저장, al은 함수의 반환값으로 사용됨
    
    pop rdx         ; 함수에서 사용이 끝난 레지스터 복원
    ret             ; 함수를 호출한 다음 코드의 위치로 복귀

; 포트에 1바이트 씀
; PARAM: 포트번호, 데이터
kOutPortByte:
    push rdx
    push rax        ; 함수의 마지막 부분에서 스택에 삽입된 값을 꺼내 복원

    mov rdx, rdi    ; rdx에 파라미터1(포트번호) 저장
    mov rax, rsi    ; rax에 파라미터2(데이터) 저장
    out dx, al      ; dx에 저장된 포트 어드레스에 al에 저장된 한바이트를 쓴다

    pop rax
    pop rdx
    ret

; GDTR레지스터에 GDT 테이블을 설정
; PARAM: GDT 테이블의 정보를 저장하는 자료구조의 어드레스
kLoadGDTR:
    lgdt[rdi]   ; 파라미터 1(GDTR의 어드레스)를 프로세서에 로드하여
                ; GDT 테이블을 설정

    ret

; TR 레지스터에 tss 세그먼트 디스크립터 설정
; PARAM: TSS 세그먼트 디스크립터의 오프셋
kLoadTR:
    ltr di      ; 파라미터 1(TSS 세그먼트 디스크립터의 오프셋)을 프로세서에
                ; 설정하여 tss세그먼트를 로드

    ret

; IDTR 레지스터에 idt 테이블을 설정
; PARAM: IDT 테이블의 정보를 저장하는 자료구조의 어드레스
kLoadIDTR:
    lidt[rdi]   ; 파라미터 1(IDTR의 어드레스)을 프로세서에 로드하여
                ; IDT 테이블을 설정

    ret

