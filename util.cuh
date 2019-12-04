#pragma once
#include<iostream>
#include<stdio.h>
#include<math.h>

namespace MCT {

 
	class Reward{


	public:

		Reward() {
			this->u   = 0;
			this->var = 10;
		}

		Reward(int u, int var) {
			this->u   = u;
			this->var = var;
		}


		void set_u(int u) {
			this->u   = u;
		}

		void set_var(int var) {
			this->var = var;
		}

		void reset_u() {
			this->u   = 0;
		}

		void reset_var() {
			this->var = 0;
		}


		void set_alpha(int x) {
			alpha = x;
		}

		void reset_alpha() {
			alpha = 0;
		}

		float  operator()(const int x)  {
			float  prior = 1 / (sqrt(2 * 3.1415926)*var);
			float  midv = (x - u)*(x - u) / (2 * var*var);
			float  res = prior*exp(-midv);

			if (abs(x - u) > var) {
				weight = 2;
			}


			return (res/this->weight)*alpha;
		}

		

	private:

		int u;
		int var;
		int weight = 1;
		int alpha  = 2000;
	};



}


namespace PDPTW {





}