#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#define MAX_FRAME_CNT 65536
#define FRAME_BUF_SIZE (32<<20)
#define MAX_FN_LEN 1024
/*** Note- Assumes little endian ***/
void printBits(size_t const size, void const * const ptr);
int findFrameSamplingFrequency(const unsigned char ucHeaderByte);
int findFrameBitRate(const unsigned char ucHeaderByte);
int findMpegVersionAndLayer(const unsigned char ucHeaderByte);
int findFramePadding(const unsigned char ucHeaderByte);
void printmp3details(unsigned int nFrames, unsigned int nSampleRate, double fAveBitRate);
FILE *frameinfo;
FILE *mp3stream;
FILE * ifMp3;
long framepos[MAX_FRAME_CNT];
char framebuf[FRAME_BUF_SIZE];
char outfn[MAX_FN_LEN];
int main(int argc, char** argv)
{
	frameinfo = fopen("frameinfo.txt", "w");
	ifMp3 = fopen(argv[1], "rb");
	int fcl, fcr;
	//ifMp3 = fopen("floating.mp3","rb");
	if (ifMp3 == NULL)
	{
		perror("Error");
		return -1;
	}

	//get file size:
	fseek(ifMp3, 0, SEEK_END);
	long int lnNumberOfBytesInFile = ftell(ifMp3);
	rewind(ifMp3);

	unsigned char ucHeaderByte1, ucHeaderByte2, ucHeaderByte3, ucHeaderByte4;   //stores the 4 bytes of the header

	int nFrames = 0, nFileSampleRate;
	float fBitRateSum = 0;
	long int lnPreviousFramePosition;

syncWordSearch:
	while (ftell(ifMp3) < lnNumberOfBytesInFile)
	{
		ucHeaderByte1 = getc(ifMp3);
		if (ucHeaderByte1 == 0xFF)
		{
			ucHeaderByte2 = getc(ifMp3);
			unsigned char ucByte2LowerNibble = ucHeaderByte2 & 0xF0;
			if (ucByte2LowerNibble == 0xF0 || ucByte2LowerNibble == 0xE0)
			{
				/*if(nFrames>1){
				printf("Previous Frame Length: %ld\n\n",ftell(ifMp3)-2 -lnPreviousFramePosition);
				}*/
				++nFrames; framepos[nFrames] = ftell(ifMp3) - 0x2;
				fprintf(frameinfo, "Found frame %d at offset = %ld B\nHeader Bits:\n",
					nFrames, framepos[nFrames]);

				//get the rest of the header:
				ucHeaderByte3 = getc(ifMp3);
				ucHeaderByte4 = getc(ifMp3);
				//print the header:
				printBits(sizeof(ucHeaderByte1), &ucHeaderByte1);
				printBits(sizeof(ucHeaderByte2), &ucHeaderByte2);
				printBits(sizeof(ucHeaderByte3), &ucHeaderByte3);
				printBits(sizeof(ucHeaderByte4), &ucHeaderByte4);
				//get header info:
				int nFrameSamplingFrequency = findFrameSamplingFrequency(ucHeaderByte3);
				int nFrameBitRate = findFrameBitRate(ucHeaderByte3);
				int nMpegVersionAndLayer = findMpegVersionAndLayer(ucHeaderByte2);

				if (nFrameBitRate == 0 || nFrameSamplingFrequency == 0 || nMpegVersionAndLayer == 0)
				{//if this happens then we must have found the sync word but it was not actually part of the header
					--nFrames;
					fprintf(frameinfo, "Error: not a header\n\n");
					goto syncWordSearch;
				}
				fBitRateSum += nFrameBitRate;
				if (nFrames == 1) { nFileSampleRate = nFrameSamplingFrequency; }
				int nFramePadded = findFramePadding(ucHeaderByte3);
				//calculate frame size:
				int nFrameLength = int((144 * (float)nFrameBitRate /
					(float)nFrameSamplingFrequency) + nFramePadded);
				fprintf(frameinfo, "Frame Length: %d Bytes \n\n", nFrameLength);

				lnPreviousFramePosition = ftell(ifMp3) - 4; //the position of the first byte of this frame

															//move file position by forward by frame length to bring it to next frame:
				fseek(ifMp3, nFrameLength - 4, SEEK_CUR);
			}
		}
	}
	float fFileAveBitRate = fBitRateSum / nFrames;
	framepos[nFrames + 1] = lnNumberOfBytesInFile;
	printmp3details(nFrames, nFileSampleRate, fFileAveBitRate);
	strcpy(outfn, "done_");
	strcat(outfn, argv[1]);
	mp3stream = fopen(outfn, "wb");
	printf("Input frame [L,R]=");
	scanf("%d %d", &fcl, &fcr);
	printf("File opened\n");
	fclose(frameinfo);
	fseek(ifMp3, framepos[fcl], SEEK_SET);
	//printf("%d %d\n", framepos[fcl], framepos[fcr + 1]);
	fread(framebuf, framepos[fcr + 1] - framepos[fcl], 1, ifMp3);
	fwrite(framebuf, framepos[fcr + 1] - framepos[fcl], 1, mp3stream);
	fclose(ifMp3);
	fclose(mp3stream);
	return 0;
}

void printmp3details(unsigned int nFrames, unsigned int nSampleRate, double fAveBitRate)
{
	fprintf(frameinfo, "MP3 details:\n");
	fprintf(frameinfo, "Frames: %d\n", nFrames);
	printf("Frames: %d\n", nFrames);
	fprintf(frameinfo, "Sample rate: %d\n", nSampleRate);
	fprintf(frameinfo, "Ave bitrate: %0.0f\n", fAveBitRate);
}

int findFramePadding(const unsigned char ucHeaderByte)
{
	//get second to last bit to of the byte
	unsigned char ucTest = ucHeaderByte & 0x02;
	//this is then a number 0 to 15 which correspond to the bit rates in the array
	int nFramePadded;
	if ((unsigned int)ucTest == 2)
	{
		nFramePadded = 1;
		fprintf(frameinfo, "padded: true\n");
	}
	else
	{
		nFramePadded = 0;
		fprintf(frameinfo, "padded: false\n");
	}
	return nFramePadded;
}

int findMpegVersionAndLayer(const unsigned char ucHeaderByte)
{
	int MpegVersionAndLayer;
	//get bits corresponding to the MPEG verison ID and the Layer
	unsigned char ucTest = ucHeaderByte & 0x1E;
	//we are working with MPEG 1 and Layer III
	if (ucTest == 0x1A)
	{
		MpegVersionAndLayer = 1;
		fprintf(frameinfo, "MPEG Version 1 Layer III \n");
	}
	else
	{
		MpegVersionAndLayer = 1;
		fprintf(frameinfo, "Not MPEG Version 1 Layer III \n");
	}
	return MpegVersionAndLayer;
}

int findFrameBitRate(const unsigned char ucHeaderByte)
{
	unsigned int bitrate[] = { 0,32000,40000,48000,56000,64000,80000,96000,
		112000,128000,160000,192000,224000,256000,320000,0 };
	//get first 4 bits to of the byte
	unsigned char ucTest = ucHeaderByte & 0xF0;
	//move them to the end
	ucTest = ucTest >> 4;
	//this is then a number 0 to 15 which correspond to the bit rates in the array
	int unFrameBitRate = bitrate[(unsigned int)ucTest];
	fprintf(frameinfo, "Bit Rate: %u\n", unFrameBitRate);
	return unFrameBitRate;
}

int findFrameSamplingFrequency(const unsigned char ucHeaderByte)
{
	unsigned int freq[] = { 44100,48000,32000,00000 };
	//get first 2 bits to of the byte
	unsigned char ucTest = ucHeaderByte & 0x0C;
	ucTest = ucTest >> 6;
	//then we have a number 0 to 3 corresponding to the freqs in the array
	int unFrameSamplingFrequency = freq[(unsigned int)ucTest];
	fprintf(frameinfo, "Sampling Frequency: %u\n", unFrameSamplingFrequency);
	return unFrameSamplingFrequency;
}

void printBits(size_t const size, void const * const ptr)
{
	unsigned char *b = (unsigned char*)ptr;
	unsigned char byte;
	int i, j;

	for (i = size - 1; i >= 0; i--)
	{
		for (j = 7; j >= 0; j--)
		{
			byte = b[i] & (1 << j);
			byte >>= j;
			fprintf(frameinfo, "%u", byte);
		}
	}
	fprintf(frameinfo, "\n");
}
