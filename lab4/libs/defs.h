#ifndef __LIBS_DEFS_H__ // 防止重复包含头文件
#define __LIBS_DEFS_H__

#ifndef NULL // 如果没有定义NULL
#define NULL ((void *)0) // 定义NULL为(void *)0
#endif

#define __always_inline inline __attribute__((always_inline)) // 定义__always_inline为总是内联
#define __noinline __attribute__((noinline)) // 定义__noinline为不内联
#define __noreturn __attribute__((noreturn)) // 定义__noreturn为不返回

/* Represents true-or-false values */ // 表示布尔值
typedef int bool; // 定义bool为int类型

/* Explicitly-sized versions of integer types */ // 明确大小的整数类型
typedef char int8_t; // 定义int8_t为char类型
typedef unsigned char uint8_t; // 定义uint8_t为unsigned char类型
typedef short int16_t; // 定义int16_t为short类型
typedef unsigned short uint16_t; // 定义uint16_t为unsigned short类型
typedef int int32_t; // 定义int32_t为int类型
typedef unsigned int uint32_t; // 定义uint32_t为unsigned int类型
typedef long long int64_t; // 定义int64_t为long long类型
typedef unsigned long long uint64_t; // 定义uint64_t为unsigned long long类型
#if __riscv_xlen == 64 // 如果__riscv_xlen为64
  typedef uint64_t uint_t; // 定义uint_t为uint64_t类型
  typedef int64_t sint_t; // 定义sint_t为int64_t类型
#elif __riscv_xlen == 32 // 如果__riscv_xlen为32
  typedef uint32_t uint_t; // 定义uint_t为uint32_t类型
  typedef int32_t sint_t; // 定义sint_t为int32_t类型
#endif

/* *
 * Pointers and addresses are 32 bits long.
 * We use pointer types to represent addresses,
 * uintptr_t to represent the numerical values of addresses.
 * */ // 指针和地址是32位长。我们使用指针类型表示地址，使用uintptr_t表示地址的数值。
typedef sint_t intptr_t; // 定义intptr_t为sint_t类型
typedef uint_t uintptr_t; // 定义uintptr_t为uint_t类型

/* size_t is used for memory object sizes */ // size_t用于表示内存对象的大小
typedef uintptr_t size_t; // 定义size_t为uintptr_t类型

/* used for page numbers */ // 用于页号
typedef size_t ppn_t; // 定义ppn_t为size_t类型

/* *
 * Rounding operations (efficient when n is a power of 2)
 * Round down to the nearest multiple of n
 * */ // 四舍五入操作（当n是2的幂时效率高），向下舍入到最接近的n的倍数
#define ROUNDDOWN(a, n) ({                                          \
            size_t __a = (size_t)(a);                               \
            (typeof(a))(__a - __a % (n));                           \
        }) // 定义ROUNDDOWN宏，向下舍入到最接近的n的倍数

/* Round up to the nearest multiple of n */ // 向上舍入到最接近的n的倍数
#define ROUNDUP(a, n) ({                                            \
            size_t __n = (size_t)(n);                               \
            (typeof(a))(ROUNDDOWN((size_t)(a) + __n - 1, __n));     \
        }) // 定义ROUNDUP宏，向上舍入到最接近的n的倍数

/* Return the offset of 'member' relative to the beginning of a struct type */ // 返回'member'相对于结构体类型起始位置的偏移量
#define offsetof(type, member)                                      \
    ((size_t)(&((type *)0)->member)) // 定义offsetof宏，返回'member'相对于结构体类型起始位置的偏移量

/* *
 * to_struct - get the struct from a ptr
 * @ptr:    a struct pointer of member
 * @type:   the type of the struct this is embedded in
 * @member: the name of the member within the struct
 * */ // to_struct - 从指针获取结构体
#define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member))) // 定义to_struct宏，从指针获取结构体

#endif /* !__LIBS_DEFS_H__ */ // 结束防止重复包含头文件的条件编译
