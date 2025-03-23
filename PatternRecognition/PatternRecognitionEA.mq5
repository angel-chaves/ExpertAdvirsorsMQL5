//+------------------------------------------------------------------+
//|                                               benchmark_test.mq5 |
//|                                        Copyright © 2018, Amr Ali |
//|                             https://www.mql5.com/en/users/amrali |
//+------------------------------------------------------------------+
#include <Benchmark\Benchmark.mqh>

//+------------------------------------------------------------------+
//| The function returns integer numeric value closest from below.   |
//+------------------------------------------------------------------+
double FastFloor(const double v)
  {
   double k = (double)(long)v;
   return k - (v < k);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart(void)
  {
   int repeats = 1e8;
   Print("repeats=",repeats);

//--- if result of the expression is not used, compiler optimizes out
//--- (i.e., ignores) the function call.
   double sum = 0;

   Benchmark(repeats, sum += MathFloor(__i));
   Benchmark(repeats, sum += FastFloor(__i));

   Print("sum=",sum);
  }
//+------------------------------------------------------------------+

// sample output:
/*
 repeats=100000000
 sum+=MathFloor(__i) -> 599 msec
 sum+=FastFloor(__i) -> 138 msec
 sum=9999999922280040.0
*/
