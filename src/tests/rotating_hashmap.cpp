/*
   (c) Copyright 2008, Hewlett-Packard Development Company, LP

   See the file named COPYING for license details
*/

/** @file

   Test program for RotatingHashMap.hpp

*/

#include <Lintel/RotatingHashMap.hpp>

void test_odd(int k, int v) 
{
    SINVARIANT(k == v && k % 2 == 1);
}

int main()
{
    RotatingHashMap<int, int> test_hm;

    for(int i=0; i<100; ++i) {
	test_hm[i] = i;
    }

    test_hm.rotate();
    SINVARIANT(test_hm.size_recent() == 0 && test_hm.size_old() == 100);

    for(int i=0; i<100; i += 2) {
	SINVARIANT(test_hm.lookup(i) != NULL);
    }
    SINVARIANT(test_hm.size_recent() == 50 && test_hm.size_old() == 50);

    test_hm.rotate(boost::bind(test_odd, _1, _2));

    SINVARIANT(test_hm.size_recent() == 0 && test_hm.size_old() == 50);
    for(int i=1; i<100; i += 2) {
	SINVARIANT(!test_hm.exists(i)); // also tests lookup
	test_hm[i] = i;
    }
    SINVARIANT(test_hm.size_recent() == 50 && test_hm.size_old() == 50);

    for(int i=0; i < 100; i += 3) {
	test_hm.remove(i);
	SINVARIANT(!test_hm.exists(i));
    }

    exit(0);
}
