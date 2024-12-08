#ifndef __KERN_MM_MMU_H__ // 防止重复包含头文件
#define __KERN_MM_MMU_H__ // 定义头文件标识符

#ifndef __ASSEMBLER__ // 如果不是汇编代码
#include <defs.h> // 包含defs.h头文件
#endif /* !__ASSEMBLER__ */ // 结束条件编译

// A linear address 'la' has a three-part structure as follows: // 线性地址'la'有三部分结构如下:
// +--------10------+-------10-------+---------12----------+ // 地址结构图
// | Page Directory |   Page Table   | Offset within Page  | // 页目录索引、页表索引、页内偏移
// |      Index     |     Index      |                     | // 页目录索引、页表索引、页内偏移
// +----------------+----------------+---------------------+ // 地址结构图结束
//  \--- PDX(la) --/ \--- PTX(la) --/ \---- PGOFF(la) ----/ // 页目录索引、页表索引、页内偏移宏定义
//  \----------- PPN(la) -----------/ // 页号宏定义

// The PDX, PTX, PGOFF, and PPN macros decompose linear addresses as shown. // PDX、PTX、PGOFF和PPN宏分解线性地址
// To construct a linear address la from PDX(la), PTX(la), and PGOFF(la), // 从PDX(la)、PTX(la)和PGOFF(la)构造线性地址la
// use PGADDR(PDX(la), PTX(la), PGOFF(la)). // 使用PGADDR(PDX(la), PTX(la), PGOFF(la))

// RISC-V uses 32-bit virtual address to access 34-bit physical address! // RISC-V使用32位虚拟地址访问34位物理地址
// Sv32 page table entry: // Sv32页表项结构
// +---------12----------+--------10-------+---2----+-------8-------+ // 页表项结构图
// |       PPN[1]        |      PPN[0]     |Reserved|D|A|G|U|X|W|R|V| // 页号、保留位和标志位
// +---------12----------+-----------------+--------+---------------+ // 页表项结构图结束

// page directory index // 页目录索引
#define PDX1(la) ((((uintptr_t)(la)) >> PDX1SHIFT) & 0x1FF) // 获取页目录索引1
#define PDX0(la) ((((uintptr_t)(la)) >> PDX0SHIFT) & 0x1FF) // 获取页目录索引0

// page table index // 页表索引
#define PTX(la) ((((uintptr_t)(la)) >> PTXSHIFT) & 0x1FF) // 获取页表索引

// page number field of address // 地址的页号字段
#define PPN(la) (((uintptr_t)(la)) >> PTXSHIFT) // 获取页号

// offset in page // 页内偏移
#define PGOFF(la) (((uintptr_t)(la)) & 0xFFF) // 获取页内偏移

// construct linear address from indexes and offset // 从索引和偏移构造线性地址
#define PGADDR(d1, d0, t, o) ((uintptr_t)((d1) << PDX1SHIFT |(d0) << PDX0SHIFT | (t) << PTXSHIFT | (o))) // 构造线性地址

// address in page table or page directory entry // 页表或页目录项中的地址
#define PTE_ADDR(pte)   (((uintptr_t)(pte) & ~0x3FF) << (PTXSHIFT - PTE_PPN_SHIFT)) // 获取页表项地址
#define PDE_ADDR(pde)   PTE_ADDR(pde) // 获取页目录项地址

/* page directory and page table constants */ // 页目录和页表常量
#define NPDEENTRY       512                    // page directory entries per page directory // 每个页目录的页目录项数
#define NPTEENTRY       512                    // page table entries per page table // 每个页表的页表项数

#define PGSIZE          4096                    // bytes mapped by a page // 每页映射的字节数
#define PGSHIFT         12                      // log2(PGSIZE) // PGSIZE的对数
#define PTSIZE          (PGSIZE * NPTEENTRY)    // bytes mapped by a page directory entry // 每个页目录项映射的字节数
#define PTSHIFT         21                      // log2(PTSIZE) // PTSIZE的对数

#define PTXSHIFT        12                      // offset of PTX in a linear address // 线性地址中PTX的偏移
#define PDX0SHIFT       21                      // offset of PDX in a linear address // 线性地址中PDX的偏移
#define PDX1SHIFT		30                      // offset of PDX1 in a linear address // 线性地址中PDX1的偏移
#define PTE_PPN_SHIFT   10                      // offset of PPN in a physical address // 物理地址中PPN的偏移

// page table entry (PTE) fields // 页表项字段
#define PTE_V     0x001 // Valid // 有效
#define PTE_R     0x002 // Read // 读
#define PTE_W     0x004 // Write // 写
#define PTE_X     0x008 // Execute // 执行
#define PTE_U     0x010 // User // 用户
#define PTE_G     0x020 // Global // 全局
#define PTE_A     0x040 // Accessed // 访问
#define PTE_D     0x080 // Dirty // 脏
#define PTE_SOFT  0x300 // Reserved for Software // 软件保留

#define PAGE_TABLE_DIR (PTE_V) // 页表目录项
#define READ_ONLY (PTE_R | PTE_V) // 只读
#define READ_WRITE (PTE_R | PTE_W | PTE_V) // 读写
#define EXEC_ONLY (PTE_X | PTE_V) // 只执行
#define READ_EXEC (PTE_R | PTE_X | PTE_V) // 读和执行
#define READ_WRITE_EXEC (PTE_R | PTE_W | PTE_X | PTE_V) // 读写和执行

#define PTE_USER (PTE_R | PTE_W | PTE_X | PTE_U | PTE_V) // 用户页表项

#endif /* !__KERN_MM_MMU_H__ */ // 结束头文件防止重复包含
