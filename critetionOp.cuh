#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include <deque> 
#include <algorithm>
#include "evaluate.cuh"
//ALNS接受标准的算子集合
//表现为新生成一个解后决定是否接受它
//使用CPU实现

namespace PDPTW {

	int checkRouteCount(PDPTW::CustomerNode* host_Route, int* routeCount, int* routeCapcity, int routeNum) {

		int rCount = 0;
		for (int i = 0; i <= routeNum; i++) {
			rCount += routeCount[i];
		}

		//printf("routeCount is %d\n", rCount);

		return rCount;


	}

	__host__ void RouteCopy(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute, size_t* UserSize, int routeNum, int *routeCount, int *routeCapacity, int* bestRouteCount, int* bestRouteCapacity) {

		for (int i = 0; i <= routeNum; i++) {
			for (int j = 0; j < routeCount[i]; j++) {
				bestRoute[i*PDPTW::maxUserSize + j].CustomerNodeStationID = currentRoute[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
				bestRoute[i*PDPTW::maxUserSize + j].UserID = currentRoute[i*PDPTW::maxUserSize + j].UserID;
				bestRoute[i*PDPTW::maxUserSize + j].UserAction = currentRoute[i*PDPTW::maxUserSize + j].UserAction;
				bestRoute[i*PDPTW::maxUserSize + j].NodeDemand = currentRoute[i*PDPTW::maxUserSize + j].NodeDemand;
				bestRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft = currentRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft;
				bestRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowRight = currentRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowRight;
			}
		}

		for (int i = 0; i < (*UserSize); i++) {
			bestRouteCount[i] = routeCount[i];
			bestRouteCapacity[i] = routeCapacity[i];
		}


	}


	//贪婪接受当前解比过去解评价函数评分更好的时侯，就选择接受当前新生成的解
	__host__ void greedyAccept(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute, size_t* size, float* host_DistMatrix, int routeNum, int* routeCount, int* routeCapacity, int bestRoutNum, int* bestRouteCount, int* bestRouteCapacity) {

		float currentSolutionValue = PDPTW::BaseEvaluate(currentRoute, size, host_DistMatrix, routeNum, routeCount);
		float bestSolutionValue = PDPTW::BaseEvaluate(bestRoute, size, host_DistMatrix, bestRoutNum, bestRouteCount);

		printf("result is %f %f \n\n", currentSolutionValue, bestSolutionValue);
		
		if (currentSolutionValue < bestSolutionValue) {
			printf("find one best solution\n");
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
		}
	}


	//基于模拟退火法选择是否接受解
	__host__ void simulatedAnnelAccept(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute, 
									   size_t* size, float* host_DistMatrix, 
		                               int routeNum, int* routeCount, int* routeCapacity,
		                               int bestRoutNum, int* bestRouteCount, int* bestRouteCapacity,std::vector<float> & RemoveMethodWeight,int & removeMethodType , int bestVal) {

		//初始化初始温度
		static float T = 100;

		//初始化衰减系数
		static float a = 0.999999;

		int rcount=checkRouteCount(currentRoute, routeCount, routeCapacity, routeNum);


		if (rcount < *size-1){
			std::cout << *size << std::endl;
			printf("rcount is %d less than 35\n",rcount);
			return;
		} 

		//当前解的评价值
		float currentSolutionValue = PDPTW::BaseEvaluate(currentRoute, size, host_DistMatrix, routeNum, routeCount);

		//最佳解的评价值
		float bestSolutionValue    = PDPTW::BaseEvaluate(bestRoute, size, host_DistMatrix, bestRoutNum, bestRouteCount);

		//显示解
		//printf("result is %f %f \n\n", currentSolutionValue, bestSolutionValue);
		

		//评估解的差值
		float diffSolutionValue = currentSolutionValue - bestSolutionValue;

		//接受概率
		float acceptProb = exp(-abs(diffSolutionValue) / T);

		//printf("\n accept prob is : %f \n", acceptProb);

		//生成概率
		srand((UINT)GetCurrentTime());
		float randNum = (rand() % 100)/(float)(101)+0.1;
		
		//printf("generator prob is: %f \n", randNum);

		//弱国随机生成的概率小于接受概率则接受
        //如果当前解评价好于当前解则一定接受
		if (currentSolutionValue < bestVal) {
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
			RemoveMethodWeight[removeMethodType] += 20;
		}
		else if (currentSolutionValue<bestSolutionValue) {
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
			RemoveMethodWeight[removeMethodType] += 10;
		}
		//但是如果当前解存在一定概率比当前解差的情况，则基于概率接受
		else {
			if (randNum < acceptProb) {
				RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
				RemoveMethodWeight[removeMethodType] += 5;
			}	
			//更新温度
			if (T > 0.1) {
				T = a*T;
			}
		}

	
	}


	//基于模拟退火法选择是否接受解
	__host__ void originSimulatedAnnelAccept(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute,
		size_t* size, float* host_DistMatrix,
		int routeNum, int* routeCount, int* routeCapacity,
		int bestRoutNum, int* bestRouteCount, int* bestRouteCapacity) {

		//初始化初始温度
		static float T = 100;

		//初始化衰减系数
		static float a = 0.999999;

		int rcount = checkRouteCount(currentRoute, routeCount, routeCapacity, routeNum);


		if (rcount < *size - 1) {
			//std::cout << *size << std::endl;
			//printf("rcount is %d less than 35\n", rcount);
			return;
		}

		//当前解的评价值
		float currentSolutionValue = PDPTW::BaseEvaluate(currentRoute, size, host_DistMatrix, routeNum, routeCount);

		//最佳解的评价值
		float bestSolutionValue = PDPTW::BaseEvaluate(bestRoute, size, host_DistMatrix, bestRoutNum, bestRouteCount);

		//显示解
		//printf("result is %f %f \n\n", currentSolutionValue, bestSolutionValue);


		//评估解的差值
		float diffSolutionValue = currentSolutionValue - bestSolutionValue;

		//接受概率
		float acceptProb = exp(-abs(diffSolutionValue) / T);

		//printf("\n accept prob is : %f \n", acceptProb);

		//生成概率
		srand((UINT)GetCurrentTime());
		float randNum = (rand() % 100) / (float)(101) + 0.1;

		//printf("generator prob is: %f \n", randNum);

		//弱国随机生成的概率小于接受概率则接受
		//如果当前解评价好于当前解则一定接受
		if (currentSolutionValue < bestSolutionValue) {
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);

		}
		//但是如果当前解存在一定概率比当前解差的情况，则基于概率接受
		else {
			if (randNum < acceptProb) {
				RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
			}
			//更新温度
			if (T > 0.1) {
				T = a*T;
			}
		}


	}



}
 