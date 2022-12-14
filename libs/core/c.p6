@module_priority(-900_000)

// Externs are assumed to be C calling convention/mangling

pub alias size_t    = long
pub alias ptrdiff_t = long

pub struct FILE(void* _Placeholder)

// stdio.h
pub extern fn fopen(byte* filename, byte* mode return FILE*)
pub extern fn fclose(FILE* return int)
pub extern fn fflush(FILE* return int)
pub extern fn fputs(byte* str, FILE* stream return int)
pub extern fn fread(byte* ptr, long size, long count, FILE* stream return long)
pub extern fn fwrite(byte* ptr, long size, long count, FILE* stream return long)
pub extern fn getchar(return int)
pub extern fn putchar(int ch return int)
pub extern fn puts(byte* str return int)

// stdlib
pub extern fn _itoa(int value,byte* str,int base return byte*)
pub extern fn atoi(byte* str return int)
pub extern fn calloc(long numElements, long elementSize return void*)
pub extern fn exit(int status return void)
pub extern fn free(void* ptr return void)
pub extern fn malloc(long size return void*)
pub extern fn realloc(void* ptr, long size return void*)

pub extern fn __argc(return int)
pub extern fn __argv(return byte**)
pub extern fn __wargv(return short**)

// string.h
pub extern fn memchr(void* ptr, int value, long num return void*)
pub extern fn memcmp(void* ptr1,void* ptr2, long numBytes return int)
pub extern fn memcpy(void* destination, void* source, long num return void*)
pub extern fn memmove(void* dest, void* src, long numBytes return void*)
pub extern fn memset(void* ptr, int value, long num return void*)
pub extern fn strcmp(byte* str1, byte* str2 return byte*)
pub extern fn strlen(byte* str return long)
pub extern fn strstr(byte* str1, byte* str2 return byte*)

