#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>
#include <kmalloc.h>
#include <cow.h>

/* 
    vmm设计包括两个部分：mm_struct (mm) 和 vma_struct (vma)
    mm是管理一组连续虚拟内存区域的内存管理器，这些区域具有相同的PDT。vma是一个连续的虚拟内存区域。
    在mm中有一个线性链表和一个红黑树链表来管理vma。
---------------
    mm相关函数：
     全局函数
         struct mm_struct * mm_create(void)
         void mm_destroy(struct mm_struct *mm)
         int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
    vma相关函数：
     全局函数
         struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
         void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
         struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
     局部函数
         inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
     检查正确性函数
         void check_vmm(void);
         void check_vma_struct(void);
         void check_pgfault(void);
*/

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create - 分配一个mm_struct并初始化它
struct mm_struct *
mm_create(void) {
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

        if (mm != NULL) {
                list_init(&(mm->mmap_list)); // 初始化mmap_list链表
                mm->mmap_cache = NULL;
                mm->pgdir = NULL;
                mm->map_count = 0;

                if (swap_init_ok) swap_init_mm(mm); // 如果swap初始化成功，则初始化mm的swap相关字段
                else mm->sm_priv = NULL;
                
                set_mm_count(mm, 0); // 设置mm的引用计数为0
                lock_init(&(mm->mm_lock)); // 初始化mm的锁
        }    
        return mm;
}

// vma_create - 分配一个vma_struct并初始化它 (地址范围: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
        struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

        if (vma != NULL) {
                vma->vm_start = vm_start;
                vma->vm_end = vm_end;
                vma->vm_flags = vm_flags;
        }
        return vma;
}


// find_vma - 查找一个vma (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
        struct vma_struct *vma = NULL;
        if (mm != NULL) {
                vma = mm->mmap_cache;
                if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                                bool found = 0;
                                list_entry_t *list = &(mm->mmap_list), *le = list;
                                while ((le = list_next(le)) != list) {
                                        vma = le2vma(le, list_link);
                                        if (vma->vm_start<=addr && addr < vma->vm_end) {
                                                found = 1;
                                                break;
                                        }
                                }
                                if (!found) {
                                        vma = NULL;
                                }
                }
                if (vma != NULL) {
                        mm->mmap_cache = vma; // 更新mmap_cache
                }
        }
        return vma;
}


// check_vma_overlap - 检查vma1是否与vma2重叠
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
        assert(prev->vm_start < prev->vm_end);
        assert(prev->vm_end <= next->vm_start);
        assert(next->vm_start < next->vm_end);
}


// insert_vma_struct - 将vma插入到mm的链表中
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
        assert(vma->vm_start < vma->vm_end);
        list_entry_t *list = &(mm->mmap_list);
        list_entry_t *le_prev = list, *le_next;

                list_entry_t *le = list;
                while ((le = list_next(le)) != list) {
                        struct vma_struct *mmap_prev = le2vma(le, list_link);
                        if (mmap_prev->vm_start > vma->vm_start) {
                                break;
                        }
                        le_prev = le;
                }

        le_next = list_next(le_prev);

        /* 检查重叠 */
        if (le_prev != list) {
                check_vma_overlap(le2vma(le_prev, list_link), vma);
        }
        if (le_next != list) {
                check_vma_overlap(vma, le2vma(le_next, list_link));
        }

        vma->vm_mm = mm;
        list_add_after(le_prev, &(vma->list_link)); // 将vma插入到链表中

        mm->map_count ++;
}

// mm_destroy - 释放mm和mm内部的字段
void
mm_destroy(struct mm_struct *mm) {
        assert(mm_count(mm) == 0);

        list_entry_t *list = &(mm->mmap_list), *le;
        while ((le = list_next(list)) != list) {
                list_del(le);
                kfree(le2vma(le, list_link));  // 释放vma        
        }
        kfree(mm); // 释放mm
        mm=NULL;
}

// mm_map - 将地址范围[start, end)映射到mm中
int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
             struct vma_struct **vma_store) {
        uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
        if (!USER_ACCESS(start, end)) {
                return -E_INVAL;
        }

        assert(mm != NULL);

        int ret = -E_INVAL;

        struct vma_struct *vma;
        if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
                goto out;
        }
        ret = -E_NO_MEM;

        if ((vma = vma_create(start, end, vm_flags)) == NULL) {
                goto out;
        }
        insert_vma_struct(mm, vma);
        if (vma_store != NULL) {
                *vma_store = vma;
        }
        ret = 0;

out:
        return ret;
}


/**
 * dup_mmap - 复制内存映射区域
 * @to: 目标 mm_struct 结构体指针
 * @from: 源 mm_struct 结构体指针
 *
 * 该函数用于将源 mm_struct 结构体中的内存映射区域复制到目标 mm_struct 结构体中。
 * 它会遍历源 mm_struct 的 mmap_list 列表，并为每个 vma_struct 创建一个新的 vma_struct，
 * 然后将其插入到目标 mm_struct 的 mmap_list 列表中。
 * 如果在复制过程中出现内存分配失败或页面复制失败的情况，函数将返回 -E_NO_MEM 错误码。
 *
 * 返回值:
 * 成功时返回 0，失败时返回 -E_NO_MEM。
 */
int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list) {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);

        bool share = 1;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
            return -E_NO_MEM;
        }
    }
    return 0;
}

void
exit_mmap(struct mm_struct *mm) {
    assert(mm != NULL && mm_count(mm) == 0); // 确保mm不为空且引用计数为0
    pde_t *pgdir = mm->pgdir; // 获取页目录表指针
    list_entry_t *list = &(mm->mmap_list), *le = list; // 获取mm的mmap_list链表
    while ((le = list_next(le)) != list) { // 遍历链表
        struct vma_struct *vma = le2vma(le, list_link); // 获取vma结构体
        unmap_range(pgdir, vma->vm_start, vma->vm_end); // 取消映射vma的地址范围
    }
    while ((le = list_next(le)) != list) { // 再次遍历链表
        struct vma_struct *vma = le2vma(le, list_link); // 获取vma结构体
        exit_range(pgdir, vma->vm_start, vma->vm_end); // 释放vma的地址范围
    }
}

bool
copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable) {
    if (!user_mem_check(mm, (uintptr_t)src, len, writable)) { // 检查用户内存是否可访问
        return 0; // 如果不可访问，返回0
    }
    memcpy(dst, src, len); // 将数据从用户空间复制到内核空间
    return 1; // 返回1表示成功
}

bool
copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len) {
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1)) { // 检查用户内存是否可写
        return 0; // 如果不可写，返回0
    }
    memcpy(dst, src, len); // 将数据从内核空间复制到用户空间
    return 1; // 返回1表示成功
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
    check_vmm(); // 调用check_vmm函数检查虚拟内存管理的正确性
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    // size_t nr_free_pages_store = nr_free_pages(); // 存储当前空闲页的数量
    
    check_vma_struct(); // 调用check_vma_struct函数检查vma结构的正确性
    check_pgfault(); // 调用check_pgfault函数检查页错误处理的正确性

    cprintf("check_vmm() succeeded.\n"); // 打印检查成功的信息
}

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i ++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i+1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i+2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i+3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i+4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
    }

    for (i =4; i>=0; i--) {
        struct vma_struct *vma_below_5= find_vma(mm,i);
        if (vma_below_5 != NULL ) {
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    assert(pgdir[0] == 0);

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
        sum -= *(char *)(addr + i);
    }

    assert(sum == 0);

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    pgdir[0] = 0;
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
    check_mm_struct = NULL;

    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_pgfault() succeeded!\n");
}
//page fault number
volatile unsigned int pgfault_num=0;

/* do_pgfault - interrupt handler to process the page fault execption
 * @mm         : the control struct for a set of vma using the same PDT
 * @error_code : the error code recorded in trapframe->tf_err which is setted by x86 hardware
 * @addr       : the addr which causes a memory access exception, (the contents of the CR2 register)
 *
 * CALL GRAPH: trap--> trap_dispatch-->pgfault_handler-->do_pgfault
 * The processor provides ucore's do_pgfault function with two items of information to aid in diagnosing
 * the exception and recovering from it.
 *   (1) The contents of the CR2 register. The processor loads the CR2 register with the
 *       32-bit linear address that generated the exception. The do_pgfault fun can
 *       use this address to locate the corresponding page directory and page-table
 *       entries.
 *   (2) An error code on the kernel stack. The error code for a page fault has a format different from
 *       that for other exceptions. The error code tells the exception handler three things:
 *         -- The P flag   (bit 0) indicates whether the exception was due to a not-present page (0)
 *            or to either an access rights violation or the use of a reserved bit (1).
 *         -- The W/R flag (bit 1) indicates whether the memory access that caused the exception
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL; // 初始化返回值为无效错误
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr); // 查找包含addr的vma

    pgfault_num++; // 页错误计数器加1
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) { // 如果找不到vma或者addr不在vma范围内
        cprintf("not valid addr %x, and  can not find it in vma\n", addr); // 打印错误信息
        goto failed; // 跳转到失败处理
    }

    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U; // 初始化页表项权限为用户态
    if (vma->vm_flags & VM_WRITE) { // 如果vma可写
        perm |= READ_WRITE; // 增加写权限
    }
    addr = ROUNDDOWN(addr, PGSIZE); // 将addr向下取整到页边界

    ret = -E_NO_MEM; // 初始化返回值为内存不足错误

    pte_t *ptep=NULL; // 页表项指针初始化为空
    
    // 判断页表项权限，如果有效但是不可写，跳转到COW
    if ((ptep = get_pte(mm->pgdir, addr, 0)) != NULL) {
        if((*ptep & PTE_V) & ~(*ptep & PTE_W)) {
            return cow_pgfault(mm, error_code, addr);
        }
    }


    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) { // 尝试获取页表项，如果页表不存在则创建
        cprintf("get_pte in do_pgfault failed\n"); // 打印错误信息
        goto failed; // 跳转到失败处理
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 如果物理地址不存在，则分配一个页面并映射物理地址和逻辑地址
            cprintf("pgdir_alloc_page in do_pgfault failed\n"); // 打印错误信息
            goto failed; // 跳转到失败处理
        }
    } else {
        /*LAB3 EXERCISE 3: YOUR CODE
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) { // 如果交换初始化成功
            struct Page *page = NULL; // 初始化页面指针为空
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            // cprintf("do_pgfault called!!!\n");
            if((ret = swap_in(mm,addr,&page)) != 0) { // 根据mm和addr，从磁盘加载正确的页面内容到内存
                goto failed; // 跳转到失败处理
            }
            page_insert(mm->pgdir,page,addr,perm); // 建立物理地址和逻辑地址的映射
            swap_map_swappable(mm,addr,page,1); // 设置页面可交换
            page->pra_vaddr = addr; // 设置页面的虚拟地址
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep); // 打印错误信息
            goto failed; // 跳转到失败处理
        }
   }
   ret = 0; // 设置返回值为0，表示成功
failed:
    return ret; // 返回结果
}

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
    if (mm != NULL) { // 如果mm不为空
        if (!USER_ACCESS(addr, addr + len)) { // 检查地址范围是否在用户空间
            return 0; // 如果不在用户空间，返回0
        }
        struct vma_struct *vma; // 定义vma结构体指针
        uintptr_t start = addr, end = addr + len; // 定义起始地址和结束地址
        while (start < end) { // 遍历地址范围
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) { // 查找包含start地址的vma，如果找不到或者start小于vma的起始地址
                return 0; // 返回0
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) { // 检查vma的权限，如果写操作但vma不可写，或者读操作但vma不可读
                return 0; // 返回0
            }
            if (write && (vma->vm_flags & VM_STACK)) { // 如果是写操作并且vma是栈
                if (start < vma->vm_start + PGSIZE) { // 检查栈的起始地址和大小
                    return 0; // 返回0
                }
            }
            start = vma->vm_end; // 更新start为vma的结束地址
        }
        return 1; // 返回1表示成功
    }
    return KERN_ACCESS(addr, addr + len); // 如果mm为空，检查地址范围是否在内核空间
}