#include "Types.h"
#include "Keyboard.h"
#include "Descriptor.h"

// 함수 선언
void kPrintString(int iX, int iY, const char* pcString);

// 아래 함수는 C언어 커널의 시작 부분임
void Main()
{
    char vcTemp[2] = {0, };
    BYTE bFlags;
    BYTE bTemp;
    int i = 0;

    kPrintString(0, 10, "Switch To IA-32e Mode Success!");
    kPrintString(0, 11, "IA-32e C Language Kernel Start..............[Pass]");

    kPrintString(0, 12, "GDT Initialize And Switch For IA-32e Mode...[    ]");
    kInitializeGDTTableAndTSS();
    kLoadGDTR(GDTR_STARTADDRESS);
    kPrintString(45, 12, "Pass");

    kPrintString(0, 13, "TSS Segment Load............................[    ]");
    kLoadTR(GDT_TSSSEGMENT);
    kPrintString(45, 13, "Pass");

    kPrintString(0, 14, "IDT Segment Load............................[    ]");
    kInitializeIDTTables();
    kLoadIDTR(IDTR_STARTADDRESS);
    kPrintString(45, 14, "Pass");


    kPrintString(0, 15, "Keyboard Activate...........................[    ]");

    // 키보드를 활성화
    if(kActivateKeyboard() == TRUE){
        kPrintString(45, 15, "Pass");
        kChangeKeyboardLED(FALSE, FALSE, FALSE);
    }else{
        kPrintString(45, 15, "Fail");
        while(1);
    }
    
    while(1){
        // 출력 버퍼(0x60)가 차있으면 스캔 코드를 읽을 수 있음
        if(kIsOutputBufferFull() == TRUE){
            // 출력 버퍼에서 스캔코드를 읽어서 저장
            bTemp = kGetKeyboardScanCode();

            // 스캔코드를 ascii코드로 변환하는 함수를 호출하여 ascii코드와
            // 눌림/떨어짐 정보를 반환
            if(kConvertScanCodeToASCIICode(bTemp, &(vcTemp[0]), &bFlags) == TRUE){
                // 키가 눌려있으면 키의 ascii코드값을 화면에 출력
                if(bFlags & KEY_FLAGS_DOWN){
                    kPrintString(i++, 16, vcTemp);
                    // 0이 입력되면 변수를 0으로 나누어 Divide Error 예외(벡터0번)를 발생시킴
                    if(vcTemp[0] == '0'){
                        // 아래코드를 수행하면 Divide Error 예외가 발생하여
                        // 커널의 임시 핸들러가 수행됨
                        bTemp = bTemp / 0;
                    }
                }
            }
        }
    }
}
