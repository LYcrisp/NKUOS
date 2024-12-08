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

/* 
    vmm设计包括两个部分：mm_struct (mm) 和 vma_struct (vma)
    mm是用于管理一组具有相同PDT的连续虚拟内存区域的内存管理器。vma是一个连续的虚拟内存区域。
    mm中有一个线性链表和一个红黑树链表用于vma。
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
     本地函数
         inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
     检查正确性函数
         void check_vmm(void);
         void check_vma_struct(void);
         void check_pgfault(void);
*/

// szx函数：print_vma和print_mm
void print_vma(char *name, struct vma_struct *vma){
        cprintf("-- %s print_vma --\n", name);
        cprintf("   mm_struct: %p\n",vma->vm_mm);
        cprintf("   vm_start,vm_end: %x,%x\n",vma->vm_start,vma->vm_end);
        cprintf("   vm_flags: %x\n",vma->vm_flags);
        cprintf("   list_entry_t: %p\n",&vma->list_link);
}

void print_mm(char *name, struct mm_struct *mm){
        cprintf("-- %s print_mm --\n",name);
        cprintf("   mmap_list: %p\n",&mm->mmap_list);
        cprintf("   map_count: %d\n",mm->map_count);
        list_entry_t *list = &mm->mmap_list;
        for(int i=0;i<mm->map_count;i++){
                list = list_next(list);
                print_vma(name, le2vma(list,list_link));
        }
}

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create - 分配一个mm_struct并初始化它
struct mm_struct *
mm_create(void) {
        struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

        if (mm != NULL) {
                list_init(&(mm->mmap_list));
                mm->mmap_cache = NULL;
                mm->pgdir = NULL;
                mm->map_count = 0;

                if (swap_init_ok) swap_init_mm(mm);
                else mm->sm_priv = NULL;
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
                        mm->mmap_cache = vma;
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

// insert_vma_struct - 在mm的链表中插入vma
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
        list_add_after(le_prev, &(vma->list_link));

        mm->map_count ++;
}

// mm_destroy - 释放mm和mm的内部字段
void
mm_destroy(struct mm_struct *mm) {

        list_entry_t *list = &(mm->mmap_list), *le;
        while ((le = list_next(list)) != list) {
                list_del(le);
                kfree(le2vma(le, list_link));  //释放vma        
        }
        kfree(mm); //释放mm
        mm=NULL;
}

// vmm_init - 初始化虚拟内存管理
//          - 现在只调用check_vmm来检查vmm的正确性
void
vmm_init(void) {
        check_vmm();
}

// check_vmm - 检查vmm的正确性
static void
check_vmm(void) {
        check_vma_struct();
        check_pgfault();

        cprintf("check_vmm() succeeded.\n");
}

// check_vma_struct - 检查vma_struct的正确性
static void
check_vma_struct(void) {
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

// check_pgfault - 检查页错误处理程序的正确性
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

// 页错误数量
volatile unsigned int pgfault_num=0;

/* do_pgfault - 中断处理程序，用于处理页错误异常
 * @mm         : 使用相同PDT的一组vma的控制结构
 * @error_code : 在trapframe->tf_err中记录的错误代码，由x86硬件设置
 * @addr       : 导致内存访问异常的地址（CR2寄存器的内容）
 *
 * 调用图：trap--> trap_dispatch-->pgfault_handler-->do_pgfault
 * 处理器为ucore的do_pgfault函数提供了两项信息，以帮助诊断异常并从中恢复。
 *   (1) CR2寄存器的内容。处理器将CR2寄存器加载为生成异常的32位线性地址。do_pgfault函数可以使用此地址来定位相应的页目录和页表条目。
 *   (2) 内核堆栈上的错误代码。页错误的错误代码格式不同于其他异常的错误代码。错误代码告诉异常处理程序三件事：
 *         -- P标志（位0）指示异常是由于不存在的页面（0）还是由于访问权限违规或使用保留位（1）。
 *         -- W/R标志（位1）指示导致异常的内存访问是读取（0）还是写入（1）。
 *         -- U/S标志（位2）指示处理器在发生异常时是处于用户模式（1）还是监督模式（0）。
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
        int ret = -E_INVAL;
        // 尝试查找包含addr的vma
        struct vma_struct *vma = find_vma(mm, addr);

        pgfault_num++;
        // 如果addr在mm的vma范围内？
        if (vma == NULL || vma->vm_start > addr) {
                cprintf("not valid addr %x, and  can not find it in vma\n", addr);
                goto failed;
        }

        /* 如果（写入已存在的地址）或
         *    （写入不存在的地址且地址可写）或
         *    （读取不存在的地址且地址可读）
         * 则继续处理
         */
        uint32_t perm = PTE_U;
        if (vma->vm_flags & VM_WRITE) {
                perm |= READ_WRITE;
        }
        addr = ROUNDDOWN(addr, PGSIZE);

        ret = -E_NO_MEM;

        pte_t *ptep=NULL;
    
        // 尝试查找一个pte，如果pte的PT（页表）不存在，则创建一个PT。
        // （注意第三个参数'1'）
        if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
                cprintf("get_pte in do_pgfault failed\n");
                goto failed;
        }
        if (*ptep == 0) { // 如果物理地址不存在，则分配一个页面并将物理地址与逻辑地址映射
                if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
                        cprintf("pgdir_alloc_page in do_pgfault failed\n");
                        goto failed;
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
                if (swap_init_ok) {
                        struct Page *page = NULL;
                        // 根据mm和addr，尝试将正确的磁盘页面内容加载到page管理的内存中
                        swap_in(mm, addr, &page); 
                        // 根据mm、addr和page，设置物理地址与逻辑地址的映射
                        page_insert(mm->pgdir, page, addr, perm); // 更新页表，插入新的页表项

                        // 使页面可交换
                        swap_map_swappable(mm, addr, page, 1);

                        page->pra_vaddr = addr;
                } else {
                        cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
                        goto failed;
                }
     }

     ret = 0;
failed:
        return ret;
}
