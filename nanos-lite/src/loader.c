#include <proc.h>
#include <elf.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);


static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr elf_hdr = {};
  ramdisk_read(&elf_hdr, 0, sizeof(Elf_Ehdr));
  assert(*(uint32_t *)elf_hdr.e_ident == 0x464c457f);
  size_t prog_header_offset = elf_hdr.e_phoff;
  size_t prog_header_size = elf_hdr.e_phentsize;
  uint32_t prog_idx = 0;
  while(prog_idx < elf_hdr.e_phnum){
    Elf_Phdr prog_hdr = {};
    ramdisk_read(&prog_hdr, prog_header_offset, sizeof(Elf_Phdr));
    prog_header_offset += prog_header_size;
    prog_idx++;
    if(PT_LOAD==prog_hdr.p_type){
    ramdisk_read((void *)prog_hdr.p_vaddr, prog_hdr.p_offset, prog_hdr.p_filesz);
    memset((void *)(prog_hdr.p_vaddr + prog_hdr.p_filesz), 0, prog_hdr.p_memsz - prog_hdr.p_filesz);
    }
  }
  return elf_hdr.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %#x", entry);
  ((void(*)())entry) ();
}

