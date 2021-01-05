#ifndef _RTL_SIM_H_
#define _RTL_SIM_H_
#define SIM_END 0x40000004
#define SIM_FN_BASE 0x40001000
#define SIM_FN_LEN 0x4000000C
#define SIM_OPEN_FILEWB 0x40000010
#define SIM_WRITEB_FILE 0x40000014
void sim_end();
void sim_open_file_wb(const char *st);
void sim_writeb_file(uint32_t to_write);
void sim_dummy_cycle(uint32_t N);
#endif
