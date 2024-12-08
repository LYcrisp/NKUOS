#ifndef __KERN_MM_VMM_H__                 // 防止重复包含头文件的宏定义开始
#define __KERN_MM_VMM_H__

#include <defs.h>                         // 包含基本数据类型定义
#include <list.h>                         // 包含链表操作相关定义
#include <memlayout.h>                    // 包含内存布局相关定义
#include <sync.h>                         // 包含同步机制相关定义

// 预先声明 mm_struct 结构体
struct mm_struct;

// 虚拟连续内存区域（vma），地址范围为 [vm_start, vm_end)
// 地址属于某个 vma 意味着 vma.vm_start <= addr < vma.vm_end
struct vma_struct {
    struct mm_struct *vm_mm;              // 指向该 vma 所属的 mm_struct，表示使用相同页目录表的 vma 集合
    uintptr_t vm_start;                   // vma 的起始地址
    uintptr_t vm_end;                     // vma 的结束地址，不包括 vm_end
    uint32_t vm_flags;                    // vma 的标志位，表示权限等信息
    list_entry_t list_link;               // 链表链接，用于按起始地址排序的线性链表
};

#define le2vma(le, member)                \
    to_struct((le), struct vma_struct, member)  // 由链表元素指针获取 vma_struct 结构体指针

#define VM_READ                 0x00000001  // 可读权限标志
#define VM_WRITE                0x00000002  // 可写权限标志
#define VM_EXEC                 0x00000004  // 可执行权限标志

// 使用相同页目录表的一组 vma 的控制结构
struct mm_struct {
    list_entry_t mmap_list;                // vma 的链表，按起始地址排序
    struct vma_struct *mmap_cache;         // 指向最近使用的 vma，用于加速查找
    pde_t *pgdir;                          // 指向页目录表的指针
    int map_count;                         // vma 的数量
    void *sm_priv;                         // 交换管理器的私有数据
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);  // 查找包含指定地址的 vma
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags);  // 创建新的 vma
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);  // 将 vma 插入到 mm 的链表中

struct mm_struct *mm_create(void);          // 创建新的 mm_struct
void mm_destroy(struct mm_struct *mm);      // 销毁 mm_struct，释放资源

void vmm_init(void);                        // 初始化虚拟内存管理模块

int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr);  // 处理页错误异常

extern volatile unsigned int pgfault_num;   // 页错误计数器，记录页错误次数
extern struct mm_struct *check_mm_struct;   // 测试用的 mm_struct 指针

#endif /* !__KERN_MM_VMM_H__ */            // 防止重复包含头文件的宏定义结束
