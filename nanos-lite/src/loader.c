#include <proc.h>
#include <elf.h>
#include <fs.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif


static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr elf_hdr = {};
  int fd = fs_open(filename, 0, 0);
  if(fd<0) return 0;
  fs_read(fd, &elf_hdr, sizeof(Elf_Ehdr));
  assert(*(uint32_t *)elf_hdr.e_ident == 0x464c457f);
  size_t prog_header_offset = elf_hdr.e_phoff;
  size_t prog_header_size = elf_hdr.e_phentsize;
  uint32_t prog_idx = 0;
  while(prog_idx < elf_hdr.e_phnum){
    Elf_Phdr prog_hdr = {};
    fs_lseek(fd, prog_header_offset, SEEK_SET);
    fs_read(fd, &prog_hdr, sizeof(Elf_Phdr));
    prog_header_offset += prog_header_size;
    prog_idx++;
    if(PT_LOAD==prog_hdr.p_type){
    fs_lseek(fd, prog_hdr.p_offset, SEEK_SET);
    fs_read(fd, (void *)prog_hdr.p_vaddr, prog_hdr.p_filesz);
    memset((void *)(prog_hdr.p_vaddr + prog_hdr.p_filesz), 0, prog_hdr.p_memsz - prog_hdr.p_filesz);
    }
  }
  fs_close(fd);
  return elf_hdr.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  if(entry==0){
    panic("The file: %s not found!", filename);
  }else{
    Log("Jump to entry = %#x", entry);
    ((void(*)())entry) ();
  }
}

