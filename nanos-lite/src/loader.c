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

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  uintptr_t entry = loader(pcb, filename);
  if(entry==0){
    panic("The file: %s not found!", filename);
  }else{
    Area kstack = {pcb->stack, pcb->stack + sizeof(pcb->stack)};
    pcb->cp = ucontext(NULL, kstack,(void *)entry);
    pcb->cp->GPRx = (uintptr_t)heap.end - 1024 - 128;
    uint64_t *argc  = heap.end - 1024 - 128;
    uint64_t *arg_p = argc + 1;
    uint64_t *arg_e = heap.end - 1024;
    uint8_t  *str_p = heap.end - 1024;
    uint8_t  *str_e = heap.end;
    *argc = 0;
    int i = 0;
    if(argv){
      while(argv[i]){
        *(arg_p++) = (uintptr_t)str_p;
        if(arg_p>arg_e) panic("Out of the bound of stack!");
        int j = 0;
        while(argv[i][j]){
          *(str_p++) = argv[i][j];
          if(str_p>str_e) panic("Out of the bound of stack!");
          j++;
        }
        *(str_p++) = '\0';
        if(str_p>str_e) panic("Out of the bound of stack!");
        *argc += 1;
        i++;
      }
      *(arg_p++) = 0;
      if(arg_p>arg_e) panic("Out of the bound of stack!");
    }
    i = 0;
    if(envp){
      while(envp[i]){
        *(arg_p++) = (uintptr_t)str_p;
        if(arg_p>arg_e) panic("Out of the bound of stack!");
        int j = 0;
        while(envp[i][j]){
          *(str_p++) = envp[i][j];
          if(str_p>str_e) panic("Out of the bound of stack!");
          j++;
        }
        *(str_p++) = '\0';
        if(str_p>str_e) panic("Out of the bound of stack!");
        i++;
      }
    }
  }
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

