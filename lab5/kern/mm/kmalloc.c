#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <assert.h>
#include <kmalloc.h>
#include <sync.h>
#include <pmm.h>
#include <stdio.h>

/*
 * SLOB 分配器：简单的块列表
 *
 * Matt Mackall <mpm@selenic.com> 12/30/03
 *
 * SLOB 的工作原理：
 *
 * SLOB 的核心是一个传统的 K&R 风格的堆分配器，支持返回对齐的对象。
 * 在 x86 上，这个分配器的粒度是 8 字节，尽管可能可以将其减少到 4 字节，如果认为值得的话。
 * slob 堆是一个从 __get_free_page 获取的页面的单链表，按需增长，堆的分配目前是首次适配。
 *
 * 在此之上实现了 kmalloc/kfree。kmalloc 返回的块是 8 字节对齐的，并且前面有一个 8 字节的头。
 * 如果 kmalloc 被要求分配 PAGE_SIZE 或更大的对象，它会直接调用 __get_free_pages，以便返回页面对齐的块，
 * 并保持这些页面及其顺序的链表。这些对象在 kfree() 中通过其页面对齐来检测。
 *
 * SLAB 在 SLOB 之上通过简单地为每个 SLAB 分配调用构造函数和析构函数来模拟。
 * 除非设置了 SLAB_MUST_HWCACHE_ALIGN 标志，否则对象以 8 字节对齐返回，在这种情况下，
 * 低级分配器将碎片化块以创建适当的对齐。同样，页面大小或更大的对象通过调用 __get_free_pages 分配。
 * 由于 SLAB 对象知道它们的大小，因此不需要单独的大小记录，并且基本上没有分配空间开销。
 */


// 一些辅助函数
#define spin_lock_irqsave(l, f) local_intr_save(f) // 保存中断状态并加锁
#define spin_unlock_irqrestore(l, f) local_intr_restore(f) // 恢复中断状态并解锁
typedef unsigned int gfp_t; // 定义 gfp_t 类型
#ifndef PAGE_SIZE
#define PAGE_SIZE PGSIZE // 定义页面大小
#endif

#ifndef L1_CACHE_BYTES
#define L1_CACHE_BYTES 64 // 定义一级缓存字节数
#endif

#ifndef ALIGN
#define ALIGN(addr,size)   (((addr)+(size)-1)&(~((size)-1))) // 对齐宏
#endif


struct slob_block {
	int units; // 单位数
	struct slob_block *next; // 下一个块指针
};
typedef struct slob_block slob_t; // 定义 slob_t 类型

#define SLOB_UNIT sizeof(slob_t) // 定义 SLOB 单位大小
#define SLOB_UNITS(size) (((size) + SLOB_UNIT - 1)/SLOB_UNIT) // 计算 SLOB 单位数
#define SLOB_ALIGN L1_CACHE_BYTES // 定义 SLOB 对齐大小

struct bigblock {
	int order; // 顺序
	void *pages; // 页面指针
	struct bigblock *next; // 下一个大块指针
};
typedef struct bigblock bigblock_t; // 定义 bigblock_t 类型

static slob_t arena = { .next = &arena, .units = 1 }; // 初始化 arena
static slob_t *slobfree = &arena; // 初始化 slobfree
static bigblock_t *bigblocks; // 初始化 bigblocks


static void* __slob_get_free_pages(gfp_t gfp, int order)
{
  struct Page * page = alloc_pages(1 << order); // 分配页面
  if(!page) // 如果页面分配失败
	return NULL; // 返回 NULL
  return page2kva(page); // 返回页面的虚拟地址
}

#define __slob_get_free_page(gfp) __slob_get_free_pages(gfp, 0) // 获取单个页面

static inline void __slob_free_pages(unsigned long kva, int order)
{
  free_pages(kva2page(kva), 1 << order); // 释放页面
}

static void slob_free(void *b, int size); // 声明 slob_free 函数

static void *slob_alloc(size_t size, gfp_t gfp, int align)
{
  assert( (size + SLOB_UNIT) < PAGE_SIZE ); // 断言大小加上 SLOB 单位小于页面大小

	slob_t *prev, *cur, *aligned = 0; // 定义指针
	int delta = 0, units = SLOB_UNITS(size); // 计算单位数
	unsigned long flags; // 定义标志

	spin_lock_irqsave(&slob_lock, flags); // 加锁并保存中断状态
	prev = slobfree; // 初始化 prev
	for (cur = prev->next; ; prev = cur, cur = cur->next) { // 遍历 slobfree 链表
		if (align) { // 如果需要对齐
			aligned = (slob_t *)ALIGN((unsigned long)cur, align); // 计算对齐地址
			delta = aligned - cur; // 计算偏移量
		}
		if (cur->units >= units + delta) { /* 是否有足够空间？ */
			if (delta) { /* 是否需要碎片化头部以对齐？ */
				aligned->units = cur->units - delta; // 更新对齐块的单位数
				aligned->next = cur->next; // 更新对齐块的下一个指针
				cur->next = aligned; // 更新当前块的下一个指针
				cur->units = delta; // 更新当前块的单位数
				prev = cur; // 更新 prev
				cur = aligned; // 更新 cur
			}

			if (cur->units == units) /* 是否正好适配？ */
				prev->next = cur->next; /* 取消链接 */
			else { /* 碎片化 */
				prev->next = cur + units; // 更新 prev 的下一个指针
				prev->next->units = cur->units - units; // 更新新块的单位数
				prev->next->next = cur->next; // 更新新块的下一个指针
				cur->units = units; // 更新当前块的单位数
			}

			slobfree = prev; // 更新 slobfree
			spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态
			return cur; // 返回当前块
		}
		if (cur == slobfree) { // 如果遍历完链表
			spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态

			if (size == PAGE_SIZE) /* 是否尝试缩小 arena？ */
				return 0; // 返回 0

			cur = (slob_t *)__slob_get_free_page(gfp); // 获取新的页面
			if (!cur) // 如果获取失败
				return 0; // 返回 0

			slob_free(cur, PAGE_SIZE); // 释放页面
			spin_lock_irqsave(&slob_lock, flags); // 加锁并保存中断状态
			cur = slobfree; // 更新 cur
		}
	}
}

static void slob_free(void *block, int size) // 定义 slob_free 函数，释放内存块
{
	slob_t *cur, *b = (slob_t *)block; // 定义指针 cur 和 b，将 block 转换为 slob_t 类型
	unsigned long flags; // 定义标志

	if (!block) // 如果 block 为空
		return; // 返回

	if (size) // 如果 size 不为 0
		b->units = SLOB_UNITS(size); // 计算并设置 b 的单位数

	/* 查找重新插入点 */
	spin_lock_irqsave(&slob_lock, flags); // 加锁并保存中断状态
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next) // 遍历 slobfree 链表，查找插入点
		if (cur >= cur->next && (b > cur || b < cur->next)) // 如果 cur 大于等于 cur->next 且 b 大于 cur 或 b 小于 cur->next
			break; // 跳出循环

	if (b + b->units == cur->next) { // 如果 b 的末尾与 cur->next 相连
		b->units += cur->next->units; // 合并单位数
		b->next = cur->next->next; // 更新 b 的下一个指针
	} else // 否则
		b->next = cur->next; // 更新 b 的下一个指针

	if (cur + cur->units == b) { // 如果 cur 的末尾与 b 相连
		cur->units += b->units; // 合并单位数
		cur->next = b->next; // 更新 cur 的下一个指针
	} else // 否则
		cur->next = b; // 更新 cur 的下一个指针

	slobfree = cur; // 更新 slobfree

	spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态
}

void slob_init(void) { // 定义 slob_init 函数，初始化 SLOB 分配器
  cprintf("use SLOB allocator\n"); // 打印使用 SLOB 分配器的信息
}

inline void kmalloc_init(void) { // 定义 kmalloc_init 函数，初始化 kmalloc
	slob_init(); // 调用 slob_init 函数
	cprintf("kmalloc_init() succeeded!\n"); // 打印 kmalloc 初始化成功的信息
}

size_t slob_allocated(void) { // 定义 slob_allocated 函数，返回已分配的内存大小
  return 0; // 返回 0
}

size_t kallocated(void) { // 定义 kallocated 函数，返回已分配的内存大小
   return slob_allocated(); // 调用 slob_allocated 函数并返回结果
}

static int find_order(int size) // 定义 find_order 函数，查找合适的顺序
{
	int order = 0; // 初始化顺序为 0
	for ( ; size > 4096 ; size >>=1) // 当 size 大于 4096 时，右移一位
		order++; // 增加顺序
	return order; // 返回顺序
}

static void *__kmalloc(size_t size, gfp_t gfp) // 定义 __kmalloc 函数，分配内存
{
	slob_t *m; // 定义 slob_t 类型的指针 m
	bigblock_t *bb; // 定义 bigblock_t 类型的指针 bb
	unsigned long flags; // 定义标志

	if (size < PAGE_SIZE - SLOB_UNIT) { // 如果 size 小于页面大小减去 SLOB 单位大小
		m = slob_alloc(size + SLOB_UNIT, gfp, 0); // 调用 slob_alloc 分配内存
		return m ? (void *)(m + 1) : 0; // 如果分配成功，返回 m + 1，否则返回 0
	}

	bb = slob_alloc(sizeof(bigblock_t), gfp, 0); // 调用 slob_alloc 分配 bigblock_t 大小的内存
	if (!bb) // 如果分配失败
		return 0; // 返回 0

	bb->order = find_order(size); // 调用 find_order 函数查找合适的顺序
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order); // 调用 __slob_get_free_pages 分配页面

	if (bb->pages) { // 如果页面分配成功
		spin_lock_irqsave(&block_lock, flags); // 加锁并保存中断状态
		bb->next = bigblocks; // 将 bigblocks 赋值给 bb 的 next 指针
		bigblocks = bb; // 将 bb 赋值给 bigblocks
		spin_unlock_irqrestore(&block_lock, flags); // 解锁并恢复中断状态
		return bb->pages; // 返回分配的页面
	}

	slob_free(bb, sizeof(bigblock_t)); // 调用 slob_free 释放内存
	return 0; // 返回 0
}

void *
kmalloc(size_t size) // 定义 kmalloc 函数，分配内存
{
  return __kmalloc(size, 0); // 调用 __kmalloc 函数分配内存
}


void kfree(void *block) // 定义 kfree 函数，释放内存
{
	bigblock_t *bb, **last = &bigblocks; // 定义 bigblock_t 类型的指针 bb 和 last，将 bigblocks 的地址赋值给 last
	unsigned long flags; // 定义标志

	if (!block) // 如果 block 为空
		return; // 返回

	if (!((unsigned long)block & (PAGE_SIZE-1))) { // 如果 block 是页面对齐的
		/* 可能在大块列表中 */
		spin_lock_irqsave(&block_lock, flags); // 加锁并保存中断状态
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) { // 遍历 bigblocks 链表
			if (bb->pages == block) { // 如果找到匹配的页面
				*last = bb->next; // 更新 last 的 next 指针
				spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态
				__slob_free_pages((unsigned long)block, bb->order); // 调用 __slob_free_pages 释放页面
				slob_free(bb, sizeof(bigblock_t)); // 调用 slob_free 释放 bigblock_t 大小的内存
				return; // 返回
			}
		}
		spin_unlock_irqrestore(&block_lock, flags); // 解锁并恢复中断状态
	}

	slob_free((slob_t *)block - 1, 0); // 调用 slob_free 释放内存
	return; // 返回
}


unsigned int ksize(const void *block) // 定义 ksize 函数，返回内存块的大小
{
	bigblock_t *bb; // 定义 bigblock_t 类型的指针 bb
	unsigned long flags; // 定义标志

	if (!block) // 如果 block 为空
		return 0; // 返回 0

	if (!((unsigned long)block & (PAGE_SIZE-1))) { // 如果 block 是页面对齐的
		spin_lock_irqsave(&block_lock, flags); // 加锁并保存中断状态
		for (bb = bigblocks; bb; bb = bb->next) // 遍历 bigblocks 链表
			if (bb->pages == block) { // 如果找到匹配的页面
				spin_unlock_irqrestore(&slob_lock, flags); // 解锁并恢复中断状态
				return PAGE_SIZE << bb->order; // 返回页面大小乘以 2 的 bb->order 次方
			}
		spin_unlock_irqrestore(&block_lock, flags); // 解锁并恢复中断状态
	}

	return ((slob_t *)block - 1)->units * SLOB_UNIT; // 返回内存块的单位数乘以 SLOB 单位大小
}