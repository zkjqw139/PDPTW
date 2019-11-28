#pragma  once
#include "device_launch_parameters.h"
#include <cuda_runtime.h>
#include <curand.h>
#include <curand_kernel.h>
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>

#include "../PDPTW/User.cuh"
#include "../PDPTW/CustomerNode.cuh"

namespace PDPTW {

	const  int maxRouteCounts = 64;
	const  int maxUserSize    = 128;
	const  int maxValue       = 999999999;


	struct dfsComponent {

		int  DispatchTime;
		bool ifDispatch;

	};

}