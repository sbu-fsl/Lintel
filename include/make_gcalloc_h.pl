#!/usr/bin/perl -w

#
#  (c) Copyright 2005-2008, Hewlett-Packard Development Company, LP
#
#  See the file named COPYING for license details
#

use strict;
use File::Path;

die "Usage: $0 <output-pathname>" unless @ARGV == 1 && $ARGV[0] =~ m!/!;

my $dir = $ARGV[0];
$dir =~ s!/[^/]+$!!o;
mkpath($dir);

open(OUT, ">$ARGV[0]-new") or die "Can't write to $ARGV[0]-new: $!";
select(OUT);
header();
templates();
footer();
close(OUT);
rename("$ARGV[0]-new", $ARGV[0]) or die "can't rename $ARGV[0]-new to $ARGV[0]: $!";
exit(0);

sub header {
    print <<'END_OF_HEADER';
/*
   (c) Copyright 2005, Hewlett-Packard Development Company, LP

   See the file named COPYING for license details
*/

/*
    This file provides definitions for making GC stuff more easily used in C++.
    It is automatically generated by make_gcalloc_h.pl
*/

#ifndef __LINTEL_GC_ALLOC_H
#define __LINTEL_GC_ALLOC_H

#define WITH_LINTEL_GC_ALLOC 1

#include <memory>
#include <string>

#include <Lintel/AssertBoost.H>
extern "C" {
#include <gc/gc.h>
}

#ifndef __STL_NOTHROW
#define __STL_NOTHROW
#endif

// The GCallocator is the general purpose allocator

// The atomic allocator is for allocating objects which don't have
// pointers in them. The ignore off page allocator assumes that 
// there will be a pointer to the object somewhere within the first 
// 256 bytes of the object.

// There are 5 allocators here; three of them rebind
// to an allocator of the same type, which is not safe for use with
// the stl map, and probably not the stl list either.  The RebindGCAlloc 
// variants of the two atomic classes rebind to the GCAllocator, which is 
// probably safe for use with the stl map, but works poorly with the stl 
// string because it rebinds to a void * type to make the actual string 
// representation, defeating the purpose of using the allocator atomic.

template<class __T> class GCAtomicAllocatorRebindGCAlloc;
template<class __T> class GCAtomicIgnoreOffPageAllocatorRebindGCAlloc;

END_OF_HEADER
}

sub templates {
    write_template('GCAllocator','GC_malloc','GCAllocator');
    write_template('GCAtomicAllocator','GC_malloc_atomic','GCAtomicAllocator');
    write_template('GCAtomicAllocatorRebindGCAlloc','GC_malloc_atomic','GCAllocator');
    write_template('GCAtomicIgnoreOffPageAllocator','GC_malloc_atomic_ignore_off_page','GCAtomicIgnoreOffPageAllocator');
    write_template('GCAtomicIgnoreOffPageAllocatorRebindGCAlloc','GC_malloc_atomic_ignore_off_page','GCAllocator');
}

sub footer {
    print <<'END_OF_FOOTER';
#if (__GNUC__ >= 3) 
typedef std::basic_string<char, std::char_traits<char>, GCAtomicAllocator<char> > gcstring;
#else
typedef std::basic_string<char, std::string_char_traits<char>, GCAtomicAllocator<char> > gcstring;
#endif

static inline bool operator== (const std::string &lhs, const gcstring &rhs) 
{
  return lhs.size() == rhs.size() && memcmp(lhs.data(),rhs.data(),lhs.size()) == 0;
}

static inline bool operator== (const gcstring &lhs, const std::string &rhs) 
{
  return lhs.size() == rhs.size() && memcmp(lhs.data(),rhs.data(),lhs.size()) == 0;
}

#endif

END_OF_FOOTER
}

sub write_template {
    my($classname,$fnname,$rebindname) = @_;
    my $extrabits = '';
    if ($classname eq 'GCAllocator') {
       $extrabits = '
template <class Up> GCAllocator(const GCAtomicAllocatorRebindGCAlloc<Up>&)
	__STL_NOTHROW {}
template <class Up> GCAllocator(const GCAtomicIgnoreOffPageAllocatorRebindGCAlloc<Up>&)
	__STL_NOTHROW {}';
   }
print <<"END_OF_TEMPLATE"
template <class __T>
class $classname {
public:
#if defined(RWSTD_TEMPLATE) || defined(RWSTD_ALLOC_SIZE_TYPE)
    typedef void * allocateT;
    typedef __T T;
#else
    typedef __T * allocateT;
    typedef __T T;
#endif
    typedef size_t     size_type;
    typedef ptrdiff_t  difference_type;
    typedef T*       pointer;
    typedef const T* const_pointer;
    typedef T&       reference;
    typedef const T& const_reference;
    typedef T        value_type;
    
    template <class Up> struct rebind {
	typedef $rebindname<Up> other;
    };
    
    $classname() __STL_NOTHROW {}
    $classname(const $classname& a) __STL_NOTHROW {}
    template <class Up> $classname(const $classname<Up>&)
	__STL_NOTHROW {}$extrabits
    ~$classname() __STL_NOTHROW {}
    
    pointer address(reference x) const { return &x; }
    const_pointer address(const_reference x) const { return &x; }
    
    static allocateT allocate(size_type n, const void*__p = 0) {
	if (n == 0)
	    return static_cast<allocateT>(0);
#ifdef RWSTD_ALLOC_SIZE_TYPE
	// roguewave C++ STL has already multipled the size
#else
	n = n * sizeof(T); // C++ documentation implies this is correct
#endif
	allocateT ret = static_cast<allocateT>($fnname(n));
	INVARIANT(ret != NULL, "Out of Memory!");
	return ret;
    }
    
    // p is not permitted to be a null pointer.
    static void deallocate(pointer p, size_type n)
    { GC_free(p); }
    
    static void deallocate(pointer p)
    { GC_free(p); }

    static void deallocate(void * p)
    { GC_free(p); }
    
    static void deallocate(void *p, size_type n)
    { GC_free(p); }

    size_type max_size() const __STL_NOTHROW 
    { return size_t(-1) / sizeof(T); }
    
    static void construct(pointer p, const T& __val) { new(p) T(__val); }
    static void destroy(pointer p) { p->~T(); }

    bool operator==(const $classname<__T> &b) const { return true; }
};

#ifdef RWSTD_TEMPLATE
RWSTD_TEMPLATE
class $classname<void>
{
  public:
    typedef void*         pointer;
    typedef const void*   const_pointer;      
};

template<class T>
class allocator_interface<class $classname<T>, void>
{
  public:
    typedef void*         pointer;
    typedef const void*   const_pointer;      
};

#endif
END_OF_TEMPLATE
}
