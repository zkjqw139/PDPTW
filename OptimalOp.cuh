#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include "evaluate.cuh"
//一些TSP相关的优化组件

namespace PDPTW {

	//对单条线路初始化
	__host__ void  routeInit(PDPTW::CustomerNode  *route,int count) {

		for (int s = 0; s < count; s++) {
			route[s].CustomerNodeStationID =0;
			route[s].NodeArriveTime =0;
			route[s].NodeDemand =0;
			route[s].NodeTimeWindowLeft = 999999;
			route[s].NodeTimeWindowRight = 999999;
		}
	}

	//将单条线路拷贝
	__host__ void routeCopy(PDPTW::CustomerNode *oldRoute, PDPTW::CustomerNode* newRoute, int count) {

		for (int s = 0; s < count; s++) {

			oldRoute[s].CustomerNodeStationID = newRoute[s].CustomerNodeStationID;
			oldRoute[s].NodeArriveTime        = newRoute[s].NodeArriveTime;
			oldRoute[s].NodeDemand            = newRoute[s].NodeDemand;
			oldRoute[s].NodeTimeWindowLeft    = newRoute[s].NodeTimeWindowLeft;
			oldRoute[s].NodeTimeWindowRight   = newRoute[s].NodeTimeWindowRight;
		}
	}
	//单线路从大数据集合中拷贝
	__host__ void routeCopyFrom(PDPTW::CustomerNode * route,PDPTW::CustomerNode * Route,int routeCount,int routeNum) {

		for (int s = 0; s < routeCount; s++) {

			route[s].CustomerNodeStationID = Route[PDPTW::maxUserSize*routeNum + s].CustomerNodeStationID;
			route[s].NodeArriveTime = Route[PDPTW::maxUserSize*routeNum + s].NodeArriveTime;
			route[s].NodeDemand = Route[PDPTW::maxUserSize*routeNum + s].NodeDemand;
			route[s].NodeTimeWindowLeft = Route[PDPTW::maxUserSize*routeNum + s].NodeTimeWindowLeft;
			route[s].NodeTimeWindowRight = Route[PDPTW::maxUserSize*routeNum + s].NodeTimeWindowRight;
		}
	}

	//单线路拷贝回大数据
	__host__ void routeCopyTo(PDPTW::CustomerNode * route,PDPTW::CustomerNode * Route,int routeCount,int routeNum) {
		
		for (int s = 0; s < routeCount; s++) {

			Route[PDPTW::maxUserSize*routeNum + s].CustomerNodeStationID = route[s].CustomerNodeStationID;
			Route[PDPTW::maxUserSize*routeNum + s].NodeArriveTime        = route[s].NodeArriveTime;
			Route[PDPTW::maxUserSize*routeNum + s].NodeDemand            = route[s].NodeDemand;
			Route[PDPTW::maxUserSize*routeNum + s].NodeTimeWindowLeft    = route[s].NodeTimeWindowLeft;
			Route[PDPTW::maxUserSize*routeNum + s].NodeTimeWindowRight   = route[s].NodeTimeWindowRight;
		}
	}
	//2-opt
	__host__ void two_opt_swap(PDPTW::CustomerNode * Route, int j, int k) {
		
		for (int begin = j, int end = k; j < k; j++, k--) {
			 
			CustomerNode *T = (CustomerNode *)malloc(sizeof(PDPTW::CustomerNode));

			
			T->CustomerNodeStationID = Route[j].CustomerNodeStationID;
			T->NodeArriveTime        = Route[j].NodeArriveTime;
			T->NodeDemand            = Route[j].NodeDemand;
			T->NodeTimeWindowLeft    = Route[j].NodeTimeWindowLeft;
			T->NodeTimeWindowRight   = Route[j].NodeTimeWindowRight;

			Route[j].CustomerNodeStationID = Route[k].CustomerNodeStationID;
			Route[j].NodeArriveTime        = Route[k].NodeArriveTime;
			Route[j].NodeDemand            = Route[k].NodeDemand;
			Route[j].NodeTimeWindowLeft    = Route[k].NodeTimeWindowLeft;
			Route[j].NodeTimeWindowRight   = Route[k].NodeTimeWindowRight;

			
			Route[k].CustomerNodeStationID =T->CustomerNodeStationID  ;
			Route[k].NodeArriveTime = T->NodeArriveTime;
			Route[k].NodeDemand =T->NodeDemand;
			Route[k].NodeTimeWindowLeft= T->NodeTimeWindowLeft;
			Route[k].NodeTimeWindowRight = T->NodeTimeWindowRight;

			free(T);
			T = NULL;
		}
	}

	//对于单条线路进行2-opt
	__host__ void singleRoadTwoOpt(PDPTW::CustomerNode * Route, size_t* UserSize, float *DistMatrix, int sepecifcRouteNum, int * routeCount) {

		
		int i      = sepecifcRouteNum;
		PDPTW::CustomerNode  *route     = (PDPTW::CustomerNode *)malloc(routeCount[i] * sizeof(PDPTW::CustomerNode));
		PDPTW::CustomerNode  *bestRoute = (PDPTW::CustomerNode *)malloc(routeCount[i] * sizeof(PDPTW::CustomerNode));
		
		//初始化要进行two opt的线路
		routeInit(route, routeCount[i]);
		routeCopyFrom(route, Route, routeCount[i], i);
		routeCopy(bestRoute, route, routeCount[i]);
		
		//对于当前路线进行评估，得到当前路线的初始解
		float bestSolutionValue = PDPTW::baseSingleEvaluate(bestRoute, UserSize, DistMatrix, routeCount[i]);

		//选择所有可以进行轨迹reverse
		for (int j = 0; j < routeCount[i]; j++) {
			for (int k = j + 1; k < routeCount[i]; k++) {
				
				routeCopy(route, bestRoute, routeCount[i]);
				//进行2-opt
				two_opt_swap(route, j, k);

				//对2-opt后的线路进行评估
				float currSolutionValue = PDPTW::baseSingleEvaluate(route, UserSize, DistMatrix, routeCount[i]);

				//判断是否比当前的解好，如果比当前解好，就替换当前解

				if (currSolutionValue < bestSolutionValue) {

					bestSolutionValue = currSolutionValue;
					routeCopy(bestRoute, route, routeCount[i]);
				}
			}
		}
		//将新得到的解复制回解的集合
		routeCopyTo(bestRoute, Route, routeCount[i], i);

		free(route);
		route = NULL;

		free(bestRoute);
		bestRoute = NULL;

	}



	//two optimization
	//https://en.wikipedia.org/wiki/2-opt
	__host__ void two_opt(PDPTW::CustomerNode * Route, size_t* UserSize, float *DistMatrix,int routeNum,int * routeCount) {
		//遍历每一条路
		for (int i = 0; i <= routeNum; i++) {
			singleRoadTwoOpt(Route, UserSize, DistMatrix, i, routeCount);
		}
	}


 	//Relocate optimization
	



	//demand nearsest Relocation

	

	//second nearest location
	


	//Random location


}