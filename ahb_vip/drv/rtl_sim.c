#include <inttypes.h>
#include <string.h>
#include <regop.h>
#include "rtl_sim.h"
void sim_end()
{
	*(volatile uint32_t*)0x40000004=0;
}
void sim_dummy_cycle(uint32_t N)
{
	for (int i=0;i<N;i++) *(volatile uint32_t*)0x40002000=0;
}
void sim_open_file_wb(const char *st)
{
	uint32_t len=strlen(st);
	uint32_t ptr=SIM_FN_BASE;
	uint32_t to_write;
	for (int i=0;i<len;i+=4)
	{
		to_write=st[i]<<24;
		if (i+1<len) to_write|=st[i+1]<<16;
		if (i+2<len) to_write|=st[i+2]<<8;
		if (i+3<len) to_write|=st[i+3];
		writel(to_write,ptr);
		ptr+=0x4;
	}
	writel(len,SIM_FN_LEN);
	writel(len,SIM_OPEN_FILEWB);
}
void sim_writeb_file(uint32_t to_write)
{
	writel(to_write,SIM_WRITEB_FILE);
}