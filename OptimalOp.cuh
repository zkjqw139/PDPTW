#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include "evaluate.cuh"
//һЩTSP��ص��Ż����

namespace PDPTW {

	//�Ե�����·��ʼ��
	__host__ void  routeInit(PDPTW::CustomerNode  *route,int count) {

		for (int s = 0; s < count; s++) {
			route[s].CustomerNodeStationID =0;
			route[s].NodeArriveTime =0;
			route[s].NodeDemand =0;
			route[s].NodeTimeWindowLeft = 999999;
			route[s].NodeTimeWindowRight = 999999;
		}
	}

	//��������·����
	__host__ void routeCopy(PDPTW::CustomerNode *oldRoute, PDPTW::CustomerNode* newRoute, int count) {

		for (int s = 0; s < count; s++) {

			oldRoute[s].CustomerNodeStationID = newRoute[s].CustomerNodeStationID;
			oldRoute[s].NodeArriveTime        = newRoute[s].NodeArriveTime;
			oldRoute[s].NodeDemand            = newRoute[s].NodeDemand;
			oldRoute[s].NodeTimeWindowLeft    = newRoute[s].NodeTimeWindowLeft;
			oldRoute[s].NodeTimeWindowRight   = newRoute[s].NodeTimeWindowRight;
		}
	}
	//����·�Ӵ����ݼ����п���
	__host__ void routeCopyFrom(PDPTW::CustomerNode * route,PDPTW::CustomerNode * Route,int routeCount,int routeNum) {

		for (int s = 0; s < routeCount; s++) {

			route[s].CustomerNodeStationID = Route[PDPTW::maxUserSize*routeNum + s].CustomerNodeStationID;
			route[s].NodeArriveTime = Route[PDPTW::maxUserSize*routeNum + s].NodeArriveTime;
			route[s].NodeDemand = Route[PDPTW::maxUserSize*routeNum + s].NodeDemand;
			route[s].NodeTimeWindowLeft = Route[PDPTW::maxUserSize*routeNum + s].NodeTimeWindowLeft;
			route[s].NodeTimeWindowRight = Route[PDPTW::maxUserSize*routeNum + s].NodeTimeWindowRight;
		}
	}

	//����·�����ش�����
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

	//���ڵ�����·����2-opt
	__host__ void singleRoadTwoOpt(PDPTW::CustomerNode * Route, size_t* UserSize, float *DistMatrix, int sepecifcRouteNum, int * routeCount) {

		
		int i      = sepecifcRouteNum;
		PDPTW::CustomerNode  *route     = (PDPTW::CustomerNode *)malloc(routeCount[i] * sizeof(PDPTW::CustomerNode));
		PDPTW::CustomerNode  *bestRoute = (PDPTW::CustomerNode *)malloc(routeCount[i] * sizeof(PDPTW::CustomerNode));
		
		//��ʼ��Ҫ����two opt����·
		routeInit(route, routeCount[i]);
		routeCopyFrom(route, Route, routeCount[i], i);
		routeCopy(bestRoute, route, routeCount[i]);
		
		//���ڵ�ǰ·�߽����������õ���ǰ·�ߵĳ�ʼ��
		float bestSolutionValue = PDPTW::baseSingleEvaluate(bestRoute, UserSize, DistMatrix, routeCount[i]);

		//ѡ�����п��Խ��й켣reverse
		for (int j = 0; j < routeCount[i]; j++) {
			for (int k = j + 1; k < routeCount[i]; k++) {
				
				routeCopy(route, bestRoute, routeCount[i]);
				//����2-opt
				two_opt_swap(route, j, k);

				//��2-opt�����·��������
				float currSolutionValue = PDPTW::baseSingleEvaluate(route, UserSize, DistMatrix, routeCount[i]);

				//�ж��Ƿ�ȵ�ǰ�Ľ�ã�����ȵ�ǰ��ã����滻��ǰ��

				if (currSolutionValue < bestSolutionValue) {

					bestSolutionValue = currSolutionValue;
					routeCopy(bestRoute, route, routeCount[i]);
				}
			}
		}
		//���µõ��Ľ⸴�ƻؽ�ļ���
		routeCopyTo(bestRoute, Route, routeCount[i], i);

		free(route);
		route = NULL;

		free(bestRoute);
		bestRoute = NULL;

	}



	//two optimization
	//https://en.wikipedia.org/wiki/2-opt
	__host__ void two_opt(PDPTW::CustomerNode * Route, size_t* UserSize, float *DistMatrix,int routeNum,int * routeCount) {
		//����ÿһ��·
		for (int i = 0; i <= routeNum; i++) {
			singleRoadTwoOpt(Route, UserSize, DistMatrix, i, routeCount);
		}
	}


 	//Relocate optimization
	



	//demand nearsest Relocation

	

	//second nearest location
	


	//Random location


}