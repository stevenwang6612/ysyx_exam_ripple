#include "sdb.h"

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;

  /* TODO: Add more members if necessary */
  char expr_str[32];
  word_t value;

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
int new_wp(char *args){
  bool success = true;
  word_t value;
  value = expr(args,&success);
  if(!success){
    return -2;
  }
  if(free_ == NULL){
    return -1;
  }
  else if(head==NULL){
    head = free_;
    free_ = free_ -> next;
    head->next = NULL;
    strncpy(head->expr_str, args, 31);
    head->value = value;
    return head->NO;
  }else{
    WP *temp = head->next;
    WP *temp_pre = head;
    while(temp != NULL){
      if(temp->NO < free_->NO){
        temp_pre = temp;
        temp = temp->next;
      }else{break;}
    }
    temp_pre->next = free_;
    temp_pre = temp_pre -> next;
    free_ = free_ -> next;
    temp_pre->next = temp;
    strncpy(temp_pre->expr_str, args, 31);
    temp_pre->value = value;
    return temp_pre->NO;
  }
}


int free_wp(char *args){
  WP *temp = NULL;
  WP *temp_pre = NULL;
  WP *temp_free = free_;
  WP *temp_free_pre = NULL;
  int free_no=0;
  //move temp from head to the node need to free
  if(head == NULL){
    return -1;
  }else if(args[0]==':'){
    sscanf(args, ":%d", &free_no);
    temp = head;
    while(temp->NO != free_no && temp->next != NULL){
      temp_pre = temp;
      temp = temp -> next;
    }
  }else{
    temp = head;
    while(strcmp(temp->expr_str,args) != 0 && temp->next != NULL){
      temp_pre = temp;
      temp = temp -> next;
    }
  }
  //move temp_free from free_ to the node going to be inserted
  bool not_tail = temp->NO != free_no && strcmp(temp->expr_str,args) != 0;
  if(temp->next==NULL && not_tail){
    return -2;
  }else{
    while(temp_free->NO < temp->NO && temp_free != NULL){
      temp_free_pre = temp_free;
      temp_free = temp_free -> next;
    }
  }
  //to free
  if(temp_pre == NULL){
    head = head -> next;
  }else{
    temp_pre -> next = temp -> next;
  }
  //to insert
  if(temp_free_pre == NULL){
    temp -> next = free_;
    free_ = temp;
  }else{
    temp -> next = temp_free;
    temp_free_pre -> next = temp;
  }
  return temp->NO;
}

void info_wp(){
  WP *temp = head;
  while(temp != NULL){
    printf("watchpoint[%02d]: %s\t = %-24ld0x%016lx\n",temp->NO,temp->expr_str,temp->value,temp->value);
    temp = temp->next;
  }
}

bool scan_wp(){
  WP *temp = head;
  bool changed = false;
  bool success = true;
  word_t value;
  while(temp != NULL){
    value = expr(temp->expr_str,&success);
    if(temp->value != value){
      printf("watchpoint[%02d] changed: %s\n",temp->NO,temp->expr_str);
      printf("old: %-24ld0x%016lx\n",temp->value,temp->value);
      printf("new: %-24ld0x%016lx\n",value,value);
      temp->value = value;
      changed = true;
    }
    temp = temp->next;
  }
  return changed;
}

