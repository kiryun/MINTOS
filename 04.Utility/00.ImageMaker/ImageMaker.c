#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/io.h> // 우분투에서는 io.h의 위치는 sys내부에 있다.
//#include <unistd.h> // unix기반에서만 include
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#define BYTESOFSECOTR 512

//함수 선언
int AdjustInSectorSize(int iFd, int iSourceSize);
void WriteKernelInformation( int iTargetFd, int iKernelSectorcount );
int CopyFile( int iSourceFd, int iTargetFd );

//Main
int main(int argc, char* argv[])
{
    int iSourceFd;
    int iTargetFd;
    int iBootLoaderSize;
    int iKernel32Sectorcount;
    int iSourceSize;

    if( argc < 3 ){ // BootLoader.asm Kernel32.bin System명령어
        fprintf(stderr, "[ERROR] ImageMaker BootLoader.bin Kernel32.bin\n");
        exit(-1);
    }

    //Disk.img 생성
    if( (iTargetFd = open("Disk.img", O_RDWR | O_CREAT | O_TRUNC,
     __S_IREAD | __S_IWRITE)) == -1 ){
        fprintf(stderr, "[ERROR] Disk.img open fail.\n");
        exit(-1);
    }

    //-----------------------------------------------------------------------
    // 부트로더 파일을 열어서 모든 내용을 디스크 이미지 파일로 복사
    //-----------------------------------------------------------------------
    printf("[INFO] Copy boot loader to image file\n");
    if( (iSourceFd = open( argv[1], O_RDONLY )) == -1){
        fprintf(stderr, "[ERROR] %s open fail\n", argv[1]);
        exit(-1);
    }

    iSourceSize = CopyFile(iSourceFd, iTargetFd);
    close(iSourceFd);

    //파일 크기를 섹터 크기인 512바이트로 맞추기 위해 나머지 부분을 0x00으로 채움
    iBootLoaderSize = AdjustInSectorSize(iTargetFd, iSourceSize);
    printf("[INFO] %s size = [%d] and sector count = [%d]\n",
    argv[1], iSourceSize, iBootLoaderSize);

    //-----------------------------------------------------------------------
    // 32비트 커널 파일을 열어서 모든 내용을 디스크 이미지 파일로 복사
    //-----------------------------------------------------------------------
    printf("[INFO] Copy protected mode kernel to image file\n");
    
    if( (iSourceFd = open(argv[2], O_RDONLY)) == -1 ){
        fprintf(stderr, "[ERROR] %s oepn fail\n", argv[2]);
        exit(-1);
    }

    iSourceSize = CopyFile(iSourceFd, iTargetFd);
    close(iSourceFd);

    //파일 크기를 섹터 크기인 512바이트로 맞추기 위해 나머지 부분을 0x00으로 채움
    iKernel32Sectorcount = AdjustInSectorSize(iTargetFd, iSourceSize);
    printf("[INFO] %s size = [%d] and sector count = [%d]\n",argv[2], iSourceSize, iKernel32Sectorcount );

    //-----------------------------------------------------------------------
    // 디스크 이미지에 커널 정보를 갱신
    //-----------------------------------------------------------------------
    printf("[INFO] Start to write kernel information\n");
    // 부트섹터의 5번째 바이트부터 커널에 대한 정보를 넣음
    WriteKernelInformation(iTargetFd, iKernel32Sectorcount);
    printf("[INFO] Image file create complete\n");

    close(iTargetFd);
    return 0;
}

// 현재 위치부터 512바이트 배수 위치까지 맞추어 0x00으로 채움
int AdjustInSectorSize(int iFd, int iSourceSize)
{
    int i;
    int iAdjustSizeToSector;
    char cCh;
    int iSectorCount;

    iAdjustSizeToSector = iSourceSize % BYTESOFSECOTR;
    cCh = 0x00;

    if( iAdjustSizeToSector != 0){
        iAdjustSizeToSector = 512 - iAdjustSizeToSector;
        printf("[INFO] File size [%ul] and fill [%u] byte\n", iSourceSize,
        iAdjustSizeToSector);
        for(i = 0; i < iAdjustSizeToSector; i++){
            write(iFd, &cCh, 1);
        }
    }else{
        printf("[INFO] File size is aligned 512 byte\n");
    }

    // 섹터 수를 되돌려줌
    iSectorCount = (iSourceSize + iAdjustSizeToSector) / BYTESOFSECOTR;
    return iSectorCount;
}

// 부트로더에 커널에 대한 정보를 삽입
void WriteKernelInformation( int iTargetFd, int iKernelSectorCount )
{
    unsigned short usData;
    long lPosition;

    // 파일의 시작에서 5바이트 떨어진 위치가 커널의 총 섹터 수 정보를 나타낸다.
    // 이를 이용
    lPosition = lseek(iTargetFd, (off_t)5, SEEK_SET);
    if(lPosition == -1){
        fprintf(stderr, "lseek fail. Return value = %d, errno = %d, %d\n",
        lPosition, errno, SEEK_SET);
        exit(-1);
    }

    usData = (unsigned short)iKernelSectorCount;
    write(iTargetFd, &usData, 2);

    printf("[INFO] Total sector count except boot loader [%d]\n",
    iKernelSectorCount);
}

// 소스파일(Source FD)의 내용을 목표 파일(Target FD)에 복사하고 그 크기를 되돌려줌
int CopyFile(int iSourceFd, int iTargetFd)
{
    int iSourceFileSize;
    int iRead;
    int iWrite;
    char vcBuffer[BYTESOFSECOTR];

    iSourceFileSize = 0;
    while(1){
        iRead = read(iSourceFd, vcBuffer, sizeof(vcBuffer));
        iWrite = write(iTargetFd, vcBuffer, iRead);

        if(iRead != iWrite){
            fprintf(stderr, "[ERROR] iRead != iWrite.. \n");
            exit(-1);
        }
        iSourceFileSize += iRead;

        if(iRead != sizeof(vcBuffer)){
            break;
        }
    }

    return iSourceFileSize;
}