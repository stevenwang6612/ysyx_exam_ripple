#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
	const char* end = s;
	while (*end != '\0') {end++;}
	return end - s;
}

char *strcpy(char *dst, const char *src) {
	size_t i;
	for (i = 0; src[i] != '\0'; i++)
		dst[i] = src[i];
	dst[i] = '\0';
	return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
	size_t i;
	for (i = 0; i < n && src[i] != '\0'; i++)
		dst[i] = src[i];
	for ( ; i < n; i++)
		dst[i] = '\0';
	return dst;
}

char *strcat(char *dst, const char *src) {
	size_t dst_len = strlen(dst);
	size_t i;
	for (i = 0 ; src[i] != '\0' ; i++)
		dst[dst_len + i] = src[i];
	dst[dst_len + i] = '\0';
	return dst;
}

char *strncat(char *dst, const char *src, size_t n) {
	size_t dst_len = strlen(dst);
	size_t i;
	for (i = 0 ; i < n && src[i] != '\0' ; i++)
		dst[dst_len + i] = src[i];
	dst[dst_len + i] = '\0';
	return dst;
}

int strcmp(const char *s1, const char *s2) {
	const char *p = s1;
	const char *q = s2;
	while(*p == *q && *p != '\0'){
		p++;
		q++;
	}
	return *(unsigned char*)p - *(unsigned char*)q; 
}

int strncmp(const char *s1, const char *s2, size_t n) {
	const char *p = s1;
	const char *q = s2;
	while(*p == *q && *p != '\0' && n-- > 0){
		p++;
		q++;
	}
	return *(unsigned char*)p - *(unsigned char*)q; 
}

void *memset(void *s, int c, size_t n) {
	char *dst = (char*)s;
	for (;n>0;n--){*dst++ = c;}
	return s;
}

void *memmove(void *dst, const void *src, size_t n) {
	void * ret = dst;
	if (dst <= src || (char *)dst >= ((char *)src + n)){
		while (n--) {
			*(char *)dst = *(char *)src;
			dst = (char *)dst + 1;
			src = (char *)src + 1;
		}
	}else{
		dst = (char *)dst + n - 1;
		src = (char *)src + n - 1;
		while (n--){
			*(char *)dst = *(char *)src;
			dst = (char *)dst - 1;
			src = (char *)src - 1;
		}
	}
	return(ret);
}

void *memcpy(void *dst, const void *src, size_t n) {
	void * ret = dst;
	while (n--) {
		*(char *)dst = *(char *)src;
		dst = (char *)dst + 1;
		src = (char *)src + 1;
	}
	return ret;
}

int memcmp(const void *s1, const void *s2, size_t n) {
	const unsigned char *p = s1;
	const unsigned char *q = s2;
	n--;
	while(*p == *q && n-- > 0){
		p++;
		q++;
	}
	return *p - *q; 
}

#endif
