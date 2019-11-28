
#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include "loadData.h"
#include "BaseInitOp.cuh"
#include "evaluate.cuh"
#include "RemoveOP.cuh"
#include "InsertOp.cuh"
#include "critetionOp.cuh"
#include "OptimalOp.cuh"


namespace PDPTW {

	struct alnsModelOutput {
		PDPTW::CustomerNode* host_Route;
		int* routeCount;
		int* routeCapacity;
		int  routeNum;
		int  value;
	};


	void showRouteResult(PDPTW::CustomerNode* host_Route, int* routeCount, int* routeCapcity, int routeNum) {

		//显示解
		printf("\n显示初始解的结果...\n");
		for (int i = 0; i <= routeNum; i++) {
			printf("线路%d : ", i);
			for (int j = 0; j < routeCount[i]; j++) {
				printf("%d-- %d    ", host_Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID + 1, host_Route[i*PDPTW::maxUserSize + j].NodeDemand);
			}

			printf(" || 线路车容量 ： %d ", routeCapcity[i]);
			printf("\n");
		}
		printf("\n");
	}

	void companyToUsers(PDPTW::UserGroup* users, std::vector<PDPTW::CompanyWithTimeTable> companys) {

		for (int i = 0; i < companys.size(); i++) { 
			users[i].expectArriveTime = 0;
			users[i].groupID   = i+1;
			users[i].userCount = companys[i].employeeWantUseBusNum;
			users[i].UserDownStationID = 1;
			users[i].UserUpStationID = i + 1;
			users[i].UserUpStationLat = companys[i].lat;
			users[i].UserUpStationLon = companys[i].lon;
		}
	}

	__host__ alnsModelOutput  alnsModel(PDPTW::UserGroup* users , size_t * size , float *host_DistMatrix,float * DurationMatirx) {

		
		//初始化线路基本信息
		int* routeCount = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		for (int i = 0; i < PDPTW::maxUserSize; i++) {
			routeCount[i] = 0;
		}

		int* routeCapacity = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		for (int i = 0; i < PDPTW::maxUserSize; i++) {
			routeCapacity[i] = 0;
		}

		//初始化Route
		PDPTW::CustomerNode *host_Route = (PDPTW::CustomerNode*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));//初始化线路，线路初始分配内存是最大线路数目*最大用户数目
		if (host_Route == NULL) {
			printf("Allocat Error");
		}

		//初始化
		for (int i = 0; i < PDPTW::maxRouteCounts; i++) {
			for (int j = 0; j < PDPTW::maxUserSize; j++) {
				host_Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID = 0;
				host_Route[i*PDPTW::maxUserSize + j].UserID = 0;
				host_Route[i*PDPTW::maxUserSize + j].UserAction = false;
				host_Route[i*PDPTW::maxUserSize + j].NodeDemand = 0;
				host_Route[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft = 999999;
				host_Route[i*PDPTW::maxUserSize + j].NodeTimeWindowRight = 999999;
			}
		}

		//生成初始解
		int routeNum = PDPTW::BaseInit(users, size, host_Route, routeCapacity, routeCount, host_DistMatrix);
		//评估初始解
		float solutionValue = PDPTW::BaseEvaluate(host_Route, size, host_DistMatrix, routeNum, routeCount);
		//printf("\n\n初始解的值是: %f", solutionValue);

		//显示初始解
		//showRouteResult(host_Route, routeCount, routeCapacity, routeNum);

		//初始化Route
		PDPTW::CustomerNode *best_Route = (PDPTW::CustomerNode*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));//初始化线路，线路初始分配内存是最大线路数目*最大用户数目
		memcpy(best_Route, host_Route, PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));

		PDPTW::CustomerNode *true_best_Route = (PDPTW::CustomerNode*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));//初始化线路，线路初始分配内存是最大线路数目*最大用户数目
		memcpy(true_best_Route, host_Route, PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));

		//显示初始解
		//showRouteResult(best_Route, routeCount, routeCapacity, routeNum);


		//对初始解进行2-opt
		PDPTW::two_opt(host_Route, size, host_DistMatrix, routeNum, routeCount);

		//显示2-opt后的解
		//showRouteResult(host_Route, routeCount, routeCapacity, routeNum);

		//显示解的评估
		solutionValue = PDPTW::BaseEvaluate(host_Route, size, host_DistMatrix, routeNum, routeCount);
		//printf("\n\n2-opt 后解的值是 : %f", solutionValue);


		int *bestRouteCount = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int *bestRouteCapacity = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int bestrouteNum = routeNum;

		PDPTW::RouteCopy(host_Route, best_Route, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);



		int *truebestRouteCount = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int *truebestRouteCapacity = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int  truebestrouteNum = routeNum;

		PDPTW::RouteCopy(host_Route, true_best_Route, size, routeNum, routeCount, routeCapacity, truebestRouteCount, truebestRouteCapacity);

		float bestval = 9999999;
		//当前策略集合权重
		//删除策略集合权重
		std::vector<float>  RemoveWeight;
		//插入策略集合权重
		std::vector<float>  InsertWeight;


		//权重初始化
		for(int i=0;i<3;i++)
			RemoveWeight.push_back(1.0);
		


		for (int iter_times = 0; iter_times < 2500; iter_times++) {

			//初始化当前策略集合的初始值
			std::vector<float>  oneStepRemoveWeight;
			std::vector<int>    oneStepMethodUseTimes;

			for (int i = 0; i < 3; i++)
				oneStepRemoveWeight.push_back(0);

			for (int i=0; i < 3; i++)
				oneStepMethodUseTimes.push_back(0);
			
			for (int one_iter_times = 0; one_iter_times < 100; one_iter_times++) {
				//printf("times is : %d\n", times);

				PDPTW::RouteCopy(best_Route, host_Route, size, routeNum, bestRouteCount, bestRouteCapacity, routeCount, routeCapacity);

				//启发式搜索过程
				//加入一部分随机性
				//这里是假设所有删除方法拥有相同的权重
				//轮盘赌
				
				float totalSum = 0;
				for (int i = 0; i < 3; i++) {
					totalSum = totalSum + RemoveWeight[i];
				}

				int  tnum = int(totalSum) + 1;
				tnum = tnum * 1000;

				srand((UINT)GetCurrentTime());
				int randNum = rand() % tnum + 1;
				int removeMethodType = 0;


				//printf("\n randnum is: %d\n", randNum);

				std::vector<PDPTW::CustomerNode> RequestPool;
				if (randNum <=  RemoveWeight[0] * 1000) {
					RequestPool = PDPTW::worstRemove(host_Route, routeCount, routeCapacity, routeNum, host_DistMatrix, size);
					oneStepMethodUseTimes[0] += 1;
					removeMethodType = 0;
				}
				else if (randNum >RemoveWeight[0] * 1000 && randNum<=RemoveWeight[1] * 1000) {
					RequestPool = PDPTW::randomRemove(host_Route, routeCount, routeCapacity, routeNum);
					oneStepMethodUseTimes[1] += 1;
					removeMethodType = 1;
				}
				else if (randNum >RemoveWeight[1] * 1000 && randNum<=RemoveWeight[2] * 1000) {
					RequestPool = PDPTW::relatedRemove(host_Route, routeCount, routeCapacity, routeNum, host_DistMatrix, size);
					oneStepMethodUseTimes[2] += 1;
					removeMethodType = 2;
				}
				//showRouteResult(best_Route, bestRouteCount, bestRouteCapacity, bestrouteNum);
				PDPTW::two_opt(host_Route, size, host_DistMatrix, routeNum, routeCount);
				 


				//对Request进行插入
				PDPTW::greedyInsert(host_Route, RequestPool, routeNum, routeCount, routeCapacity, host_DistMatrix, size);
				PDPTW::two_opt(host_Route, size, host_DistMatrix, routeNum, routeCount);

				PDPTW::simulatedAnnelAccept(host_Route, best_Route, size, host_DistMatrix, routeNum, routeCount, routeCapacity, bestrouteNum, bestRouteCount, bestRouteCapacity, oneStepRemoveWeight,removeMethodType,bestval);

				//再次评估解
				solutionValue = PDPTW::BaseEvaluate(best_Route, size, host_DistMatrix, bestrouteNum, bestRouteCount);
				//printf("%f", solutionValue);

				//std::cout << solutionValue << std::endl;
				if (solutionValue < bestval) {
					bestval = solutionValue;
					PDPTW::RouteCopy(best_Route, true_best_Route, size, bestrouteNum, bestRouteCount, bestRouteCapacity, truebestRouteCount, truebestRouteCapacity);

				}
				int rCount = checkRouteCount(host_Route, routeCount, routeCapacity, routeNum);
				//showRouteResult(best_Route, bestRouteCount, bestRouteCapacity, bestrouteNum);
				//printf("\n bestVal is %f \n", bestval);
			  }
			
			  
			  
		    //update value
			for (int i = 0; i < 3; i++) {
				if (oneStepMethodUseTimes[i] > 0) {
					RemoveWeight[i] = RemoveWeight[i] * 0.9 + 0.1*(oneStepRemoveWeight[i] / oneStepMethodUseTimes[i]);
				}
				//std::cout << "Remove Weight i : " << "   " << RemoveWeight[i] << std::endl;
			}

			float totalweight = 0;
			for (int i = 0; i < 3; i++) {
				totalweight = totalweight + RemoveWeight[i];
			}

			for (int i = 0; i < 3; i++) {
				RemoveWeight[i] = min(0.1, RemoveWeight[i] / totalweight);
			}




		}

		free(host_Route);
		host_Route = NULL;

		free(routeCapacity);
		routeCapacity = NULL;

		free(routeCount);
		routeCount = NULL;

		free(best_Route);
		best_Route = NULL;

		free(bestRouteCapacity);
		bestRouteCapacity = NULL;

		free(bestRouteCount);
		bestRouteCount = NULL;

		//showRouteResult(best_Route, bestRouteCount, bestRouteCapacity, bestrouteNum);
		printf("\n bestVal is %f \n", bestval);
		showRouteResult(true_best_Route, truebestRouteCount, truebestRouteCapacity, truebestrouteNum);

		alnsModelOutput res;
		res.host_Route = true_best_Route;
		res.routeCapacity = truebestRouteCapacity;
		res.routeCount = truebestRouteCount;
		res.routeNum = truebestrouteNum;
		res.value = bestval;

		return res;
	}
    
	__host__ void  alns() {


		//读档
		PDPTW::UserGroup* users = NULL;
		size_t *size = (size_t*)malloc(sizeof(size_t));

		//printf("%d", sizeof(users));
		users = PDPTW::loadUserData(users, size);

		//计算节点间关系的距离矩阵
		int      length = *size;
		float *  host_DistMatrix = NULL;
		host_DistMatrix = (float*)malloc(length*length * sizeof(float));
		host_DistMatrix = PDPTW::caldistMatirx(users, size, host_DistMatrix);
		//初始化线路基本信息
		int* routeCount = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		for (int i = 0; i < PDPTW::maxUserSize; i++) {
			routeCount[i] = 0;
		}

		int* routeCapaity = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		for (int i = 0; i < PDPTW::maxUserSize; i++) {
			routeCapaity[i] = 0;
		}

		//初始化Route
		PDPTW::CustomerNode *host_Route = (PDPTW::CustomerNode*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));//初始化线路，线路初始分配内存是最大线路数目*最大用户数目
		if (host_Route == NULL) {
			printf("Allocat Error");
		}

		//初始化
		for (int i = 0; i < PDPTW::maxRouteCounts; i++) {
			for (int j = 0; j < PDPTW::maxUserSize; j++) {
				host_Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID = 0;
				host_Route[i*PDPTW::maxUserSize + j].UserID = 0;
				host_Route[i*PDPTW::maxUserSize + j].UserAction = false;
				host_Route[i*PDPTW::maxUserSize + j].NodeDemand = 0;
				host_Route[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft = 999999;
				host_Route[i*PDPTW::maxUserSize + j].NodeTimeWindowRight = 999999;
			}
		}
		//生成初始解
		int routeNum = PDPTW::BaseInit(users, size, host_Route, routeCapaity, routeCount, host_DistMatrix);

		//评估初始解
		float solutionValue = PDPTW::BaseEvaluate(host_Route, size, host_DistMatrix, routeNum, routeCount);
		//printf("\n\n初始解的值是: %f", solutionValue);

		//显示初始解
		showRouteResult(host_Route, routeCount, routeCapaity, routeNum);

		//初始化Route
		PDPTW::CustomerNode *best_Route = (PDPTW::CustomerNode*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));//初始化线路，线路初始分配内存是最大线路数目*最大用户数目
		memcpy(best_Route, host_Route, PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));

		PDPTW::CustomerNode *true_best_Route = (PDPTW::CustomerNode*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));//初始化线路，线路初始分配内存是最大线路数目*最大用户数目
		memcpy(true_best_Route, host_Route, PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(PDPTW::CustomerNode));



		//显示初始解
		showRouteResult(best_Route, routeCount, routeCapaity, routeNum);


		//对初始解进行2-opt
		PDPTW::two_opt(host_Route, size, host_DistMatrix, routeNum, routeCount);

		//显示2-opt后的解
		showRouteResult(host_Route, routeCount, routeCapaity, routeNum);

		//显示解的评估
		solutionValue = PDPTW::BaseEvaluate(host_Route, size, host_DistMatrix, routeNum, routeCount);
		//printf("\n\n2-opt 后解的值是 : %f", solutionValue);

		int *bestRouteCount = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int *bestRouteCapacity = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int  bestrouteNum = routeNum;

		PDPTW::RouteCopy(host_Route, best_Route, size, routeNum, routeCount, routeCapaity, bestRouteCount, bestRouteCapacity);

		/*
		for (int i = 0; i < PDPTW::maxUserSize; i++) {
			printf("%d \n", bestRouteCount[i]);
		}*/

		int *truebestRouteCount    = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int *truebestRouteCapacity = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
		int  truebestrouteNum      = routeNum;

		PDPTW::RouteCopy(true_best_Route, host_Route, size, routeNum, bestRouteCount, bestRouteCapacity, routeCount, routeCapaity);

		
		float bestval = 9999;
		for (int times = 0; times < 250000; times++) {

			//printf("times is : %d\n", times);

			PDPTW::RouteCopy(best_Route, host_Route, size, routeNum, bestRouteCount, bestRouteCapacity, routeCount, routeCapaity);

			//启发式搜索过程
			//加入一部分随机性
			//这里是假设所有删除方法拥有相同的权重
			srand((UINT)GetCurrentTime());
			int randNum = rand() % 20 + 1;

			//printf("\n randnum is: %d\n", randNum);

			std::vector<PDPTW::CustomerNode> RequestPool;
			if (randNum % 3 == 0) {
				RequestPool = PDPTW::worstRemove(host_Route, routeCount, routeCapaity, routeNum, host_DistMatrix, size);
			}
			else if (randNum % 3 == 1) {
				RequestPool = PDPTW::randomRemove(host_Route, routeCount, routeCapaity, routeNum);
			}
			else if (randNum % 3 == 2) {
				RequestPool = PDPTW::relatedRemove(host_Route, routeCount, routeCapaity, routeNum, host_DistMatrix, size);
			}
			//showRouteResult(best_Route, bestRouteCount, bestRouteCapacity, bestrouteNum);
			PDPTW::two_opt(host_Route, size, host_DistMatrix, routeNum, routeCount);
			int rcount2 = checkRouteCount(host_Route, routeCount, routeCapaity, routeNum);
			int* routeCount2 = (int*)malloc(PDPTW::maxUserSize * sizeof(int));
			for (int i = 0; i < PDPTW::maxUserSize; i++) {
				routeCount2[i] = routeCount[i];
			}


			//对Request进行插入
			PDPTW::greedyInsert(host_Route, RequestPool, routeNum, routeCount, routeCapaity, host_DistMatrix, size);
			PDPTW::two_opt(host_Route, size, host_DistMatrix, routeNum, routeCount);

			//是否接受解
 


			PDPTW::originSimulatedAnnelAccept(host_Route, best_Route, size, host_DistMatrix, routeNum, routeCount, routeCapaity, bestrouteNum, bestRouteCount, bestRouteCapacity);

			//再次评估解
			solutionValue = PDPTW::BaseEvaluate(best_Route, size, host_DistMatrix, bestrouteNum, bestRouteCount);
			//printf("%f", solutionValue);
	 

			if (solutionValue < bestval) {
				bestval = solutionValue;
				PDPTW::RouteCopy(true_best_Route, host_Route, size, routeNum, bestRouteCount, bestRouteCapacity, routeCount, routeCapaity);

			}
			int rCount = checkRouteCount(host_Route, routeCount, routeCapaity, routeNum);
			//showRouteResult(best_Route, bestRouteCount, bestRouteCapacity, bestrouteNum);

			printf("\n bestVal is %f \n", bestval);

		}


	}
}