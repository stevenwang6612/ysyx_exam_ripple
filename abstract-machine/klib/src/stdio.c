#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdio.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define ZEROPAD	1			/* pad with zero 填补0*/
#define SIGN	2				/* unsigned/signed long */
#define PLUS	4				/* show plus 显示+*/
#define SPACE	8				/* space if plus 加上空格*/
#define LEFT	16			/* left justified 左对齐*/
#define SPECIAL	32		/* 0x /0*/
#define LARGE	64			/* 用 'ABCDEF'/'abcdef' */
static char * number(char * str, unsigned long long num, int base, int size, int precision, int type);


int printf(const char *fmt, ...) {
	panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
	char *str = out;
	int base = 10;
	int flags = 0;
	unsigned long long num = 0;
	int field_width = -1;	/* 输出字段的宽度 */
	int precision = -1;
	int qualifier = -1;
	const char * s;

	for(;*fmt;fmt++){
		if(*fmt!='%'){
			*str++ = *fmt;
			continue;
		}
		while(1){
			fmt++;
			switch (*fmt){		
				case '-': flags |= LEFT; continue;
				case '+': flags |= PLUS; continue;
				case ' ': flags |= SPACE; continue;
				case '#': flags |= SPECIAL; continue;
				case '0': flags |= ZEROPAD; continue;
			}
			break;
		}
		field_width = -1;
		if ('0' <= *fmt && *fmt <= '9'){
			field_width = 0;        			 	 //得到字段宽度
			while('0' <= *fmt && *fmt <= '9'){
				field_width = field_width * 10 + *fmt - 48;
				fmt++;
			}
		}else if (*fmt == '*'){             //*表示可变宽度
			++fmt;
			field_width = va_arg(ap, int);
			if(field_width < 0){	
				field_width = -field_width;
				flags |= LEFT;
			}
		}

		// 获取精度 
		precision = -1;
		if (*fmt == '.'){
			++fmt;	
			if ('0' <= *fmt && *fmt <= '9'){
				precision = 0;               //获得精度
				while('0' <= *fmt && *fmt <= '9'){
					precision = precision * 10 + *fmt - 48;
					fmt++;
				}
			}
			else if (*fmt == '*') {
				++fmt;
				precision = va_arg(ap, int);
			}
			if (precision < 0)//精度不能小于0
				precision = 0;
		}

		//获取转换修饰符,即%hd、%ld、%lld、%Lf...中的h、l、L、Z (ll用q代替)
		qualifier = -1;
		if (*fmt == 'l' && *(fmt + 1) == 'l') {
			qualifier = 'L';//即ll
			fmt += 2;
		} else if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L' ){
			qualifier = *fmt;
			++fmt;
		}

		switch(*fmt){
			case 'c':
				if (!(flags & LEFT))//如果没有'-'标记符
					while (--field_width > 0) *str++ = ' ';
				*str++ = (unsigned char) va_arg(ap, int);
				while (--field_width > 0) *str++ = ' ';
				continue;
			case 's':
				s = va_arg(ap, char *);
				if (!s)                  //如果字符串不存在，则返回(NULL)
					s = "<NULL>";
        if (precision<(signed int)strlen(s))
				  precision = strlen(s);
        field_width -= precision;
				if (!(flags & LEFT))//如果没有'-'标记符
					while (--field_width > 0) *str++ = ' ';
				for(int i=0; i<precision ;i++) *str++ = *s++;
				while (--field_width > 0) *str++ = ' ';
				continue;
			case '%':
				*str++ = '%';
				continue;
			case 'o':
				base = 8;
				break;
			case 'X':
				flags |= LARGE;//小写转大写
			case 'x':  //十六进制
				base = 16;
				break;
			case 'd': case 'i':
        flags |= SIGN;
				break;
      case 'u': break;
      default :
        *str++ = '%';
        if (*fmt)
          *str++ = *fmt;
        else
          --fmt;
        continue;
    }
    switch(qualifier){
      case 'l':
        num = va_arg(ap, unsigned long);
        break;
      case 'L':
        num = va_arg(ap, unsigned long long);
        break;
      case 'h':
        num = (unsigned short) va_arg(ap, int);
        break;
      default:
        num = va_arg(ap, unsigned int);
    }
    if (flags & SIGN)
      num = (signed int) num;
    str = number(str, num, base, field_width, precision, flags);
  }
  *str = '\0';
  return str - out;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  int ret = -1;
  va_start(ap, fmt);
  ret = vsprintf(out, fmt, ap);
  va_end(ap);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

//以特定的进制格式化输出字符
static char * number(char * str, unsigned long long num, int base, int size, int precision, int type)
{
  char c,sign,tmp[66];
  const char *digits="0123456789abcdefghijklmnopqrstuvwxyz";
  int i;

  if (type & LARGE)//输出大写字符，例如十六进制0XFF112233AA
    digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  if (type & LEFT)//如果有'-'，如果出现了左对齐，就取消前面补0
    type &= ~ZEROPAD;
  if (base < 2 || base > 36)
    return 0;
  c = (type & ZEROPAD) ? '0' : ' ';//如果标志符有0则补0，否则补空格；例如%02d
  sign = 0;//符号

  if (type & SIGN) //有符号与无符号的转换
  {
    if ((signed long long)num < 0) 
    {
      sign = '-';
      num = - (signed long long)num;//取正值
      size--;//字段宽度减1
    } else if (type & PLUS) //显示+
    {
      sign = '+';
      size--;
    } else if (type & SPACE)//填补空格
    {
      sign = ' ';
      size--;
    }
  }

  //处理十六进制字宽问题
  if (type & SPECIAL) //十六进制显示
  {
    if (base == 16)
      size -= 2;//0x
    else if (base == 8)
      size--;//0
  }

  i = 0;
  if (num == 0)//如果参数为0，则记录字符0
    tmp[i++]='0'; //tmp中的内容会放到缓冲区中
  else while (num != 0) //循环,num /= base
  {
    tmp[i++] = digits[num % base];//将进制转换,低地址先进tmp？
    num /= base;
  }
  //地址长度大于精度，直接按地址长度输出，如果精度大于地址位数，先补空格
  //例如：printf("%18p\n",&a);-->空格空格00000000FAF27284
  if (i > precision)
    precision = i;
  size -= precision;
  if (!(type&(ZEROPAD+LEFT)))//没有'-'和补0,直接补空格
    while(size-->0)
      *str++ = ' ';
  if (sign)//如果有符号，输出符号，符号包括：'-','+','',0
    *str++ = sign;

  if (type & SPECIAL) //输出8进制或16进制符号0或0x
  {
    if (base==8)
      *str++ = '0';
    else if (base==16) 
    {
      *str++ = '0';
      *str++ = digits[33];//x或X
    }
  }

  if (!(type & LEFT))//没有-
    while (size-- > 0)
      *str++ = c;//c为0或空格
  while (i < precision--)//i为转换后存在tmp中字符的个数
    *str++ = '0';
  while (i-- > 0)
    *str++ = tmp[i];//tmp中存储着转换了的参数
  while (size-- > 0)
    *str++ = ' ';
  return str;
}

#endif
